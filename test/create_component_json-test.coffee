# Std library
fs = require 'fs'

# Third party
difflet = require('difflet')({indent: 4})
async = require 'async'
js2c = require "js2coffee"
{_} = require "underscore"
debug = require('debug')('component-generator.test')
{expect} = require "chai"

# Local dep
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

describe.skip "use a component.json and generate a manifest.coffee, " +
        "then convert into a component.json", ->
    it "should be equals (the source component.json and " +
            "generated component.json)", (done) ->
        async.waterfall [
            (cb) ->
                debug "generating manifest ..."
                manifestGenerator sourceComponent, null, (err, manifest) ->
                    if err? then return cb err
                    cb null, sourceComponent, manifest

            (componentObject, manifest, cb) ->
                debug "generateing component ..."
                manifest = js2c.build manifest
                fs.writeFile "tmp_manifest.coffee", manifest, {flags: 'r'}, cb

            (cb) ->
                findProjectRoot cb

            (projectRoot, cb) ->
                if fs.existsSync 'build/tmp_component.json'
                    fs.unlinkSync 'build/tmp_component.json'
                if fs.existsSync 'build'
                    fs.rmdirSync 'build'
                fs.mkdirSync 'build'
                componentGenerator projectRoot,
                    'tmp_manifest.coffee', 'build/tmp_component.json'

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

describe 'translations in the Manifest', ->
    it 'should become scripts in the component.json', (done) ->
        
        manifest = """
            module.exports =
                name: 'myFeature'
                client:
                    scripts: ['scriptA.coffee', 'scriptB.coffee']
                    templates: ['views/templA.jade', 'views/templB.jade']
                    translations:
                        de_DE: 'translations/de_DE.coffee'
                        en_US: 'translations/en_US.coffee'
        """
        manifestPath = "tmp_manifest.coffee"
        componentPath = "build/tmp_component.json"

        async.waterfall [
            (cb) ->
                fs.writeFile manifestPath, manifest, {flags: 'r'}, cb

            (cb) ->
                findProjectRoot cb

            (projectRoot, cb) ->
                componentGenerator projectRoot, manifestPath, componentPath
                component = JSON.parse fs.readFileSync componentPath, 'utf8'
                expect(component.scripts).to.deep.equal [
                    'scriptA.js'
                    'scriptB.js'
                    'views/templA.js'
                    'views/templB.js'
                    'translations/de_DE.js'
                    'translations/en_US.js'
                ]
                cb null
        ], (err) ->
            if err?
                return done err
            if fs.existsSync manifestPath
                    fs.unlinkSync manifestPath
            if fs.existsSync componentPath
                    fs.unlinkSync componentPath
            
            done()
                
