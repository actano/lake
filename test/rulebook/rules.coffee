module.exports =
    addRules: (lake, featurePath, manifest, rb) ->
        rules =
            "rule1":
                tags: ["foo", "foobaz"]
                factory: ->
                    targets: rb.getRulesByTag("bar")["rule3"].targets
                    dependencies: rb.getRuleById("rule3").dependencies
                    actions: rb.getRulesByTag("bar", true)[0].targets

            "rule2":
                condition: manifest?.client?
                factory: ->
                    targets: "foo" + "rule2"
                    dependencies: manifest.client.main
                    actions: manifest.license

            "rule2false":
                condition: manifest?.client?.foo?
                factory: ->
                    targets: "foo" + "rule2"
                    dependencies: manifest.client.foo.bar
                    actions: manifest.description

            "rule3":
                tags: ["foobaz", "bar"]
                factory: ->
                    targets:  "foo" + "rule3"
                    dependencies: rb.getRuleById("rule2").targets
                    actions: "foobaz"


        return rules
