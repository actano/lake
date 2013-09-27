JADE_TEMPLATES = ["views/markup.jade", "../testlmake-dep/views/page.jade"]

module.exports =

    name: "testlmake"
    version: "0.0.1"

    license: "MIT"
    description: "a feature description"
    keywords: []

    documentation: ["Readme.md"]

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
                    "views/markup.jade",
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
                    "../testlmake-dep"
                ]

            development:
                remote:
                    "visionmedia/mocha": "*"
                    "chaijs/chai": "*"

        scripts: ["client.coffee"]
        main: "client.coffee"
        styles: ["styles/testlmake.styl"]
        templates: ["views/list-entry-partial.jade"]


        tests:
            # A single test.html file is created from the specified template.
            # It contains script tags for
            # all files mentioned under 'scripts'
            # This generated HTML file is then loaded into a headless browser
            # (phantomjs) and the tests are executed with mocha.

            browser:
                html: "test/test.jade"
                dependencies: JADE_TEMPLATES

                assets:
                    styles:
                      ["build/components/visionmedia-mocha/mocha.css"]
                    scripts:
                      ["build/components/visionmedia-mocha/mocha.js",
                       "build/components/chaijs-chai/lib/chai.js",
                       "../../vendor/sinon-1.6.0.js",
                       "../../vendor/jquery-1.9.1.js"
                      ]
                scripts: [
                    "test/testlmake-browser.coffee"
                ]


    server:
        scripts: ["server.coffee"]
        mountPoint: "/testlmake"
        tests: [
            "test/testlmake-unit.coffee"
        ]

    database:
        designDocuments: []
        bucket: []

    integrationTests:
        mocha: [
            "test/testlmake-integration.coffee"
        ]
