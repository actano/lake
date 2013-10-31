module.exports.addRules = (lake, featurePath, manifest, ruleBook) ->
    rb = ruleBook
    rb.addRule "rule1", ["foo", "foobaz"], ->
        targets: rb.getRulesByTag("bar", false)["rule3"].targets
        dependencies: rb.getRuleById("rule3").dependencies
        actions: rb.getRulesByTag("bar")[0].targets

    if manifest?.client?
        rb.addRule "rule2", [], ->
            targets: "foo" + "rule2"
            dependencies: manifest.client.main
            actions: manifest.license

        if manifest.client.foo?
            rb.addRule "rule2false", [], ->
                targets: "foo" + "rule2"
                dependencies: manifest.client.foo.bar
                actions: manifest.description

        rb.addRule "rule3", ["foobaz", "bar"], ->
            targets:  "foo" + "rule3"
            dependencies: rb.getRuleById("rule2").targets
            actions: "foobaz"
