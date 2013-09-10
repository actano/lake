JADE_TEMPLATES = ["views/markup.jade", "../testlmake-trans-dep/views/page.jade"]

module.exports =

    name: "testlmake-dep"
    version: "0.0.1"

    license: "MIT"
    description: ""
    keywords: []

    documentation: ["Readme.md", "History.md"]
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
                templates: ["views/markup", "../../testlmake-dep/views/widget"]
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

        tests:
            # A single test.html file is created from the specified template.
            # It contains script tags for
            # all files mentioned under 'scripts'
            # This generated HTML file is then loaded into a headless browser
            # (phantomjs) and the tests are executed with mocha.

            browser:
                template: "test/test.jade"
                prerequisits: JADE_TEMPLATES

                scripts: [
                    "test/testlmake-dep-browser.coffee"
                ]

            mocha: [
                "test/testlmake-dep-phantom.coffee"
            ]

    server:
        scripts:
            files: ["server.coffee", "index.coffee"] # must be a file
        mountPoint: "/testlmake-dep"
        tests:
            integration: [
                "test/testlmake-dep-integration.coffee"
            ]
            unit: [
                "test/testlmake-dep-unit.coffee"
            ]

    database:
        designDocuments: []
        bucket: []







