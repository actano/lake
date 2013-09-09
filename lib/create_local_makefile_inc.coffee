#!/usr/bin/env coffee

###

    targets:

        run

        clean

        install

        runtime

        documentation

        manifest.documentation:

            featurepath/build/*.html

        manifest.client:
            featurepath/build/component.json
                src: manifest.coffee

            featurepath/build/components
                src: component.json, local_components

            lib/usermanagement/build/styles/featurename.css

            lib/usermanagement/build/views/*.js

            featurepath/build/featurename.js featurename.css

            featurepath/build/index.html/demo.html

            featurepath/build/featurename-browser.js

            featurepath/build/test.html

            featurepath/phantom_test

        manifest.server

            featurepath/build/server_scripts/*.js

            featurepath/unit_test

            featurepath/integration_test

häufig benutzte Variablen:

    libPrefix : Pfad vom Projectroot zum Feature

aktuelle Funktionen:

    replaceFilename  (filename)

        ersetzt Dateiendungen von stylus, jade und coffee files, jade files werden in js-files kompiliert

    formatRule (targetPath, preequisits, actions, phony)

        formatiert alle Übergaben zu einer Makefile konformen Regel

    getTargetFileFromManifest (libPrefix, manifest)

        globbt alle Dateien, die unter manifest.client.styles, .templates und .scripts gelistet sind, zusammen,
        führt eine Dateiendungsersetzung durch (siehe replaceFilename) und fügt den libraryPrefix daran

    makeComponentBuildPrerequisits (libPrefix, manifest)

        erstellt und formatiert build regeln für die mit getTargetFileFromManifest gefundenen Files

    createLocalMakefileInc

        erstellt das Makefile, prozessschritte werden in einem async.waterfall abgehandelt


###




fs = require 'fs'
path = require 'path'
{exec} = require 'child_process'
{_} = require 'underscore'
async = require 'async'
debug = require('debug')('create-local-makefile-inc')
coffee = require('coffee-script')

{findProjectRoot} = require './file-locator'

RUNTIME_DIR = path.join "build", "runtime"
COVERAGE_DIR = path.join "build", "coverage"

BUILD_DIR = "build"
TEST_DIR = "test"

replaceFilename = (targetFilename) ->


    patterns = [
            ext: '.styl'
            replExt: '.css'
        ,
            ext: '.coffee'
            replExt: '.js'
        ,
            ext: '.jade'
            replExt: '.js'
    ]

    extMapping = _(patterns).find ({ext}) ->
        return (path.extname targetFilename).match ext

    if extMapping?
        directory = path.dirname targetFilename
        path.join BUILD_DIR, directory, "#{path.basename targetFilename, extMapping.ext}#{extMapping.replExt}"
    else
        targetFilename



formatRule = ({targetPath, preequisits, actions, phony}) ->
    if typeof preequisits is "object" then preequisits = preequisits.join ' '
    lines = ["#{targetPath}: #{preequisits}"]
    lines = lines.concat ("\t#{action}" for action in actions)
    if phony then lines.push ".PHONY: #{targetPath}"
    lines.push ''
    return lines.join '\n'

getTargetFileFromManifest = (libPrefix, manifest) ->

    targetFileKeys = ['scripts', 'styles', 'templates']

    targetFiles = _(manifest.client[key] for key in targetFileKeys).flatten()

    debug "#{libPrefix} target Files #{targetFiles}"

    relativePaths = _(targetFiles).compact()

    _(relativePaths).map (relativePath) ->
         path.join libPrefix, replaceFilename(relativePath)

makeComponentBuildPrerequisits = (libPrefix, manifest) ->

    createRule = (libPrefix, targetPath) ->

        # as found in Manifest.coffee
        patterns = [
            ext: 'styl'
            regexp: /build\/(.*)\.css/
            actions: [
                "mkdir -p #{path.dirname targetPath}"
                "$(STYLUSC) $(STYLUS_FLAGS) --out #{path.dirname targetPath} $<"
            ]
        ,
            ext: 'jade'
            regexp: /build\/(views\/.*)\.js/
            actions: [
                "@mkdir -p #{path.dirname targetPath}"
                '@echo "module.exports=" > $@'
                '$(JADEC) --client --path $< < $< >> $@'
            ]
        ,
            ext: 'coffee'
            regexp: /build\/(.*)\.js/
            actions: [
                "$(COFFEEC) -c $(COFFEE_FLAGS) --output #{path.dirname targetPath} $<"
            ]
        ,
            ext: 'js'
            regexp: /build\/(.*)\.js/
            actions: []
        ]


        pattern = _(patterns).find ({ext, regexp}) ->
            return targetPath.match regexp

        if not pattern? then throw Error "target path #{targetPath} does not match any pattern."

        m = targetPath.match pattern.regexp
        sourcePath = path.join libPrefix, "#{m[1]}.#{pattern.ext}"

        return {
            targetPath: targetPath
            preequisits: [sourcePath]
            actions: pattern.actions
        }

    targetFiles = getTargetFileFromManifest libPrefix, manifest

    debug "generating rules for target files: #{targetFiles}"

    return (formatRule createRule(libPrefix, targetFile) for targetFile in targetFiles)


createLocalMakefileInc = (projectRoot, cwd, cb) ->

    pathToManifest = path.join cwd, 'Manifest'
    manifest = null
    try
        #manifestContent = fs.readFileSync pathToManifest
        #manifest = coffee.eval manifestContent.toString()
        manifest = require pathToManifest
    catch err
        err.message = "Error in Manifest file #{pathToManifest}: #{err.message}"
        debug err.message
        return cb err

    if not manifest then return cb new Error "#{pathToManifest} is empty or undefined"

    makefileLines = []

    libPrefix = path.relative projectRoot, cwd

    async.waterfall [
        (cb) ->
            targets = []
            globalTargets = {}
            runtimeTargets = []

            if manifest.client?

                # Preequisits of component-build
                makefileLines.push makeComponentBuildPrerequisits libPrefix, manifest

                # component.json

                targetPath = path.join libPrefix, "build", "component.json"
                targets.push targetPath
                makefileLines.push formatRule
                    targetPath: targetPath
                    preequisits: ["#{libPrefix}/Manifest.coffee"]
                    actions: [
                        "mkdir -p #{libPrefix}/build"
                        # refactor this, extract names
                        "node $(TOOLS)/create_component_json.js $< $@"
                    ]
                # TODO component.json is only required for the feature index.coffee, better generate the index.coffee
                runtimeTargets.push [path.join(libPrefix, "component.json"), targetPath]


                # component-install
                makefileLines.push formatRule
                    targetPath: "#{libPrefix}/build/components"
                    preequisits: ["#{libPrefix}/build/component.json"]
                    actions: [
                        "cd #{libPrefix}/build && $(COMPONENT_INSTALL) $(COMPONENT_INSTALL_FLAGS) || rm -rf #{libPrefix}/components"
                        "test -d #{libPrefix}/build/components"
                        "touch #{libPrefix}/build/components"
                    ]

                # component-build creates aggregated .css and .js for the browser
                # .css is only created when there was at least one css file referenced in
                # component.json. Same for js.

                localComponents = []

                if manifest.client.dependencies?.production?.local?

                    for localDependency in manifest.client.dependencies.production.local
                        absolutePath = path.resolve projectRoot, libPrefix, localDependency
                        relativePath = path.relative projectRoot, absolutePath

                        localComponents.push relativePath

                    debug "localComponents are #{localComponents}"

                component_build_flags = "--name #{manifest.name}"

                if not manifest.library
                    component_build_flags += " --standalone #{manifest.name}"

                hasStyles = manifest.client.styles?.length
                hasScripts = manifest.client.scripts?.length

                componentBuildResults =[]
                if hasScripts
                    tp = path.join libPrefix, "build", "#{manifest.name}.js"
                    componentBuildResults.push tp
                    runtimeTargets.push [tp, tp]
                    # todo find a better way for imlicit css building
                    tp = path.join libPrefix, "build", "#{manifest.name}.css"
                    runtimeTargets.push [tp, tp]

                if hasStyles
                    tp = path.join libPrefix, "build", "#{manifest.name}.css"
                    componentBuildResults.push tp

                builtLocalComponents = localComponents.map (c) ->
                    "build/local_components/#{c}"

                targets.push componentBuildResults
                makefileLines.push formatRule
                    targetPath: componentBuildResults.join(" ")
                    preequisits: builtLocalComponents.concat ["#{libPrefix}/build/components"].concat getTargetFileFromManifest libPrefix, manifest  # change manifest.client, submit only list with local deps
                    actions: [
                        "cd #{libPrefix}/build && $(COMPONENT_BUILD) $(COMPONENT_BUILD_FLAGS) #{component_build_flags} -v -o ./"
                    ]

                # copy to /build/local_components
                makefileLines.push formatRule
                    targetPath: "build/local_components/#{libPrefix}"
                    preequisits: builtLocalComponents.concat ["#{libPrefix}/build/component.json"].concat getTargetFileFromManifest libPrefix, manifest
                    actions: [
                        "mkdir -p build/local_components/#{libPrefix}"
                        "cp -r #{libPrefix}/build/* build/local_components/#{libPrefix}"
                        "touch build/local_components/#{libPrefix}"
                    ]
                targets.push "build/local_components/#{libPrefix}"


            # rendering the client.test template

            allTests = []

            if manifest.client?.tests?.browser?.scripts?.length

                browserTestScriptsPreequisit = []

                for browserScripts in manifest.client.tests.browser.scripts
                    testScriptPreequisits = path.join(libPrefix, browserScripts)
                    relFeaturePath = path.dirname browserScripts
                    testScriptName = path.basename browserScripts, '.coffee'

                    testScriptTarget = path.join libPrefix, "build", relFeaturePath, "#{testScriptName}.js"

                    browserTestScriptsPreequisit.push testScriptTarget

                    makefileLines.push formatRule
                        targetPath: testScriptTarget
                        preequisits: testScriptPreequisits
                        actions: [
                            "$(COFFEEC) -c $(COFFEE_FLAGS) --output #{path.join libPrefix, "build", relFeaturePath} $<"
                        ]

                if manifest.client.tests.browser.html?.length

                    browserTestTemplatesPreequisit = []

                    browserTestTemplatesPreequisit.push path.join libPrefix, manifest.client.tests.browser.html

                    browserTestTemplatesPreequisit.concat _(manifest.client.tests.browser.prerequisits).map (item) ->
                        path.join libPrefix, item

                    testTemplateTarget = path.join libPrefix, BUILD_DIR, "test.html"
                    targets.push testTemplateTarget

                    testScripts = _(browserTestScriptsPreequisit).map (scriptLocation) ->
                        return path.basename scriptLocation

                    makefileLines.push formatRule
                        targetPath: testTemplateTarget
                        preequisits: (browserTestTemplatesPreequisit.concat browserTestScriptsPreequisit).join " "
                        actions: [
                            "$(JADEC) $< --pretty --obj {\\\"name\\\":\\\"#{manifest.name}\\\"\\\,\\\"tests\\\":\\\"#{testScripts.join '\\\ '}\\\"} --out #{path.join(libPrefix, "build")}"
                        ]

                    browserTestPre = [
                        target: 'mocha.js'
                        path: '$(BIN)/../mocha/mocha.js'
                    ,
                        target: 'chai.js'
                        path: '$(BIN)/../chai/chai.js'
                    ,
                        target: 'mocha.css'
                        path: '$(BIN)/../mocha/mocha.css'
                    ,
                        target: 'sinon.js'
                        path: 'vendor/sinon-1.7.3.js'
                        preequisits: true
                    ,
                        target: 'jquery.js'
                        path: 'vendor/jquery-1.10.2.js'
                        preequisits: true
                    ]

                    _(browserTestPre).each (item) ->
                        opts =
                            targetPath: "#{libPrefix}/#{BUILD_DIR}/#{item.target}"
                            actions: ["cp #{item.path} #{path.join libPrefix, BUILD_DIR, item.target}"]
                            preequisits: if item.preequisits? then item.path else []

                        makefileLines.push formatRule opts

                    targetPaths = _(browserTestPre).map (item) ->
                        path.join(libPrefix, BUILD_DIR, item.target)
                    targetPaths.unshift libPrefix
                    targetPaths.push testTemplateTarget


                    makefileLines.push formatRule
                        targetPath: "#{libPrefix}/test_assets"
                        preequisits: targetPaths
                        actions: []

                    makefileLines.push formatRule
                        targetPath: path.join libPrefix, 'client_test'
                        preequisits: "#{libPrefix}/test_assets"
                        actions: [
                            "$(BIN)/mocha-phantomjs -R tap #{testTemplateTarget}"
                        ]

                    allTests.push 'client_test'

            if manifest.client?.views?.files?.length
                for viewFile in manifest.client.views.files
                    tp = path.join libPrefix, viewFile
                    runtimeTargets.push [tp, tp]

            if manifest.client?.views?.dirs?.length
                for viewDir in manifest.client.views.dirs
                    viewFiles = fs.readdirSync(path.join projectRoot, libPrefix, viewDir)
                    for viewFile in viewFiles
                        if path.extname(viewFile) is ".jade"
                            tp = path.join libPrefix, viewDir, viewFile
                            runtimeTargets.push [tp, tp]

            # html_doc creates html from markdown files
            if manifest.documentation?.length
                documentationTarget = path.join libPrefix, "build", "documentation"
                htmlDocTargets = []
                for mdfile in manifest.documentation
                    destFile = (path.basename mdfile, '.md').concat '.html'
                    destPath = path.join documentationTarget, destFile
                    htmlDocTargets.push destPath
                    makefileLines.push formatRule
                        targetPath: destPath
                        preequisits: path.join libPrefix, mdfile
                        actions: [
                            "@mkdir -p #{documentationTarget}"
                            "markdown $< > $@"
                        ]

                makefileLines.push formatRule
                    targetPath: documentationTarget
                    preequisits: htmlDocTargets
                    actions: [
                        "touch $@"
                    ]

                targets.push documentationTarget
                globalTargets["documentation"] = [ documentationTarget ]


            targetBuildPath = path.join "#{libPrefix}", "build"
            # if output templates are present, build an html file
            if manifest.htdocs?.page?.html?.length
                for htmlDoc in manifest.htdocs.page.html

                    templateName = path.basename htmlDoc, path.extname htmlDoc
                    prerequisits = _(manifest.htdocs.page.dependencies.templates).map (item) ->
                        path.join libPrefix, item

                    prerequisits.unshift path.join libPrefix, htmlDoc

                    targetPath = "#{targetBuildPath}/#{templateName}.html"
                    targets.push targetPath
                    runtimeTargets.push [ targetPath, targetPath ]
                    makefileLines.push formatRule
                        targetPath: targetPath
                        preequisits: prerequisits
                        actions: [
                            "$(JADEC) $< --pretty --obj {\\\"name\\\":\\\"#{manifest.name}\\\"} --out #{targetBuildPath}"
                        ]


            # add rules for building and running tests according to manifest file content

            pre = _(targets).clone()
            pre = _(pre).flatten()
            if componentBuildResults?.length > 0
                pre.push path.join 'build', 'local_components', libPrefix

            # build the feature
            makefileLines.push formatRule
                targetPath: libPrefix
                preequisits: pre
                actions: [
                    "touch #{libPrefix}"
                ]
            globalTargets["build"] = [ libPrefix ]

            # create run rule, if mountpoint is set in manifest file
            if manifest.server?.mountPoint?.length
                makefileLines.push formatRule
                    targetPath: "#{libPrefix}/run"
                    preequisits: libPrefix
                    actions: [
                        "coffee #{libPrefix}/server.coffee"
                    ]

            # clean the feature
            targetPath = path.join libPrefix, "clean"
            makefileLines.push formatRule
                targetPath: targetPath
                preequisits: []
                actions: [
                    "rm -rf #{path.join libPrefix, 'build'}"
                    "rm -rf #{path.join libPrefix, 'components'}"
                ]
                phony: true
            globalTargets["clean"] = [ targetPath  ]

            # create rule to install couchbase views
            if manifest.database?.designDocuments?.length
                for designDocument in manifest.database.designDocuments
                    targetFileName = "#{libPrefix}/build/#{designDocument}"
                    makefileLines.push formatRule
                        targetPath: targetFileName
                        preequisits: "#{libPrefix}/#{designDocument}"
                        actions: [
                            "$(BIN)/jshint #{libPrefix}/#{designDocument}"
                            "$(COUCHVIEW_INSTALL) -s #{libPrefix}/#{designDocument}"
                            "mkdir -p #{path.dirname(targetFileName)}"
                            "touch #{targetFileName}"
                        ]

                targetPath = path.join libPrefix, "couchview"
                makefileLines.push formatRule
                    targetPath: targetPath
                    preequisits: _(manifest.database.designDocuments).map (value) ->
                        "#{libPrefix}/build/#{value}"
                    actions: []
                globalTargets["couchview"] = [ targetPath ]

            # create server code coffescript compile
            addCoffeeScriptFiles = (coffeeScriptFiles) ->
                targetPathList = []
                for coffeeScriptFile in coffeeScriptFiles
                    jsFilePath = path.join path.dirname(coffeeScriptFile), "#{path.basename(coffeeScriptFile, ".coffee")}.js"
                    targetPath = path.join libPrefix, "build", "server_scripts", jsFilePath
                    runtimeTargets.push [path.join(libPrefix, jsFilePath) , targetPath]
                    targetPathList.push targetPath
                    targetDir = path.dirname targetPath
                    sourcePath = path.join libPrefix, coffeeScriptFile
                    makefileLines.push formatRule
                        targetPath: targetPath
                        preequisits: sourcePath
                        actions: [
                            "@mkdir -p #{targetDir}"
                            "$(COFFEEC) -c $(COFFEE_FLAGS) --output #{targetDir} $<"
                        ]
                makefileLines.push formatRule
                    targetPath: path.join libPrefix, "build", "server_scripts"
                    preequisits: targetPathList.join(' ')
                    actions: [ ]

            if manifest.server?.scripts?.files?.length
                addCoffeeScriptFiles(manifest.server.scripts.files)


            if manifest.server?.scripts?.dirs?.length
                coffeeScriptFiles = []
                for scriptDir in manifest.server.scripts.dirs
                    scriptFiles = fs.readdirSync(path.join projectRoot, libPrefix, scriptDir)
                    for scriptFile in scriptFiles
                        if path.extname(scriptFile) is ".coffee"
                            tp = path.join scriptDir, scriptFile
                            coffeeScriptFiles.push tp
                addCoffeeScriptFiles(coffeeScriptFiles)

            # create unit test rule
            if manifest.server?.tests?.unit?.length
                targetPath = path.join libPrefix, "unit_test"
                unit_test_files = _(manifest.server.tests.unit).map (value) ->
                    "#{path.join(libPrefix,value)}"
                makefileLines.push formatRule
                    targetPath: targetPath
                    preequisits: libPrefix
                    actions: _(manifest.server.tests.unit).map (value) ->
                        "$(MOCHA) -R $(MOCHA_REPORTER) --compilers coffee:coffee-script #{path.join(libPrefix,value)}"
                globalTargets["unit_test"] = [ targetPath ]
                allTests.push 'unit_test'

            # create integration test rule
            if manifest.server?.tests?.integration?.length
                targetPath = path.join libPrefix, "integration_test"
                integration_test_files = _(manifest.server.tests.integration).map (value) ->
                    "#{path.join(libPrefix,value)}"
                makefileLines.push formatRule
                    targetPath: targetPath
                    preequisits: targetBuildPath
                    actions: _(manifest.server.tests.integration).map (value) ->
                        "$(MOCHA) -R $(MOCHA_REPORTER) --compilers coffee:coffee-script #{path.join(libPrefix,value)}"
                globalTargets["integration_test"] = [ targetPath ]
                allTests.push 'integration_test'

            # create phantom test rule
            if manifest.client?.tests?.mocha?.length
                targetPath = path.join libPrefix, "phantom_test"
                phantom_test_files = _(manifest.client.tests.mocha).map (value) ->
                    "#{path.join(libPrefix,value)}"
                makefileLines.push formatRule
                    targetPath: targetPath
                    preequisits: targetBuildPath
                    actions: _(manifest.client.tests.mocha).map (value) ->
                        "$(MOCHA) -R $(MOCHA_REPORTER) --compilers coffee:coffee-script #{path.join(libPrefix,value)}"
                globalTargets["phantom_test"] = [ targetPath ]
                allTests.push 'phantom_test'

            makefileLines.push formatRule
                targetPath: path.join libPrefix, 'test'
                preequisits: allTests.map (item) ->
                    path.join libPrefix, item
                actions: []

            if runtimeTargets.length
                for runtimeTarget in runtimeTargets
                    targetPath = path.join RUNTIME_DIR, runtimeTarget[0]
                    makefileLines.push formatRule
                        targetPath: targetPath
                        preequisits: runtimeTarget[1]
                        actions: [
                            "@mkdir -p #{path.dirname(targetPath)}"
                            "@cp  #{runtimeTarget[1]} #{targetPath} "
                        ]

                targetPath = path.join libPrefix, "install"
                makefileLines.push formatRule
                    targetPath: targetPath
                    preequisits: runtimeTargets.map (runtimeTarget) ->
                        path.join RUNTIME_DIR, runtimeTarget[0]
                    actions: []

                globalTargets["install"] = [ targetPath ]

                all_test_files = _.union(unit_test_files or [], integration_test_files or [], phantom_test_files or [])
                if all_test_files.length
                    touchMeTargetPath = path.join libPrefix, "touch_me"
                    makefileLines.push formatRule
                        targetPath: touchMeTargetPath
                        preequisits: [ ]
                        actions: [
                            "touch #{libPrefix}"
                        ]

                    targetPath = path.join libPrefix, "coverage"
                    mapped_test_files = _(all_test_files).map((testFilePath)->
                        "#{path.join(COVERAGE_DIR, testFilePath)} ").join(' ')
                    makefileLines.push formatRule
                        targetPath: targetPath
                        preequisits: [ touchMeTargetPath, "pre_coverage"]
                        actions: [
                            "-$(ISTANBUL_TEST_RUNNER) -p ../#{COVERAGE_DIR} -o #{path.join(libPrefix, "build", "coverage", "report")} #{mapped_test_files}"
                        ]
                    globalTargets["coverage"] = [ targetPath ]

                coveragePath = path.join(COVERAGE_DIR, libPrefix)
                coverageUnInstrumentedPath = path.join(COVERAGE_DIR, "uninstrumented_js_files", libPrefix)
                makefileLines.push formatRule
                    targetPath: coveragePath
                    preequisits: [libPrefix ]
                    actions: [
                        "@mkdir -p #{coveragePath}"
                        "@cp -r #{libPrefix}/* #{coveragePath}"
                        "$(COFFEEC) -c $(COFFEE_FLAGS) --output #{coverageUnInstrumentedPath} #{libPrefix} "
                        "$(ISTANBUL) instrument --no-compact -x \"**/test/**\" -x \"**/build/**\" -x \"**/_design/**\" -x \"**/components/**\" --output #{coveragePath}  #{coverageUnInstrumentedPath} "
                        "touch #{coveragePath}"
                    ]
                globalTargets["pre_coverage"] = [ coveragePath ]

            makefileLines =  _(makefileLines).flatten()

            cb null, makefileLines, globalTargets

    ], (err, makefileLines, globalTargets) ->
        if err? then return cb err
        makefileContent =  makefileLines.join '\n'
        cb null, makefileContent, globalTargets

if require.main is module
    findProjectRoot (err, projectRoot) ->

        if err?
            console.error err
            process.exit 1

        createLocalMakefileInc projectRoot, process.cwd(), (err, makefileContent) ->
            if err?
                console.error err
                process.exit 1

            process.stdout.write makefileContent
else
    module.exports = createLocalMakefileInc



