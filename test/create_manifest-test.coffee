difflet = require('difflet')({indent: 4});
async = require 'async'
{_} = require "underscore"
debug = require('debug')('manifest-generator.test')
{expect} = require "chai"
coffee = require 'coffee-script'
fs = require 'fs'

{findProjectRoot} = require "../src/file-locator"
manifestGenerator = require "../src/create_manifest"
componentGenerator = require "../src/create_component_json"

sourceManifest = """
module.exports =
    name: "feature name"
    version: "2.0.1"
    license: "MIT"
    description: "feature description"
    keywords: ["key", "word"]
    htdocs:
        page:
            html: []
            images: []

        widget:
            html: []
            images: []

    client:
        dependencies:
            production:
                remote:
                    "regular/subdom": "*"
                    "component/dom": "*"
                    "component/events": "*"
                    "visionmedia/debug": "*"
                    "karlbohlmark/jade-runtime": "*"
                    "visionmedia/superagent": "*"
                    "discore/closest": "*"
                    "regular/siblings": "*"
                    "discore/children": "*"
                    "jkroso/position": "*"
                    "matthewmueller/debounce": "*"
                    "jkroso/dom-event": "*"
                    "component/underscore": "*"

                local: [
                    "../styles",
                    "../bind-jade",
                    "../progressive-list",
                    "../object-selector",
                    "../popover"
                ]

            development:
                remote:
                    "visionmedia/mocha" : "*",
                    "chaijs/chai" : "*",

        scripts: ["client.coffee"]
        main: "client.coffee"
        styles: ["styles/working-set.styl"]
        templates: ["views/list-entry-partial.jade"]

        tests:
            browser:
                template: ""
                preequisits:
                    "visionmedia/mocha": ["mocha.js", "mocha.css"]
                    "chaijs/chai": ["chai.js"]

                scripts: []

            mocha: []

    server:
        mountPoint: ""
        tests:
            integration: []
            unit: []

    database:
        designDocuments: []
"""

describe "use a component.json and generate a manifest.coffee, then convert into a component.json", ->
    it "should be equals (the source component.json and generated component.json)", (done) ->
        async.waterfall [

            (cb) ->
                if fs.existsSync 'tmp_manifest.coffee'
                    fs.unlinkSync 'tmp_manifest.coffee'
                if fs.existsSync 'tmp_component.json'
                    fs.unlinkSync 'tmp_component.json'

                fs.writeFile "tmp_manifest.coffee", sourceManifest, {'flags': 'r'}, cb

            (cb) ->
                findProjectRoot cb

            (projectRoot, cb) ->


                debug "generateing component.json  ..."
                componentGenerator projectRoot, 'tmp_manifest.coffee', 'tmp_component.json'

                fs.readFile 'tmp_component.json', 'utf8', cb

            (generatedComponent, cb) ->
                debug "parsing component.json ..."
                generatedComponent = JSON.parse generatedComponent

                cb null, generatedComponent

            (component, cb) ->
                debug "generateing manifest ..."

                manifestGenerator component, null, (err, generatedManifest) ->
                    if err? then return cb err

                    cb null, sourceManifest, generatedManifest

            (sourceManifest, generatedManifest, cb) ->
                # sourceManifest is a string containing coffee source code
                # generatedManifest is a string containing javascript source code

                sourceManifest = coffee.eval sourceManifest
                generatedManifest = eval generatedManifest


                success = _(sourceManifest).isEqual generatedManifest
                if not success
                    diff = difflet.compare sourceManifest, generatedManifest

                    console.log diff

                cb null, success

        ], (err, result) ->
            if err? then return done err

            if result
                if fs.existsSync 'tmp_manifest.coffee'
                    fs.unlinkSync 'tmp_manifest.coffee'
                if fs.existsSync 'tmp_component.json'
                    fs.unlinkSync 'tmp_component.json'

            expect(result).to.be.ok



            done()

