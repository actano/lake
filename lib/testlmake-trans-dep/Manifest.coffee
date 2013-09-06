module.exports =

    name: "testlmake-trans-dep"
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
                templates: ["views/page.jade"]
            images: []

        widget:
            html: ["views/widget.jade"]
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

        tests:
            # A single test.html file is created from the specified template.
            # It contains script tags for
            # all files mentioned under 'scripts'
            # This generated HTML file is then loaded into a headless browser
            # (phantomjs) and the tests are executed with mocha.

            browser:
                template: "test/test.jade"
                prerequisits: ["views/markup.jade", "views/page.jade"]

                scripts: [
                    "test/testlmake-trans-dep-browser.coffee"
                ]

            mocha: [
                "test/testlmake-trans-dep-phantom.coffee"
            ]

    server:
        scripts:
            files: ["server.coffee", "index.coffee"] # must be a file
        mountPoint: "/testlmake-trans-dep"
        tests:
            integration: [
                "test/testlmake-trans-dep-integration.coffee"
            ]
            unit: [
                "test/testlmake-trans-dep-unit.coffee"
            ]

    database:
        designDocuments: []
        bucket: []







