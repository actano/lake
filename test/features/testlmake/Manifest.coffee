JADE_TEMPLATES = ["views/markup.jade", "../testlmake-dep/views/page.jade"]
WIDGET_TEMPLATES = ["views/markup.jade", "../testlmake-dep/views/widget.jade"]

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
                templates: WIDGET_TEMPLATES
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
                      ["__NODE_MODULES__/mocha/mocha.css"]
                    scripts:
                      ["__NODE_MODULES__/mocha/mocha.js",
                       "__NODE_MODULES__/chai/chai.js",
                       "__PROJECT_ROOT__/vendor/sinon-1.7.3.js",
                       "__PROJECT_ROOT__/vendor/jquery-1.10.2.js"
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

    integrationTests:
        mocha: [
            "test/testlmake-integration.coffee"
        ]
