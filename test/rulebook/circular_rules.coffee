module.exports.addRules = (lake, featurePath, manifest, ruleBook) ->
    rb = ruleBook
    rb.addRule "rule1", ["foo", "foobaz"], ->
        targets: "rule1"+"clean"
        dependencies: rb.getRuleById("rule3").dependencies
        actions: rb.getRulesByTag("bar")[0].targets

    if manifest?.client?
        rb.addRule "rule2", [], ->
            targets: rb.getRuleById("rule2false").dependencies
            dependencies: manifest.client.main
            actions: manifest.license

    rb.addRule "rule2false", [], ->
        targets: "foo" + "rule2"
        dependencies: rb.getRuleById("rule3").targets
        actions: manifest.description

    rb.addRule "rule3", ["foobaz", "bar"], ->
        targets: "foo" + "rule3"
        dependencies: rb.getRuleById("rule2").targets
        actions: "foobaz"
