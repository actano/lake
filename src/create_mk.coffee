fs = require 'fs'
path = require 'path'
async = require 'async'
{_} = require 'underscore'
debug = require('debug')('lake.create_mk')

RuleBook = require './rulebook'


MANIFEST_FILE_NAME = "Manifest.coffee"
MAKEFILE_MK_NAME = "dev_Makefile.mk"
BUILD_SUFFIX = 'build'
LOCAL_COMPONENTS = path.join "build", "local_components"

# config key names, for better refactoring
CFG_CONDITION = "condition"
CFG_TARGET = "target"
CFG_DEPENDENCIES = "dependencies"
CFG_ACTIONS = "actions"
CFG_TARGET_REGEX = "targetRegex"
CFG_GLOBAL_TARGET = "globalTarget"


projectRoot = undefined             # absolute path: /Users/john/projectX
absoluteFeaturePath = undefined     # absolute path: /Users/john/projectX/foo/bar/featureA
featureName = undefined             # for example: featureA
featurePath = undefined             # for example: foo/bar/featureA
featureBuildPath = undefined        # for example: foo/var/featureA/build
manifestPath = undefined            # for example: foo/bar/featureA/Manifest.coffee
manifest = undefined                # manifest object
rules = undefined                   # container objects for all rule configration


createLocalMakefileInc = (lakeConfig, pr, fp, outerCb) ->

    projectRoot = pr
    absoluteFeaturePath = fp
    featurePath = path.relative projectRoot, absoluteFeaturePath
    #featureBuildPath = path.join featurePath, BUILD_SUFFIX
    #featureName = path.basename featurePath
    # check manifest
    absoluteManifestPath = path.join absoluteFeaturePath, MANIFEST_FILE_NAME
    #manifestPath = path.relative projectRoot, absoluteManifestPath # relative manifest path
    try
        manifest = require absoluteManifestPath
    catch err
        console.error "#{MANIFEST_FILE_NAME} for #{featurePath} cannot be parsed: #{err.message}"
        throw err

    ruleBook = new RuleBook()
    for ruleFile in lakeConfig.ruleCollection
        ruleFilePath = path.join projectRoot, ruleFile
        unless fs.existsSync ruleFilePath
            throw new Error "rule file not found at #{ruleFilePath}"
        rules = require ruleFilePath
        ruleList = rules.addRules lakeConfig, featurePath, manifest, ruleBook

        # add rules into ruleBook
        ruleBook.add id, wrapper for id, wrapper of ruleList

    # evaluate the rules, call 'factory()'
    ruleBook.resolveAllFactories()

    console.log ruleBook.getRules()

    outerCb new Error "not implemented"

###
    last parameter (outerCb) is a callback with thre params (err, mkContent, globalTargets)
###
createLocalMakefileIncOld = (pr, fp, outerCb) ->

    rules = {}

    #TODO: need to iterate over client.scripts
    rules["client.js"] =
        target: path.join featureBuildPath, "client.js"
        dependencies: prefixPaths manifest.client.scripts, featurePath
        actions: [
            "$(COFFEEC) -c $(COFFEE_FLAGS) --output #{featureBuildPath} $<"
        ]


    rules["styles"] =
        target: path.join featureBuildPath, "styles", "#{manifest.name}.css"
        dependencies: prefixPaths manifest.client.styles, featurePath
        actions: [
            "mkdir -p #{path.join featureBuildPath, "styles"}"
            "$(STYLUSC) $(STYLUS_FLAGS) --out #{path.join featureBuildPath, "styles"} $<"
        ]
    rules["component.json"] =
        target: path.join featureBuildPath, "component.json"
        dependencies: manifestPath
        actions: [
            "mkdir -p #{featureBuildPath}"
            "$(COMPONENT_GENERATOR) $< $@"
        ]
    rules["components"] =
        target: path.join featureBuildPath, "components"
        dependencies: -> getTargetOfRule "component.json"
        actions: [
            "cd #{featureBuildPath} && $(COMPONENT_INSTALL) $(COMPONENT_INSTALL_FLAGS) || rm -rf #{path.join featurePath,"components"}"
            "test -d #{path.join featurePath,"components"}"
            "touch #{path.join featurePath,"components"}"
        ]

    ###
        build/local_components/lib/usermanagement:
        build/local_components/lib/bind-jade build/local_components/lib/widgetevents build/local_components/lib/i18n lib/usermanagement/build/component.json lib/usermanagement/build/client.js lib/usermanagement/build/styles/usermanagement.css lib/usermanagement/build/views/entry-partial.js lib/usermanagement/build/views/firstrow.js
        # local dependencies
        # component.json
        # client.js
        # <NAME>.css
        # partials / templates/views


    mkdir -p build/local_components/lib/usermanagement
        cp -r lib/usermanagement/build/* build/local_components/lib/usermanagement
        touch build/local_components/lib/usermanagement
    ###
    rules["local_components"] =
        target: path.join LOCAL_COMPONENTS, featurePath
        dependencies: [] # TODO: analyse and clean up current Makefile.mk
        action: []

    ###
        lib/usermanagement/build/usermanagement.js lib/usermanagement/build/usermanagement.css: build/local_components/lib/bind-jade build/local_components/lib/widgetevents build/local_components/lib/i18n lib/usermanagement/build/components lib/usermanagement/build/client.js lib/usermanagement/build/styles/usermanagement.css lib/usermanagement/build/views/entry-partial.js lib/usermanagement/build/views/firstrow.js
        cd lib/usermanagement/build && $(COMPONENT_BUILD) $(COMPONENT_BUILD_FLAGS) --name usermanagement --standalone usermanagement -v -o ./

        lib/usermanagement/build/client.js lib/usermanagement/build/styles/usermanagement.css lib/usermanagement/build/views/entry-partial.js lib/usermanagement/build/views/firstrow.js

    ###
    rules[featurePath] =
        globalTarget: true
        target: [path.join featureBuildPath, "#{featureName}.js", path.join featureBuildPath, "#{featureName}.css"]
        dependencies: [
            getTargetOfRule "client.js"
            getTargetOfRule "#{featureName}.css"
            getTargetOfRule "client.template.*" #TODO: implement a wildcard string

        ]

    rules["runtime"] =
        target: path.join featureBuildPath, 'runtime'
        dependencies: () ->
            keys = _(rules).keys()
            targets = (getTargetOfRule ruleName for ruleName in keys)
        actions: "rsync -rR $^ #{path.join 'runtime', featureBuildPath}"

    # partials
    for jadeView in manifest.client.templates
        rules["client.template.#{jadeView}"] =
            target: path.join featureBuildPath, jadeView
            dependencies: path.join featurePath, jadeView
            actions: [
                "@mkdir -p #{path.join featureBuildPath, "views"}"
                "@echo \"module.exports=\" > $@"
                "$(JADEC) --client --path $< < $< >> $@"
            ]
            targetRegex: 
                pattern:/\.jade/
                replacement:".js"


    rules["component.install"] =
        target: () -> componentPath
        dependencies: path.join featureBuildPath, "component.json"
        actions: [
            "cd #{featureBuildPath} && $(COMPONENT_INSTALL) $(COMPONENT_INSTALL_FLAGS) || rm -rf #{componentPath}"
            "test -d #{componentPath}"
            "touch #{componentPath}"
        ]

    rules["integration.test"] =
        condition: () ->  lookup manifest, 'integrationTest' # create the rule only if the manifest property exist, interpret error as false
        target: path.join featurePath ,'integration_test'
        dependencies: featureBuildPath
        actions: () ->
            prefixPaths manifest.integrationTests.mocha, featureBuildPath, (item) ->
                "$(MOCHA) -R $(MOCHA_REPORTER) --compilers coffee:coffee-script #{item}"

    # dynamic
    _(manifest.htdocs).each (value, key) ->
        rules["htdocs.#{key}"] =
            condition: () -> lookup manifest, "htdocs.#{key}"
            #TODO: helper function to replace extension of filename with basename
            target: path.join featureBuildPath, replaceExtension((lookup manifest, "htdocs.#{key}.html"), 'js')
            #dependencies: prefixPaths (lookup manifest, "htdocs.#{key}.dependencies.templates"), featurePath
            dependencies: [
                lookup manifest, "htdocs.#{key}"
                #TODO: remaining dependencies
            ]
            actions: "$(JADEC) $< --pretty --obj {\"name\":\"#{manifest.name}\"} --out #{featureBuildPath}"


    ###
       RULES END
    ###


    writeMkFile rules, ruleNameList, (err, relativeMkPath, globalTargets) ->
        if err?
            return outerCb err
        console.log "########################################"
        outerCb new Error "create_mk is not fully implemented"
        #outerCb err, relativeMkPath, globalTargets

# TODO: refactor for RuleBook API
writeMkFile = (rules, ruleNameList, cb) ->
    buffer = ""
    globalTargets = []
    _(ruleNameList).each (ruleName) ->
        localBuffer = ""
        currentRule = rules[ruleName]
        target = currentRule[CFG_TARGET]
        if currentRule[CFG_GLOBAL_TARGET]? and currentRule[CFG_GLOBAL_TARGET] is true
            globalTargets.push target
        dependencies = currentRule[CFG_DEPENDENCIES]
        actions = currentRule[CFG_ACTIONS]
        localBuffer 
        localBuffer += "# #{ruleName}\n"
        localBuffer += "#{target}: #{dependencies}\n"
        if actions?
            localBuffer += "\t#{actions}\n\n"
        else
            localBuffer += "\n"

        console.log localBuffer
        buffer += localBuffer


    mkFilePath = path.join projectRoot, featurePath, MAKEFILE_MK_NAME
    relativeMkPath = path.relative projectRoot, mkFilePath
    fs.writeFile mkFilePath, buffer, (err) ->
        if err?
            console.error "error writing #{mkFilePath}"
            throw err
        cb null, relativeMkPath, globalTargets



module.exports = createLocalMakefileInc

