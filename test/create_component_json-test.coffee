# Std library
fs = require 'fs'

# Third party
async = require 'async'
{_} = require "underscore"
debug = require('debug')('component-generator.test')
{expect} = require "chai"
{inspect} = require 'util'

# Local dep
{findProjectRoot} = require "../src/file-locator"
{generateComponent, parseCommandline} = require "../src/create_component_json"

describe 'command line options', ->
    it 'merges a list of additonal scripts and styles', (done) ->
        parsedArgs = parseCommandline [
            'manifestPath'
            'componentPath'
            '--add-script', 'script1'
            '--add-script', 'script2'
            '--add-style', 'style1'
            '--add-style', 'style2'
        ]

        expect(parsedArgs).to.have.property 'add-script'
        expect(parsedArgs['add-script']).to.deep.equal ['script1', 'script2']

        expect(parsedArgs).to.have.property 'add-style'
        expect(parsedArgs['add-style']).to.deep.equal ['style1', 'style2']
        done()

describe 'additional scripts and styles', ->
    it 'should appear in component.json', (done) ->
        
        manifest = """
            module.exports =
                name: 'myFeature'
                client:
                    scripts: ['scriptA.coffee', 'scriptB.coffee']
                    templates: ['views/templA.jade', 'views/templB.jade']
                    styles: ['styles/a.styl', 'styles/b.styl']
                    
        """
        manifestPath = "tmp_manifest.coffee"
        componentPath = "build/tmp_component.json"

        async.waterfall [
            (cb) ->
                fs.writeFile manifestPath, manifest, {flags: 'r'}, cb

            (cb) ->
                findProjectRoot cb

            (projectRoot, cb) ->
                generateComponent projectRoot, manifestPath, componentPath,
                    additionalFiles:
                        scripts: ['translations/de_DE.js', 'translations/en_US.js']
                        styles: ['extra/styles1.css', 'extra/styles2.css']
                component = JSON.parse fs.readFileSync componentPath, 'utf8'

                expect(component.scripts).to.deep.equal [
                    'scriptA.js'
                    'scriptB.js'
                    'translations/de_DE.js'
                    'translations/en_US.js'
                    'views/templA.js'
                    'views/templB.js'
                ]
                expect(component.styles).to.deep.equal [
                    'styles/a.css'
                    'styles/b.css'
                    'extra/styles1.css'
                    'extra/styles2.css'
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
                
