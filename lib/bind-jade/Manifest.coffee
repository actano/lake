module.exports =
    
    # the name of the feature 
    name: "bind-jade"
    version: "0.0.1" # the feature's version"
    license: "MIT"
    description: "exports a jade'd template file"
    keywords: []
    documentation: ["Readme.md","History.md"]
    library: true

    ###
    # Client-side stuff ends up in component.json
    # and will be processed by component-build
    ###
    client:
        dependencies:
            production:
                remote:
                    "karlbohlmark/jade-runtime": "*"

                local: []

            development:
                remote:
                    "visionmedia/mocha": "*"
                    "chaijs/chai": "*"

        scripts: ["client.coffee"]
        main: "client.coffee"
        styles: []
        templates: []

