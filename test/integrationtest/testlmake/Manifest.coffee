JADE_TEMPLATES = ["views/markup.jade", "../testlmake-dep/views/page.jade"]

module.exports =

    name: "testlmake"
    version: "0.0.1"

    license: "MIT"
    description: ""
    keywords: []

    documentation: ["Readme.md"]
    library: true

    htdocs:
        page:
            html: ["views/demo.jade"]
            dependencies:
                templates: JADE_TEMPLATES
            images: []

        widget:
            html: ["views/widget.jade"]
            dependencies:
                templates: ["views/markup.jade", "../testlmake-dep/views/widget.jade"]
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
        views:
            dirs: ["views"]

        tests:
            # A single test.html file is created from the specified template.
            # It contains script tags for
            # all files mentioned under 'scripts'
            # This generated HTML file is then loaded into a headless browser
            # (phantomjs) and the tests are executed with mocha.

            browser:
                html: "test/test.jade"
                prerequisits: JADE_TEMPLATES

                scripts: [
                    "test/testlmake-browser.coffee"
                ]

            mocha: [
                "test/testlmake-phantom.coffee"
            ]

    server:
        scripts:
            files: ["server.coffee"] # must be a file
        mountPoint: "/testlmake"
        tests:
            integration: [
                "test/testlmake-integration.coffee"
            ]
            unit: [
                "test/testlmake-unit.coffee"
            ]

    database:
        designDocuments: []
        bucket: []







