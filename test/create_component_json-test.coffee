fs = require 'fs'
difflet = require('difflet')({indent: 4});
async = require 'async'
js2c = require "js2coffee"
{_} = require "underscore"
debug = require('debug')('component-generator.test')
{expect} = require "chai"

{findProjectRoot} = require "../src/file-locator"
manifestGenerator = require "../src/create_manifest"
componentGenerator = require "../src/create_component_json"

sourceComponent =
    name: "feature name"
    description: "description of a feature"
    version: "1.2.3"
    keywords: ["tnis", "is", "a", "test"]
    dependencies:
        "regular/subdom": "*"
        "component/dom": "*"
        "jkroso/dom-event": "*"
        "component/events": "*"
        "visionmedia/debug": "*"
        "karlbohlmark/jade-runtime": "*"
        "visionmedia/superagent": "*"
        "discore/closest": "*"
        "discore/siblings": "*"
        "discore/children": "*"
        "jkroso/position": "*"

    development:
        "visionmedia/mocha" : "*",
        "chaijs/chai" : "*",

    license: "MIT"
    paths: ["../../../build/local_components/lib"]
    local: ["styles", "bind-jade"]
    scripts: ["client.js", "views/popover.js"]
    main: "client.js"
    styles: ["styles/popover.css"]

sourceFilePrefix = "build"


describe "use a component.json and generate a manifest.coffee, then convert into a component.json", ->
    it "should be equals (the source component.json and generated component.json)", (done) ->
        async.waterfall [
            (cb) ->
                debug "generating manifest ..."
                manifestGenerator sourceComponent, null, (err, manifest) ->
                    if err? then return cb err

                    cb null, sourceComponent, manifest

            (componentObject, manifest, cb) ->
                debug "generateing component ..."
                manifest = js2c.build manifest

                fs.writeFile "tmp_manifest.coffee", manifest, {'flags': 'r'}, cb

            (cb) ->
                findProjectRoot cb

            (projectRoot, cb) ->
                if fs.existsSync 'build/tmp_component.json'
                    fs.unlinkSync 'build/tmp_component.json'
                if fs.existsSync 'build'
                    fs.rmdirSync 'build'
                fs.mkdirSync 'build'
                componentGenerator projectRoot, 'tmp_manifest.coffee', 'build/tmp_component.json'

                fs.readFile 'build/tmp_component.json', 'utf8', cb

            (generatedComponent, cb) ->
                generatedComponent = JSON.parse generatedComponent
                success = _(sourceComponent).isEqual generatedComponent

                if not success
                    diff = difflet.compare sourceComponent, generatedComponent
                    console.log diff
                else
                    fs.unlinkSync 'tmp_manifest.coffee'
                    fs.unlink 'build/tmp_component.json'
                    fs.rmdirSync 'build'

                cb null, success

        ], (err, result) ->
            if err? then return done err

            expect(result).to.be.ok
            done()

