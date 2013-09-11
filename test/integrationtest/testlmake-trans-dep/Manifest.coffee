module.exports =

    name: "testlmake-trans-dep"
    version: "0.0.1"

    license: "MIT"
    description: ""
    keywords: []

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
            files: [] # must be a file
        mountPoint: ""


    database:
        designDocuments: []
        bucket: []








