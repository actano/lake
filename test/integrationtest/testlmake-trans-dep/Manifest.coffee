module.exports =

    name: "testlmake-trans-dep"
    version: "0.0.1"

    license: "MIT"
    description: ""
    keywords: []

    htdocs:
        demo:
            html: "views/demo.jade"
            dependencies:
                templates: ["views/page.jade"]
            images: []

        widget:
            html: "views/widget.jade"
            dependencies:
                templates: []
            images: []

    ###
    ##  Client-side stuff ends up in component.json
    ## and will be processed by component-build
    ###

    client:
        dependencies:
            production:
                remote:
                    "component/dom": "*"
                    "regular/subdom": "*"
                    "visionmedia/debug": "*"
                    "visionmedia/superagent": "*"

                local: [
                    "../bind-jade"
                ]

            development:
                remote:
                    "visionmedia/mocha": "*"
                    "chaijs/chai": "*"

        scripts: ["client.coffee" ,"trans_module.coffee"]
        main: "client.coffee"
        styles: ["styles/testlmake-trans-dep.styl"]
        templates: ["views/dummy-partial.jade"]






