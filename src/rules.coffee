path = require 'path'

module.exports =
    title: 'all'
    description: "actano-rplanx-stack"
    addRules: (lake, featurePath, manifest, rb) ->
        #buildPath = lake.getBuildPath featurePath
        buildPath = path.join lake.buildDir, featurePath

        rules =
            "rule1":
                tags: ["foo", "foobaz"]
                factory: ->
                    targets: path.join "rule1", "clean"
                    dependencies: rb.getRuleById("rule3").dependencies
                    actions: rb.getRulesByTag("bar", true)[0].targets

            "rule2":
                condition: manifest.client?
                factory: ->
                    targets: path.join "foo", "rule2"
                    dependencies: manifest.client.main
                    actions: manifest.license

            "rule2false":
                condition: manifest?.client?.foo?
                factory: ->
                    targets: path.join "foo", "rule2"
                    dependencies: manifest.client.foo.bar
                    actions: manifest.description

            "rule3":
                tags: ["foobaz", "bar"]
                factory: ->
                    targets: path.join "foo", "rule3"
                    dependencies: rb.getRuleById("rule2").targets
                    actions: "foobaz"


        return rules
