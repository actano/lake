{join, basename, dirname, resolve} = require 'path'
debug = require('debug')('rules.coffee')

exports.title = 'all'
exports.description = """
    building web application with NodeJS, Couchbase, Component, CoffeeScript, Jade, Eco, Stylus and Mocha, Chai, PhantomJS for testing
"""
exports.addRules = (lake, featurePath, manifest, ruleBook) ->
    rb = ruleBook

    # These paths are all feature specific
    buildPath = join featurePath, lake.featureBuildDirectory
    componentsPath = join buildPath, "components"
    styluesBuildPath = join buildPath, "styles"
    documentationPath = join buildPath, "documentation"
    designPath = join featurePath, "_design"
    designBuildPath = join buildPath, "_design"
    projectRoot = resolve lake.lakePath, ".."
    localComponentPath = join lake.localComponentsPath, featurePath #  for client side targets
    runtimePath = join lake.runtimePath, featurePath # directory for server side compile results
    coveragePath = join lake.coveragePath, featurePath # for coffee coverage
    uninstrumentedPath = join lake.uninstrumentedPath, featurePath

    if manifest.client?.scripts?

        for script in manifest.client.scripts
            ((script) ->
                scriptPath = join buildPath, script
                outputScriptDir = join buildPath, dirname script
                rb.addRule "client-#{script}", ["coffee-client", "client", 'component-build-prerequisite'], ->
                    targets: join(outputScriptDir, basename script).replace /\..*$/, '.js'
                    dependencies: join featurePath, script
                    actions: "$(COFFEEC) -c $(COFFEE_FLAGS) -o #{outputScriptDir} $^"
            )(script)

    if manifest.client?.styles?.length
        rb.addRule "stylus", ["client", 'component-build-prerequisite'], ->
            targets: join(buildPath, style).replace(/\..*$/, '.css') for style in manifest.client.styles
            dependencies: join(featurePath, style) for style in manifest.client.styles
            actions: [
                "mkdir -p #{styluesBuildPath}"
                "$(STYLUSC) $(STYLUS_FLAGS) -o #{styluesBuildPath} $^"
            ]

    if manifest.client?
        if manifest.client.main?
            rb.addRule "component.json", ["client", 'component-build-prerequisite'], ->
                targets: [join buildPath, "component.json"]
                dependencies: join featurePath, "Manifest.coffee"
                actions: [
                    "mkdir -p #{buildPath}"
                    "$(COMPONENT_GENERATOR) $< $@"
                ]

        if manifest.client.dependencies?
            rb.addRule "component-install", ["client"], ->
                targets: componentsPath
                dependencies: [
                    rb.getRuleById("component.json").targets
                    join(lake.localComponentsPath, entry) for entry in manifest.lookupPath 'client.dependencies.production.local'
                ]
                actions: [
                    "cd #{buildPath} && $(COMPONENT_INSTALL) $(COMPONENT_INSTALL_FLAGS) || rm -rf #{componentsPath}"
                    "test -d #{componentsPath}"
                    "touch #{componentsPath}"
                ]

        if manifest.client?.dependencies?.production?.local?
            rb.addRule "component-build", ["client"], ->
                targets: [join(buildPath, manifest.name) + '.js', join(buildPath, manifest.name) + '.css']
                dependencies: [
                    # NOTE: path for foreign components is relative, need to resolve it by build the absolute before
                    join(lake.localComponentsPath, entry) for  entry in manifest.lookupPath 'client.dependencies.production.local'
                    rule.targets for rule in rb.getRulesByTag('component-build-prerequisite', true)
                ]
                # NOTE: component-build don't use (makefile) dependencies parameter, it parse the component.json
                actions: "cd #{buildPath} && $(COMPONENT_BUILD) $(COMPONENT_BUILD_FLAGS) --name #{manifest.name} -v -o ./"

        if manifest.client?
            rb.addRule "local-components", ["feature"], ->
                targets: localComponentPath
                dependencies: rule.targets for rule in rb.getRulesByTag("client", true)
                # TODO: use dependencies in the action, but without foreign features / only own created feature files
                actions: [
                    "mkdir -p #{localComponentPath}"
                    "cp -r #{buildPath}/* #{localComponentPath}"
                    "touch #{localComponentPath}"
                ]

        if manifest.documentation?
            rb.addRule "documentation", ["feature"], ->
                targets: documentationPath
                dependencies: join(featurePath, doc) for doc in manifest.documentation
                actions: [
                    "@mkdir -p #{documentationPath}"
                    for file in manifest.documentation
                        "markdown #{join featurePath, file} > #{join documentationPath, file}"
                    "touch #{documentationPath}"
                ]

        if manifest.database?.designDocuments?
            rb.addRule "database", [], ->
                targets: join(buildPath, doc) for doc in manifest.database.designDocuments
                dependencies: join(featurePath, doc) for doc in manifest.database.designDocuments
                actions: [
                    "mkdir -p #{join buildPath, "_design"}"
                    designDocs = _(manifest.database.designDocuments).map (file) ->
                        join featurePath, file
                    for file in designDocs
                        [
                            "$(NODE_BIN)/jshint #{file}"
                            "$(COUCHVIEW_INSTALL) -s #{file}"
                            "touch #{join designBuildPath, basename file}"
                        ]
                ]

        if manifest.server?.scripts?
            rb.addRule "server-scripts", ["feaure", "server"], ->
                targets: join(featurePath, script).replace(/\..*$/, '.js') for script in manifest.server.scripts
                dependencies: join(buildPath, script) for script in manifest.server.scripts
                actions: [
                    "@mkdir -p #{buildPath}"
                    "$(COFFEEC) -c $(COFFEE_FLAGS) -o #{buildPath} $^"
                ]

        rb.addToGlobalTarget "build", rb.addRule "feature", ["full-feature"], ->
            targets: featurePath
            dependencies: rule.targets for rule in rb.getRulesByTag("feature", true)

        rb.addRule "runtime", [], ->
            targets: join featurePath, "install"
            dependencies: rule.targets for rule in rb.getRulesByTag("feature", true)
            actions: "rsync -rR $^ #{runtimePath}"

        rb.addRule "global-coverage", [], ->
            targets: coveragePath
            dependencies: featurePath
            actions: [
                "@mkdir -p #{coveragePath}"
                "@cp -r #{featurePath}/* #{coveragePath}"
                "$(COFFEEC) -c $(COFFEE_FLAGS) -o #{uninstrumentedPath} #{featurePath}"
                "$(ISTANBUL) instrument --no-compact -x \"**/test/**\" -x \"**/build/**\" -x \"**/_design/**\" -x \"**/components/**\" --output #{coveragePath} #{uninstrumentedPath}"
                "touch #{coveragePath}"
            ]

        if manifest.integrationTests?.mocha?
            rb.addRule "integration-test", ["test"], ->
                targets: join featurePath ,'integration_test'
                dependencies: rb.getRuleById("feature").targets
                actions: for testFile in manifest.integrationTests.mocha
                    "$(MOCHA) -R $(MOCHA_REPORTER) --compilers coffee:coffee-script #{join featurePath, testFile}"

        if manifest.server?.tests?
            rb.addRule "unit-test", ["test"], ->
                targets: join featurePath, "unit_test"
                actions: for testFile in manifest.server.tests
                    "$(MOCHA) -R $(MOCHA_REPORTER) --compilers coffee:coffee-script #{join featurePath, testFile}"

        if manifest.client?.tests?.browser?.scripts?
            rb.addRule "browser-test-scripts", [], ->
                targets: join(buildPath, "test", script).replace(/\..*$/, '.js') for script in manifest.client.tests.browser.scripts
                dependencies: join(featurePath, script) for script in manifest.client.tests.browser.scripts
                actions: "$(COFFEEC) -c $(COFFEE_FLAGS) -o #{join buildPath, 'test'} $^"

        if manifest.client?.tests?.browser?.html?
            rb.addRule "test-jade", [], ->
                targets: [join(buildPath, manifest.client.tests.browser.html).replace(/\..*$/, '.html')]
                dependencies: [
                    join featurePath, manifest.client.tests.browser.html
                    rb.getRuleById("browser-test-scripts").targets
                    manifest.lookupPath 'client.tests.browser.dependencies'
                ]
                actions: for script in manifest.client.tests.browser.scripts
                    "$(JADEC) $< -P -o {\\\"name\\\":\\\"#{manifest.name}\\\"\\\,\\\"tests\\\":\\\"#{script.replace(/\..*$/, '.js')}\\\"} -O #{buildPath}"

        if manifest.client?.tests?.browser?.assets?.scripts?
            rb.addRule "client-test-script-assets", ["test-assets"], ->
                scripts = manifest.lookupPath 'client.tests.browser.assets.scripts'
                return {
                    targets: join(buildPath, basename script) for script in scripts
                    dependencies: scripts
                    actions: for file in scripts
                        "cp #{file} #{join(buildPath, basename(file))}"
                }

        if manifest.client?.tests?.browser?.assets?.styles?
            rb.addRule "client-test-style-assets", ["test-assets"], ->
                styles = manifest.lookupPath 'client.tests.browser.assets.styles'
                return {
                    # FIXME: the use of basename cuts of any path in the manifest
                    # (this problem occures not only here)
                    targets: join(buildPath, basename(file)) for file in styles
                    dependencies: manifest.lookupPath 'client.tests.browser.assets.styles'
                    actions: for file in styles
                        "cp #{file} #{join(buildPath, basename(file))}"
                }

        if manifest.client?.tests?.browser?
            rb.addRule "client-test", ["test"], ->
                targets: join featurePath, "client_test"
                dependencies: [
                    rb.getRuleById("feature").targets
                    rb.getRuleById("test-jade").targets
                    rule.targets for rule in rb.getRulesByTag("test-assets", true)
                ]
                actions: [
                    # manifest.client.tests.browser.html is 'test/test.jade' --convert to--> 'test.html'
                    "$(NODE_BIN)/mocha-phantomjs -R tap #{join buildPath, basename(manifest.client.tests.browser.html.replace /\..*$/, '.html')}"
                ]

        rb.addRule "test-all", [], ->
            targets: join featurePath, "testall"
            dependencies: rule.targets for rule in rb.getRulesByTag("test", true)

        rb.addToGlobalTarget "clean", rb.addRule "clean", [], ->
            targets: join featurePath, "clean"
            actions: "rm -rf #{buildPath}"

    if manifest.client?.templates?
        for jadeTemplate in manifest.client.templates
            ((jadeTemplate) ->
                rb.addRule "jade.template.#{jadeTemplate}", ["client", "jade-partials",'component-build-prerequisite'], ->
                    targets: join buildPath, jadeTemplate.replace(/\..*$/, '.js')
                    dependencies: join featurePath, jadeTemplate
                    actions: [
                        "@mkdir -p #{join buildPath, "views"}"
                        "@echo \"module.exports=\" > $@"
                        "$(JADEC) --client --path $< < $< >> $@"
                    ]
            )(jadeTemplate)

    if manifest.htdocs?
        for key, value of manifest.htdocs
            ((key) ->
                rb.addRule "htdocs.#{key}", ["client"], ->
                    targets: join buildPath, basename(manifest.lookup "htdocs.#{key}.html").replace(/\..*$/, '.html')
                    # NOTE: path for foreign feature dependencies is relative, need to resolve it by build the absolute before
                    dependencies: [
                        manifest.lookupPath "htdocs.#{key}.html"
                        manifest.lookupPath "htdocs.#{key}.dependencies.templates"
                    ]
                    actions: "$(JADEC) $< --pretty --obj {\\\"name\\\":\\\"#{manifest.name}\\\"} --out #{buildPath}"
            )(key)

