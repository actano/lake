path = require 'path'



module.exports =
    title: 'all'
    description: "actano-rplanx-stack"
    addRules: (lake, featurePath, manifest, rb) ->
        {replaceExtension, lookup, prefixPaths} = require lake.helper
        buildPath = path.join lake.buildDir, featurePath

        rules =
            "ruleId":
                condition: manifest.client?
                factory: ->
                    targets: "dynamic" + "target"
                    dependencies: manifest.client.main
                    actions: manifest.license

        return rules
