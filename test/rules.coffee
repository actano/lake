path = require 'path'
{resolveFeatureRelativePaths, replaceExtension, lookup, concatPaths} = require "../src/rulebook_helper"

module.exports =
    title: 'all'
    description: "building web application with NodeJS, Couchbase, Component, CoffeeScript, Jade, Eco, Stylus and Mocha, Chai, PhantomJS for testing"
    addRules: (lake, featurePath, manifest, rb) ->

        buildPath = path.join featurePath, lake.buildDir
        componentsPath = path.join buildPath, "components"
        styluesBuildPath = path.join buildPath, "stylus"
        projectRoot = path.resolve "..", lake.lakeDir
        localComponentFeature = path.join lake.localComponents, featurePath

        rules =

            "coffee-client":
                condition: manifest.client?.scripts?
                tags: ["client"]
                factory: ->
                    targets: concatPaths manifest.client.scripts, {pre: buildPath}, (path) ->
                        replaceExtension path, '.js'
                    dependencies: concatPaths manifest.client.scripts, {pre: featurePath}
                    actions: "$(COFFEEC) -c $(COFFEE_FLAGS) --output #{buildPath} $^"

            "sylus":
                condition: manifest.client?.styles?
                tags: ["client"]
                factory: ->
                    targets: concatPaths manifest.client.styles, {pre: buildPath}, (path) ->
                        replaceExtension path, '.css'
                    dependencies: concatPaths manifest.client.styles, {pre: featurePath}
                    actions: [
                        "mkdir -p #{styluesBuildPath}"
                        "$(STYLUSC) $(STYLUS_FLAGS) --out #{styluesBuildPath} $^"
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
                factory: ->
                    targets: localComponentFeature
                    dependencies: rule.targets for rule in rb.getRulesByTag("client", true)
                    # TODO: use dependencies, but without foreign features / only own feature created files
                    actions: [
                        "mkdir -p #{localComponentFeature}"
                        "cp -r #{buildPath}/* #{localComponentFeature}"
                        "touch #{localComponentFeature}"
                    ]


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

