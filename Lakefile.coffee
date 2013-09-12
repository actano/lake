JADE_BASE_TEMPLATES = ["../views/markup.jade","../views/page.jade"] 


module.exports =

    # generell sollte man auch darüber nachdenken, ob bei dateiabhängigkeiten
    # wahlweise ein "files" oder ein "dirs" key verwendet wird bzw. beides
    
    name: "testfeature"
    version: "0.0.1"

    license: "MIT"
    description: "a testfeature description"
    keywords: []

    documentation: ["Readme.md", "History.md"]
    
    htdocs:
        index:
            html: ["views/index.jade"]
            prerequisits: JADE_BASE_TEMPLATES
            images: []

        demo: 
            html: ["views/demo.jade"]
            prerequisits: JADE_BASE_TEMPLATES
            images: []

        widget:
            html: ["views/widget.jade"]
            prerequisits:
                ["views/markup.jade",
                 "../views/widget.jade"]
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
                    "../styles"
                    "../bind-jade"
                ]

            development:
                remote:
                    "visionmedia/mocha": "*"
                    "chaijs/chai": "*"

        scripts: ["client.coffee"]
        main: "client.coffee"
        styles: ["styles/testfeature.styl"]
        templates: ["views/list-partial.jade"]

        tests:
            # A single test.html file is created from the specified template.
            # It contains script tags for
            # all files mentioned under 'scripts'
            # This generated HTML file is then loaded into a headless browser
            # (phantomjs) and the tests are executed with mocha.

            browser:
                html: "test/test.jade"

                assets: 
                    styles:
                      ["build/components/visionmedia-mocha/mocha.css"]
                    scripts:
                      ["build/components/visionmedia-mocha/mocha.js",
                       "build/components/chaijs-chai/lib/chai.js",
                       "../../vendor/sinon-1.6.0.js",
                       "../../vendor/jquery-1.9.1.js"
                      ]
                prerequisits: JADE_BASE_TEMPLATES
                scripts: [
                    "test/testfeature-browser.coffee"
                ]


    # alle serverseitigen scripts werden hier zusammengefasst

    server:
        scripts: ["server.coffee", "index.coffee"]
        mountPoint: "/testfeature"
        tests: [
                "test/testfeature-unit.coffee"
            ]

    database:
        designDocuments: []
        bucket: []

    integrationTests:   
        mocha:
            ["test/testfeature-integration.coffee",
             "test/testfeature-phantom.coffee"]
