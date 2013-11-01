#!/usr/bin/env coffee

# Std library
fs = require 'fs'
path = require 'path'
{inspect} = require 'util'

# Third party
{Sink} = require 'pipette'
coffee = require 'coffee-script'
{_} = require 'underscore'
async = require 'async'
js2c = require 'js2coffee'
debug = require('debug')('manifest-generator')

# Local dep
Glob = require './globber'


EXTENSION_MAPPING =
    '.js' : '.coffee'
    '.css': '.styl'

usage = """
    USAGE: #{path.basename process.argv[1]} < component.json > Manifest.coffee

    reads component.json from stdin and writes Manifest to stdout.
"""

if process.argv[2] is '-h'
    console.log usage

# '.' should be lib/feature directory
directoryScanner = (patterns, options, cb) ->
    debug 'start directoryScanner ...'
    keyValuePairs = _(patterns).pairs()

    async.map keyValuePairs, ([key, globPattern], cb) ->
        globber = new Glob globPattern, 'build/', options
        fileList = []
        globber.on 'match', (filePath) ->
            fileList.push filePath
        globber.on 'end', (err) ->
            if err? then return cb err
            cb null, [key, fileList]
    , (err, result) ->
        if err? then return cb err
        debug 'done file scan'
        cb null, _(result).object()



convertFileType = (filenames, ext) ->
    if not filenames? then throw new Error 'convertFileType expects string ' +
        "or array instead of #{filenames}"
    if filenames is '' then return ''

    convertExtension = (filename) ->
        oldExtension = path.extname filename
        newExtension = ext or EXTENSION_MAPPING[oldExtension]
        if newExtension is 'undefined'
            throw Error "file extension isn't registered for file: #{filename}"

        filename.replace new RegExp("#{oldExtension}$"), newExtension

    if typeof filenames is 'string'
        return convertExtension filenames
    else
        for filename in filenames
            convertExtension filename

removePathPrefix = (origin, toRemoveFromPath) ->
    dirArray = origin.split path.sep
    return _(dirArray).without(toRemoveFromPath).join path.sep

hasPrefix = (filePath, prefix) ->
    return (filePath.indexOf prefix) is 0


generateManifest = (component, cwd = '.', cb) ->

    convertFilePaths = (component) ->

        # remove 'build/' directory for generated scripts and views/templates
        scripts = _(component.scripts or []).map (path) ->
            return removePathPrefix path, 'build'

        debug "scripts: #{scripts}"

        styles = _(component.styles or []).map (style) ->
            return removePathPrefix style, 'build'

        debug "styles: #{styles}"

        # don't remove templates from scripts in this step,
        # because the 'difference' method would not work then
        templates = _(scripts).filter (path) ->
            hasPrefix path, 'views/'

        debug "templates: #{templates}"

        # seperate scripts from templates
        scripts = _(scripts).difference templates

        # convert filenames, do not use 'auto mapping' for templates,
        # because it's not unique
        # .js and .jade both is converted into .coffee,
        # reverse method is not possible without directory
        scripts = convertFileType scripts
        styles = convertFileType styles
        templates = convertFileType templates, '.jade'

        localDependencies = _(component.local).map (localpath) ->
            # check if the component will be saved into '.' or build/
            cwdForLocals = '..'
            if cwd isnt '.'
                cwdForLocals = path.join cwdForLocals, '..'

            return path.join(cwdForLocals, (path.basename localpath))

        return {
            scripts
            templates
            styles
            localDependencies
        }

    debug 'generation of manifest started with cwd: '+cwd
    async.waterfall [
        (cb) ->
            debug 'scan for files ...'
            directoryScanner {
                designDocuments: ['_design/*.js']
                unitTests: ['test/*-test.coffee']
                browserTests: ['test/*-btest.coffee']
                integrationTests: ['test/*-itest.coffee']
                mochaTests: ['test/*-ptest.coffee']
                all: ['test/*.coffee']
            }, {cwd}
            , (err, files) ->
                if err? then return cb err
                debug 'done'
                debug "globbed files: #{files.all}"
                cb null, component, files



        (component, globbedFiles, cb) ->
            convertedPaths = convertFilePaths(component)
            debug 'file paths converted'
            # skip first characters 'build/'
            # use path.basename, which returns the last piece of a path string
            mainFile = if component.main
                convertFileType(path.basename component.main)
            else
                ''

            checkExistingFile = (filePath) ->
                # if this script was not called standalone,
                # need to check file with given cwd
                absolutePath = path.join cwd, filePath
                debug "check existing file #{absolutePath}"
                return if fs.existsSync(absolutePath) then filePath else null



            filterExistingFiles = (fileList) ->
                result = _(fileList).map (filePath) ->
                    checkExistingFile filePath
                _(result).compact() # this removes nulls from the result set

            lookup = (key, defaultValue) ->
                #debug "lookup for key #{key}"
                context = {}
                _(context).extend component, convertedPaths, globbedFiles,
                    globbedFiles, {mainFile}
                if key.indexOf('.') is -1
                    value = context[key] ? defaultValue
                    value = "'#{value}'" if typeof value is 'string'
                    return value
                else
                    throw new Error('nested key in component.json is illegal')

            lookupArray = (key) -> inspect lookup key, []
            lookupObject = (key) -> inspect lookup key, {}

            htmlBaseName = 'demo'


            differenceElements = globbedFiles.unitTests.concat(
                globbedFiles.browserTests
                globbedFiles.integrationTests
                globbedFiles.mochaTests
            )
            notAssigned = _(globbedFiles.all).difference differenceElements

            if notAssigned.length > 0
                notAssignedTestFilesMessage = ("// #{test}" for test in notAssigned).join '\n'
                messageHeader = [
                    '// WARNING'
                    '//'
                    '// Diese Dateien konnten nicht zugeordnet werden'
                    '// Bitte per Hand nachplegen!'
                    '//'
                ]
                notAssignedTestFilesMessage = (messageHeader.join '\n') + '\n' + notAssignedTestFilesMessage

            printBrowserTemplate = ->
                if checkExistingFile 'test/test.jade'
                    return '"test/test.jade"'
                else
                    return '""'

            debug 'write manifest template'

            manifest = """
            module.exports = {

                #{if notAssignedTestFilesMessage? then '//##' else ''}
                #{if notAssignedTestFilesMessage? then notAssignedTestFilesMessage else ''}
                #{if notAssignedTestFilesMessage? then '//##\n' else ''}

                /* the name of the feature */
                name: #{lookup 'name', "GIVE ME A NAME!"},
                version: #{lookup 'version', "0.0.1"}, // the feature's version"
                license: #{lookup 'licence',  "MIT"},
                description: #{lookup 'description', ""},
                keywords: #{lookupArray 'keywords'},
                htdocs: {
                    page: {
                        html: #{inspect(filterExistingFiles ["views/"+htmlBaseName+".jade"])},
                        images: []
                    },
                    widget: {
                        html: #{inspect(filterExistingFiles ["views/widget.jade"])},
                        images: []
                    }
                },
                //##
                // Client-side stuff ends up in component.json
                // and will be processed by component-build
                //##


                client: {
                    dependencies: {
                        production: {
                            remote: #{lookupObject 'dependencies'},
                            local: #{lookupArray 'localDependencies', []}
                        },
                        development: {
                            remote: {
                                "visionmedia/mocha": "*",
                                "chaijs/chai": "*"
                            }
                        }
                    },

                    scripts: #{lookupArray 'scripts'},
                    main: #{lookup 'mainFile', null},
                    styles: #{lookupArray 'styles'},
                    templates: #{lookupArray 'templates'},

                    //##
                    // A single test.html file is created from the specified template.
                    // It contains script tags for
                    // all files mentioned under 'scripts'
                    // This generated HTML file is then loaded into a headless browser
                    // (phantomjs) and the tests are executed with mocha.
                    //##
                    tests: {
                        browser: {
                            template: #{printBrowserTemplate() },
                            preequisits: {
                                "visionmedia/mocha": ["mocha.js", "mocha.css"],
                                "chaijs/chai": ["chai.js"]
                            },
                            scripts: #{lookupArray 'browserTests'}
                        },

                        mocha: #{lookupArray 'mochaTests'}
                    }
                },

                server: {
                    mountPoint: "#{if checkExistingFile 'server.coffee' then '/'+component.name else ''}",
                    tests: {
                        integration: #{lookupArray 'integrationTests'},
                        unit: #{lookupArray 'unitTests'}
                    }
                },
                database: {
                    designDocuments: #{lookupArray 'designDocuments'}
                }
            };
            """

            ###
            todo: the result of the exported function is not coffee
            its only javascript
            need to convert it with js2coffee here
            run tests when refactoring it!
            ###

            cb null, manifest
    ], cb

module.exports = generateManifest


if require.main is module
    stdin = new Sink(process.stdin)

    stdin.on 'data', (component) ->
        component = JSON.parse component.toString()
        generateManifest component, null, (err, manifest) ->
            if err?
                console.error "generation of manifest failed: #{err.message}"
                process.exit 1
            debug 'generateManifest done'
            manifest = js2c.build(manifest, {pretty_arrays:true, indent:true})
            debug 'done'
            process.stdout.write manifest

    stdin.on 'error', (err) ->
        console.error 'error reading form stdin', err
        process.exit 2

    process.stdin.resume()