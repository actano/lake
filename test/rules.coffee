path = require 'path'
{resolveManifestVariables, resolveLocalComponentPaths, resolveFeatureRelativePaths, replaceExtension, lookup, concatPaths} = require "../src/rulebook_helper"

exports.title = 'all'
exports.description = """
    building web application with NodeJS, Couchbase, Component, CoffeeScript, Jade, Eco, Stylus and Mocha, Chai, PhantomJS for testing
"""
exports.addRules = (lake, featurePath, manifest, ruleBook) ->
    rb = ruleBook

    # These paths are all feature specific
    buildPath = path.join featurePath, lake.featureBuildDirectory
    componentsPath = path.join buildPath, "components"
    styluesBuildPath = path.join buildPath, "styles"
    documentationPath = path.join buildPath, "documentation"
    designPath = path.join featurePath, "_design"
    designBuildPath = path.join buildPath, "_design"
    projectRoot = path.resolve lake.lakePath, ".."
    localComponentPath = path.join lake.localComponentsPath, featurePath #  for client side targets
    runtimePath = path.join lake.runtimePath, featurePath # directory for server side compile results
    coveragePath = path.join lake.coveragePath, featurePath # for coffee coverage
    uninstrumentedPath = path.join lake.uninstrumentedPath, featurePath

    if manifest.client?.scripts?
        rb.addRule "coffee-client", ["client"], ->
            targets: concatPaths manifest.client.scripts, {pre: buildPath}, (file) ->
                replaceExtension file, '.js'
            dependencies: concatPaths manifest.client.scripts, {pre: featurePath}
            actions: "$(COFFEEC) -c $(COFFEE_FLAGS) -o #{buildPath} $^"

    if manifest.client?.styles?
        rb.addRule "stylus", ["client"], ->
            targets: concatPaths manifest.client.styles, {pre: buildPath}, (file) ->
                replaceExtension file, '.css'
            dependencies: concatPaths manifest.client.styles, {pre: featurePath}
            actions: [
                "mkdir -p #{styluesBuildPath}"
                "$(STYLUSC) $(STYLUS_FLAGS) -o #{styluesBuildPath} $^"
            ]

    if manifest.client?
        rb.addRule "component.json", ["client"], ->
            targets: path.join buildPath, "component.json"
            dependencies: path.join featurePath, "Manifest.coffee"
            actions: [
                "mkdir -p #{buildPath}"
                "$(COMPONENT_GENERATOR) $< $@"
            ]

        rb.addRule "component-install", ["client"], ->
            targets: componentsPath
            dependencies: [
                rb.getRuleById("component.json").targets
                resolveLocalComponentPaths manifest.client.dependencies.production.local, projectRoot, featurePath, lake.localComponentsPath
            ]
            actions: [
                "cd #{buildPath} && $(COMPONENT_INSTALL) $(COMPONENT_INSTALL_FLAGS) || rm -rf #{componentsPath}"
                "test -d #{componentsPath}"
                "touch #{componentsPath}"
            ]

        if manifest.client?.dependencies?.production?.local? 
            rb.addRule "component-build", ["client"], ->
                targets: [path.join(buildPath, manifest.name) + ".js", path.join(buildPath, manifest.name) + ".css"]
                dependencies: [
                    rb.getRuleById("component.json").targets
                    # NOTE: path for foreign components is relative, need to resolve it by build the absolute before
                    resolveLocalComponentPaths manifest.client.dependencies.production.local, projectRoot, featurePath, lake.localComponentsPath
                    rb.getRuleById("coffee-client").targets
                    rb.getRuleById("stylus").targets
                    rule.targets for rule in rb.getRulesByTag("jade-partials", true)
                ]
                # NOTE: component-build don't use (makefile) dependencies paramter, it parse the component.json
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
                dependencies: concatPaths manifest.documentation, {pre: featurePath}
                actions: [
                    "@mkdir -p #{documentationPath}"
                    concatPaths manifest.documentation, {}, (file) ->
                        "markdown #{path.join featurePath, file} > #{path.join documentationPath, file}"
                    "touch #{documentationPath}"
                ]

        if manifest.database?.designDocuments?
            rb.addRule "database", ["feature"], ->
                targets: concatPaths manifest.database.designDocuments, {pre: designBuildPath}
                dependencies: concatPaths manifest.database.designDocuments, {pre: designPath}
                actions: [
                    "mkdir -p #{path.join buildPath, "_design"}"
                    concatPaths manifest.database.designDocuments, {pre: designPath}, (file) ->
                        [
                            "$(BIN)/jshint #{file}"
                            "$(COUCHVIEW_INSTALL) -s #{file}"
                            "touch #{path.join designBuildPath, path.basename file}"
                        ]
                ]

        if manifest.server?.scripts?
            rb.addRule "server-scripts", ["feaure", "server"], ->
                targets: concatPaths manifest.server.scripts, {pre: featurePath}, (file) ->
                    replaceExtension file, '.js'
                dependencies: concatPaths manifest.server.scripts, {pre: buildPath}
                actions: [
                    "@mkdir -p #{buildPath}"
                    "$(COFFEEC) -c $(COFFEE_FLAGS) -o #{buildPath} $^"
                ]

        rb.addToGlobalTarget "build", rb.addRule "feature", ["full-feature"], ->
            targets: featurePath
            dependencies: rule.targets for rule in rb.getRulesByTag("feature", true)

        rb.addRule "runtime", [], ->
            targets: path.join featurePath, "install"
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
                targets: path.join featurePath ,'integration_test'
                dependencies: rb.getRuleById("feature").targets
                actions: concatPaths manifest.integrationTests.mocha, {pre: featurePath}, (testFile) ->
                    "$(MOCHA) -R $(MOCHA_REPORTER) --compilers coffee:coffee-script #{testFile}"

        if manifest.server?.tests?
            rb.addRule "unit-test", ["test"], ->
                targets: path.join featurePath, "unit_test"
                actions: concatPaths manifest.server.tests, {pre: featurePath}, (testFile) ->
                    "$(MOCHA) -R $(MOCHA_REPORTER) --compilers coffee:coffee-script #{testFile}"

        if manifest.client?.tests?.browser?.html?
            rb.addRule "browser-test-scripts", [], ->
                targets: concatPaths manifest.client.tests.browser.scripts, {}, (file) ->
                    replaceExtension path.join(buildPath, "test", file), ".js"
                dependencies: concatPaths manifest.client.tests.browser.scripts, {pre: featurePath}
                actions: "$(COFFEEC) -c $(COFFEE_FLAGS) -o #{path.join buildPath, 'test'} $^"

        if manifest.client?.tests?.browser?.html?
            rb.addRule "test-jade", [], ->
                targets: concatPaths [manifest.client.tests.browser.html], {pre: buildPath}, (file) ->
                    replaceExtension file, '.html'
                dependencies: [
                    path.join featurePath, manifest.client.tests.browser.html
                    rb.getRuleById("browser-test-scripts").targets
                    resolveFeatureRelativePaths manifest.client.tests.browser.dependencies, projectRoot, featurePath
                ]
                actions: concatPaths manifest.client.tests.browser.scripts, {}, (file) ->
                    "$(JADEC) $< -P -o {\\\"name\\\":\\\"#{manifest.name}\\\"\\\,\\\"tests\\\":\\\"#{replaceExtension file, '.js'}\\\"} -O #{buildPath}"

        if manifest.client?.tests?.browser?.assets?.scripts? 
            rb.addRule "client-test-script-assets", ["test-assets"], ->
                resolvedFiles = resolveManifestVariables manifest.client.tests.browser.assets.scripts, projectRoot
                return {
                    targets: concatPaths manifest.client.tests.browser.assets.scripts, {}, (file) ->
                        path.join(buildPath, path.basename(file))
                    dependencies: resolvedFiles
                    actions: concatPaths resolvedFiles, {}, (file) ->
                        "cp #{file} #{path.join(buildPath, path.basename(file))}"
                }

        if manifest.client?.tests?.browser?.assets?.styles? 
            rb.addRule "client-test-style-assets", ["test-assets"], ->
                resolvedFiles = resolveManifestVariables manifest.client.tests.browser.assets.styles, projectRoot
                return {
                    targets: concatPaths manifest.client.tests.browser.assets.styles, {}, (file) ->
                        path.join(buildPath, path.basename(file))
                    dependencies: resolvedFiles
                    actions: concatPaths resolvedFiles, {}, (file) ->
                        "cp #{file} #{path.join(buildPath, path.basename(file))}"
                }

        if manifest.client?.tests?.browser?
            rb.addRule "client-test", ["test"], ->
                targets: path.join featurePath, "client_test"
                dependencies: [
                    rb.getRuleById("feature").targets
                    rb.getRuleById("test-jade").targets
                    rule.targets for rule in rb.getRulesByTag("test-assets", true)
                ]
                actions: [
                    # manifest.client.tests.browser.html is 'test/test.jade' --convert to--> 'test.html'
                    "$(BIN)/mocha-phantomjs -R tap #{path.join buildPath, path.basename(replaceExtension(manifest.client.tests.browser.html, '.html'))}"
                ]

        rb.addRule "test-all", [], ->
            targets: path.join featurePath, "testall"
            dependencies: rule.targets for rule in rb.getRulesByTag("test", true)

        rb.addToGlobalTarget "clean", rb.addRule "clean", [], ->
            targets: path.join featurePath, "clean"
            actions: "rm -rf #{buildPath}"

    if manifest.client?.templates?
        for jadeTemplate in manifest.client.templates
            ((jadeTemplate) ->
                rb.addRule "jade.template.#{jadeTemplate}", ["client", "jade-partials"], ->
                    targets: path.join buildPath, replaceExtension(jadeTemplate, '.js')
                    dependencies: path.join featurePath, jadeTemplate
                    actions: [
                        "@mkdir -p #{path.join buildPath, "views"}"
                        "@echo \"module.exports=\" > $@"
                        "$(JADEC) --client --path $< < $< >> $@"
                    ]
            )(jadeTemplate)

    if manifest.htdocs?
        for key, value of manifest.htdocs
            ((key) ->
                rb.addRule "htdocs.#{key}", ["client"], ->
                    targets: path.join buildPath, path.basename(replaceExtension((lookup manifest, "htdocs.#{key}.html"), '.html'))
                    # NOTE: path for foreign feature dependencies is relative, need to resolve it by build the absolute before
                    dependencies: [
                        path.join(featurePath, lookup(manifest, "htdocs.#{key}.html"))
                        resolveFeatureRelativePaths lookup(manifest, "htdocs.#{key}.dependencies.templates"), projectRoot, featurePath
                    ]
                    actions: "$(JADEC) $< --pretty --obj {\\\"name\\\":\\\"#{manifest.name}\\\"} --out #{buildPath}"
            )(key)

