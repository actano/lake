path = require 'path'
{resolveFeatureRelativePaths, replaceExtension, lookup, concatPaths} = require "../src/rulebook_helper"

module.exports =
    title: 'all'
    description: "building web application with NodeJS, Couchbase, Component, CoffeeScript, Jade, Eco, Stylus and Mocha, Chai, PhantomJS for testing"
    addRules: (lake, featurePath, manifest, rb) ->

        buildPath = path.join featurePath, lake.localBuildDirectory
        componentsPath = path.join buildPath, "components"
        styluesBuildPath = path.join buildPath, "stylus"
        documentationPath = path.join buildPath, "documentation"
        projectRoot = path.resolve "..", lake.lakeDirectory
        globalBuildPath = path.join lake.globalBuildDirectory, featurePath #  for client side targets
        runtimePath = path.join lake.localBuildDirectory, featurePath # directory for server side compile results
        coveragePath = path.join lake.coveragePath, featurePath # for coffee coverage
        uninstrumentedPath = path.join lake.uninstrumentedPath, featurePath

        rules =

            "coffee-client":
                condition: manifest.client?.scripts?
                tags: ["client", "feature"]
                factory: ->
                    targets: concatPaths manifest.client.scripts, {pre: buildPath}, (file) ->
                        replaceExtension file, '.js'
                    dependencies: concatPaths manifest.client.scripts, {pre: featurePath}
                    actions: "$(COFFEEC) -c $(COFFEE_FLAGS) --output #{buildPath} $^"

            "sylus":
                condition: manifest.client?.styles?
                tags: ["client", "feature"]
                factory: ->
                    targets: concatPaths manifest.client.styles, {pre: buildPath}, (file) ->
                        replaceExtension file, '.css'
                    dependencies: concatPaths manifest.client.styles, {pre: featurePath}
                    actions: [
                        "mkdir -p #{styluesBuildPath}"
                        "$(STYLUSC) $(STYLUS_FLAGS) --out #{styluesBuildPath} $^"
                    ]

            "component.json":
                condition: manifest.client?
                tags: ["client", "feature"]
                factory: ->
                    targets: path.join buildPath, "component.json"
                    dependencies: path.join featurePath, "Manifest.coffee"
                    actions: [
                        "mkdir -p #{buildPath}"
                        "$(COMPONENT_GENERATOR) $< $@"
                    ]

            "component-install":
                condition: manifest.client?
                tags: ["client", "feature"]
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
                tags: ["client", "feature"]
                factory: ->
                    targets: [path.join(featurePath, manifest.name) + ".js", path.join(featurePath, manifest.name) + ".css"]
                    dependencies: [
                        rb.getRuleById("component.json").targets
                        # NOTE: path for foreign components is relative, need to resolve it by build the absolute before
                        resolveFeatureRelativePaths manifest.client.dependencies.production.local, projectRoot, featurePath
                        rb.getRuleById("coffee-client").targets
                        rb.getRuleById("sylus").targets

                    ]
                    # NOTE: component-build don't use (makefile) dependencies paramter, it parse the component.json
                    actions: "cd #{buildPath} && $(COMPONENT_BUILD) $(COMPONENT_BUILD_FLAGS) --name #{manifest.name} -v -o ./"

            "local-components":
                condition: manifest.client?
                tags: ["feature"]
                factory: ->
                    targets: globalBuildPath
                    dependencies: rule.targets for rule in rb.getRulesByTag("client", true)
                    # TODO: use dependencies in the action, but without foreign features / only own created feature files
                    actions: [
                        "mkdir -p #{globalBuildPath}"
                        "cp -r #{buildPath}/* #{globalBuildPath}"
                        "touch #{globalBuildPath}"
                    ]


            "documentation":
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
                tags: ["feature"]
                factory: ->
                    targets: path.join featurePath, "couchview"
                    dependencies: concatPaths manifest.database.designDocuments, {pre: featurePath}
                    actions: [
                        "mkdir -p #{path.join buildPath, "_design"}"
                        concatPaths manifest.database.designDocuments, {}, (file) ->
                            [
                                "$(BIN)/jshint #{path.join featurePath, file}"
                                "$(COUCHVIEW_INSTALL) -s #{path.join featurePath, file}"
                                "touch #{path.join buildPath, file}"
                            ]
                    ]

            "server-scripts":
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
                factory: ->
                    targets: featurePath
                    dependencies: rule.targets for rule in rb.getRulesByTag("feature", true)

            "runtime":
                factory: ->
                    target: path.join featurePath, "install"
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
                condition: manifest.integrationTest?.mocha?
                tags: ["test"]
                factory: ->
                    targets: path.join featurePath ,'integration-test'
                    dependencies: rb.getRuleById("feature").targets
                    actions: concatPaths manifest.integrationTests.mocha, {pre: featurePath}, (testFile) ->
                        "$(MOCHA) -R $(MOCHA_REPORTER) --compilers coffee:coffee-script #{testFile}"


            "unit-test":
                condition: manifest.server?.tests?
                tags: ["test"]
                factory: ->
                    targets: path.join featurePath, "unit-test"
                    actions: concatPaths manifest.server.tests, {pre: featurePath}, (testFile) ->
                        "$(MOCHA) -R $(MOCHA_REPORTER) --compilers coffee:coffee-script #{testFile}"


            "test-all":
                factory: ->
                    targets: path.join featurePath, "test"
                    dependencies: rule.targets for rule in rb.getRulesByTag("test", true)

            "clean":
                factory: ->
                    targets: path.join featurePath, "clean"
                    actions: "rm -rf #{buildPath}"

        for jadeTemplate in manifest.client.templates
            rules["jade.template.#{jadeTemplate}"] =
                factoryParams: jadeTemplate
                factory: (jadeTemplate) ->
                    targets: path.join buildPath, replaceExtension(jadeTemplate, '.js')
                    dependencies: path.join featurePath, jadeTemplate
                    actions: [
                        "@mkdir -p #{path.join buildPath, "views"}"
                        "@echo \"module.exports=\" > $@"
                        "$(JADEC) --client --path $< < $< >> $@"
                    ]

        for key, value of manifest.htdocs
            rules["htdocs.#{key}"] =
                factoryParams: key
                factory: (key) ->
                    target: path.join buildPath, replaceExtension((lookup manifest, "htdocs.#{key}.html"), '.html')
                    # NOTE: path for foreign feature dependencies is relative, need to resolve it by build the absolute before
                    dependencies: [
                        resolveFeatureRelativePaths lookup(manifest, "htdocs.#{key}.dependencies.templates"), projectRoot, featurePath
                    ]
                    actions: "$(JADEC) $< --pretty --obj {\"name\":\"#{manifest.name}\"} --out #{buildPath}"

        return rules

