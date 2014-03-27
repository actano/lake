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
    it 'merges a list of additonal scripts, styles and fonts', (done) ->
        parsedArgs = parseCommandline [
            'manifestPath'
            'componentPath'
            '--add-script', 'script1'
            '--add-script', 'script2'
            '--add-style', 'style1'
            '--add-style', 'style2'
            '--add-font', 'font1'
            '--add-font', 'font2'
        ]

        expect(parsedArgs).to.have.property 'add-script'
        expect(parsedArgs['add-script']).to.deep.equal ['script1', 'script2']

        expect(parsedArgs).to.have.property 'add-style'
        expect(parsedArgs['add-style']).to.deep.equal ['style1', 'style2']

        expect(parsedArgs).to.have.property 'add-font'
        expect(parsedArgs['add-font']).to.deep.equal ['font1', 'font2']

        done()

describe 'additional scripts, styles and fonts', ->
    it 'should appear in component.json', (done) ->
        
        manifest = """
            module.exports =
                name: 'myFeature'
                client:
                    scripts: ['scriptA.coffee', 'scriptB.coffee']
                    templates: ['views/templA.jade', 'views/templB.jade']
                    styles: ['styles/a.styl', 'styles/b.styl']
                    fonts: ['these', 'are', 'ignored']
                    
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
                        scripts: ['build/translations/de_DE.js', 'build/translations/en_US.js']
                        styles: ['build/extra/styles1.css', 'build/extra/styles2.css']
                        fonts: ['build/my.ttf', 'build/my.otf']

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
                expect(component.fonts).to.deep.equal [
                    'my.ttf'
                    'my.otf'
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
                
