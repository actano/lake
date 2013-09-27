JADE_TEMPLATES = ["views/markup.jade", "../testlmake-trans-dep/views/page.jade"]

module.exports =

    name: "testlmake-dep"
    version: "0.0.1"

    license: "MIT"
    description: ""
    keywords: []

    htdocs:
        demo:
            html: "views/demo.jade"
            dependencies:
                templates: JADE_TEMPLATES
            images: []

        widget:
            html: "views/widget.jade"
            dependencies:
                templates: [
                    "views/markup.jade"
                    "../testlmake-dep/views/widget.jade"
                ]
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
                    "../testlmake-trans-dep"
                ]

            development:
                remote:
                    "visionmedia/mocha": "*"
                    "chaijs/chai": "*"

        scripts: ["client.coffee"]
        main: "client.coffee"
        styles: ["styles/testlmake-dep.styl"]
        templates: []




