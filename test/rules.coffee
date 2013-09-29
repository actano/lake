path = require 'path'
{resolveManifestVariables, resolveLocalComponentPaths, resolveFeatureRelativePaths, replaceExtension, lookup, concatPaths} = require "../src/rulebook_helper"

module.exports =
    title: 'all'
    description: "building web application with NodeJS, Couchbase, Component, CoffeeScript, Jade, Eco, Stylus and Mocha, Chai, PhantomJS for testing"
    addRules: (lake, featurePath, manifest, rb) ->

        # NOTE: these paths are all feature specific !
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

        rules =

            "coffee-client":
                condition: manifest.client?.scripts?
                tags: ["client"]
                factory: ->
                    targets: concatPaths manifest.client.scripts, {pre: buildPath}, (file) ->
                        replaceExtension file, '.js'
                    dependencies: concatPaths manifest.client.scripts, {pre: featurePath}
                    actions: "$(COFFEEC) -c $(COFFEE_FLAGS) -o #{buildPath} $^"

            "sylus":
                condition: manifest.client?.styles?
                tags: ["client"]
                factory: ->
                    targets: concatPaths manifest.client.styles, {pre: buildPath}, (file) ->
                        replaceExtension file, '.css'
                    dependencies: concatPaths manifest.client.styles, {pre: featurePath}
                    actions: [
                        "mkdir -p #{styluesBuildPath}"
                        "$(STYLUSC) $(STYLUS_FLAGS) -o #{styluesBuildPath} $^"
                    ]

            "component.json":
                condition: manifest.client?
                tags: ["client"]
                factory: ->
                    targets: path.join buildPath, "component.json"
                    dependencies: path.join featurePath, "Manifest.coffee"
                    actions: [
                        "mkdir -p #{buildPath}"
                        "$(COMPONENT_GENERATOR) $< $@"
                    ]

            "component-install":
                condition: manifest.client?
                tags: ["client"]
                factory: ->
                    targets: componentsPath
                    dependencies: rb.getRuleById("component.json").targets
                    actions: [
                        "cd #{buildPath} && $(COMPONENT_INSTALL) $(COMPONENT_INSTALL_FLAGS) || rm -rf #{componentsPath}"
                        "test -d #{componentsPath}"
                        "touch #{componentsPath}"
                    ]


            "component-build":
                condition: manifest.client?.dependencies?.production?.local? and manifest.client?.scripts?
                tags: ["client"]
                factory: ->
                    targets: [path.join(buildPath, manifest.name) + ".js", path.join(buildPath, manifest.name) + ".css"]
                    dependencies: [
                        rb.getRuleById("component.json").targets
                        # NOTE: path for foreign components is relative, need to resolve it by build the absolute before
                        resolveLocalComponentPaths manifest.client.dependencies.production.local, projectRoot, featurePath, lake.localComponentsPath
                        rb.getRuleById("coffee-client").targets
                        rb.getRuleById("sylus").targets
                        rule.targets for rule in rb.getRulesByTag("jade-partials", true)

                    ]
                    # NOTE: component-build don't use (makefile) dependencies paramter, it parse the component.json
                    actions: "cd #{buildPath} && $(COMPONENT_BUILD) $(COMPONENT_BUILD_FLAGS) --name #{manifest.name} -v -o ./"

            "local-components":
                condition: manifest.client?
                tags: ["feature"]
                factory: ->
                    targets: localComponentPath
                    dependencies: rule.targets for rule in rb.getRulesByTag("client", true)
                    # TODO: use dependencies in the action, but without foreign features / only own created feature files
                    actions: [
                        "mkdir -p #{localComponentPath}"
                        "cp -r #{buildPath}/* #{localComponentPath}"
                        "touch #{localComponentPath}"
                    ]


            "documentation":
                condition: manifest.documentation?
                tags: ["feature"]
                factory: ->
                    targets: documentationPath
                    dependencies: concatPaths manifest.documentation, {pre: featurePath}
                    actions: [
                        "@mkdir -p #{documentationPath}"
                        concatPaths manifest.documentation, {}, (file) ->
                            "markdown #{path.join featurePath, file} > #{path.join documentationPath, file}"
                        "touch #{documentationPath}"
                    ]

            "database":
                condition: manifest.database?.designDocuments?
                tags: ["feature"]
                factory: ->
                    targets: concatPaths manifest.database.designDocuments, {pre: designBuildPath}
                    dependencies: concatPaths manifest.database.designDocuments, {pre: designPath}
                    actions: [
                        "mkdir -p #{path.join buildPath, "_design"}"
                        concatPaths manifest.database.designDocuments, {pre: designPath}, (file) ->
                            [
                                "#$(BIN)/jshint #{file}"
                                "#$(COUCHVIEW_INSTALL) -s #{file}"
                                "touch #{path.join designBuildPath, path.basename file}"
                            ]
                    ]

            "server-scripts":
                condition: manifest.server?.scripts?
                tags: ["feaure", "server"]
                factory: ->
                    targets: concatPaths manifest.server.scripts, {pre: featurePath}, (file) ->
                        replaceExtension file, '.js'
                    dependencies: concatPaths manifest.server.scripts, {pre: buildPath}
                    actions: [
                        "@mkdir -p #{buildPath}"
                        "$(COFFEEC) -c $(COFFEE_FLAGS) -o #{buildPath} $^"
                    ]

            "feature":
                tags: ["full-feature"]
                global: ["build"]
                factory: ->
                    targets: featurePath
                    dependencies: rule.targets for rule in rb.getRulesByTag("feature", true)

            "runtime":
                factory: ->
                    targets: path.join featurePath, "install"
                    dependencies: rule.targets for rule in rb.getRulesByTag("feature", true)
                    actions: "rsync -rR $^ #{runtimePath}"

            "global-coverage":
                factory: ->
                    targets: coveragePath
                    dependencies: featurePath
                    actions: [
                        "@mkdir -p #{coveragePath}"
                        "@cp -r #{featurePath}/* #{coveragePath}"
                        "$(COFFEEC) -c $(COFFEE_FLAGS) -o #{uninstrumentedPath} #{featurePath}"
                        "$(ISTANBUL) instrument --no-compact -x \"**/test/**\" -x \"**/build/**\" -x \"**/_design/**\" -x \"**/components/**\" --output #{coveragePath} #{uninstrumentedPath}"
                        "touch #{coveragePath}"
                    ]

            "integration-test":
                condition: manifest.integrationTests?.mocha?
                tags: ["test"]
                factory: ->
                    targets: path.join featurePath ,'integration_test'
                    dependencies: rb.getRuleById("feature").targets
                    actions: concatPaths manifest.integrationTests.mocha, {pre: featurePath}, (testFile) ->
                        "$(MOCHA) -R $(MOCHA_REPORTER) --compilers coffee:coffee-script #{testFile}"


            "unit-test":
                condition: manifest.server?.tests?
                tags: ["test"]
                factory: ->
                    targets: path.join featurePath, "unit_test"
                    actions: concatPaths manifest.server.tests, {pre: featurePath}, (testFile) ->
                        "$(MOCHA) -R $(MOCHA_REPORTER) --compilers coffee:coffee-script #{testFile}"


            "browser-test-scripts":
                condition: manifest.client?.tests?.browser?.html?
                factory: () ->
                    targets: concatPaths manifest.client.tests.browser.scripts, {}, (file) ->
                        replaceExtension path.join(buildPath, "test", file), ".js"
                    dependencies: concatPaths manifest.client.tests.browser.scripts, {pre: featurePath}
                    actions: "$(COFFEEC) -c $(COFFEE_FLAGS) -o #{path.join buildPath, 'test'} $^"

            "test-jade":
                condition: manifest.client?.tests?.browser?.html?
                factory: () ->
                    targets: concatPaths [manifest.client.tests.browser.html], {pre: buildPath}, (file) ->
                        replaceExtension file, '.html'
                    dependencies: [
                        path.join featurePath, manifest.client.tests.browser.html
                        rb.getRuleById("browser-test-scripts").targets
                        resolveFeatureRelativePaths manifest.client.tests.browser.dependencies, projectRoot, featurePath
                    ]
                    actions: concatPaths manifest.client.tests.browser.scripts, {}, (file) ->
                        "$(JADEC) $< -P -o {\\\"name\\\":\\\"#{manifest.name}\\\"\\\,\\\"tests\\\":\\\"#{replaceExtension file, '.js'}\\\"} -O #{buildPath}"

            "client-test-script-assets":
                condition: manifest.client?.tests?.browser?.assets?.scripts?
                tags: ["test-assets"]
                factoryParams: -> resolveManifestVariables manifest.client.tests.browser.assets.scripts, projectRoot
                factory: (resolvedFiles) ->
                    targets: concatPaths manifest.client.tests.browser.assets.scripts, {}, (file) ->
                        path.join(buildPath, path.basename(file))
                    dependencies: resolvedFiles
                    actions: concatPaths resolvedFiles, {}, (file) ->
                        "cp #{file} #{path.join(buildPath, path.basename(file))}"

            "client-test-style-assets":
                condition: manifest.client?.tests?.browser?.assets?.styles?
                tags: ["test-assets"]
                factoryParams: -> resolveManifestVariables manifest.client.tests.browser.assets.styles, projectRoot
                factory: (resolvedFiles) ->
                    targets: concatPaths manifest.client.tests.browser.assets.styles, {}, (file) ->
                        path.join(buildPath, path.basename(file))
                    dependencies: resolvedFiles
                    actions: concatPaths resolvedFiles, {}, (file) ->
                        "cp #{file} #{path.join(buildPath, path.basename(file))}"

            "client-test":
                condition: manifest.client?.tests?.browser?
                tags: ["test"]
                factory: ->
                    targets: path.join featurePath, "client_test"
                    dependencies: [
                        rb.getRuleById("test-jade").targets
                        rule.targets for rule in rb.getRulesByTag("test-assets", true)
                    ]
                    actions: [
                        # manifest.client.tests.browser.html is 'test/test.jade' --convert to--> 'test.html'
                        "$(BIN)/mocha-phantomjs -R tap #{path.join buildPath, path.basename(replaceExtension(manifest.client.tests.browser.html, '.html'))}"
                    ]

            "test-all":
                factory: ->
                    targets: path.join featurePath, "testall"
                    dependencies: rule.targets for rule in rb.getRulesByTag("test", true)

            "clean":
                global: ["clean"]
                factory: ->
                    targets: path.join featurePath, "clean"
                    actions: "rm -rf #{buildPath}"


        if manifest.client?.templates?
            for jadeTemplate in manifest.client.templates
                rules["jade.template.#{jadeTemplate}"] =
                    tags: ["client", "jade-partials"]
                    factoryParams: jadeTemplate
                    factory: (jadeTemplate) ->
                        targets: path.join buildPath, replaceExtension(jadeTemplate, '.js')
                        dependencies: path.join featurePath, jadeTemplate
                        actions: [
                            "@mkdir -p #{path.join buildPath, "views"}"
                            "@echo \"module.exports=\" > $@"
                            "$(JADEC) --client --path $< < $< >> $@"
                        ]
        if manifest.htdocs?
            for key, value of manifest.htdocs
                rules["htdocs.#{key}"] =
                    tags: ["client"]
                    factoryParams: key
                    factory: (key) ->
                        targets: path.join buildPath, path.basename(replaceExtension((lookup manifest, "htdocs.#{key}.html"), '.html'))
                        # NOTE: path for foreign feature dependencies is relative, need to resolve it by build the absolute before
                        dependencies: [
                            path.join(featurePath, lookup(manifest, "htdocs.#{key}.html"))
                            resolveFeatureRelativePaths lookup(manifest, "htdocs.#{key}.dependencies.templates"), projectRoot, featurePath
                        ]
                        actions: "$(JADEC) $< --pretty --obj {\\\"name\\\":\\\"#{manifest.name}\\\"} --out #{buildPath}"

        return rules

