#!/usr/bin/env coffee

# Std library
fs = require 'fs'
path = require 'path'
{inspect} = require 'util'

# Third party
async = require 'async'
coffee = require 'coffee-script'
debug = require('debug') 'create-component.json'
nopt = require 'nopt'
{_} = require 'underscore'

# Local dep
{findProjectRoot} = require './file-locator'

debug 'require done'

EXTENSION_MAPPING =
    '.coffee': '.js'
    '.styl': '.css'
    '.jade': '.js'


convertFileType = (filenames) ->
    unless filenames?
        throw new Error "convertFileType expects string or array instead " +
            "of #{filenames}"
    if not filenames.length? then return ''

    convertExtension = (filename) ->
        oldExtension = path.extname filename
        if oldExtension.match /.js$/
            return filename
        else
            newExtension = EXTENSION_MAPPING[oldExtension]
            filename.replace new RegExp("#{oldExtension}$"), newExtension

    if typeof filenames is 'string'
        return convertExtension filenames
    else
        convertExtension filename for filename in filenames


processPaths = (manifest,
    projectRoot,
    manifestPath,
    componentPath,
    sourceFilePrefix,
    options) ->

    addPrefix = (localpath) ->
        return path.join sourceFilePrefix, localpath

    keyValuePairs = ['scripts', 'templates', 'styles', 'fonts'].map (key) ->
        files = []
        if key isnt 'fonts'
            files = convertFileType(manifest.client?[key] or [])
            files = _(files).map addPrefix

        if options.additionalFiles?
            additionalFiles = options.additionalFiles[key]
            if additionalFiles?
                for f in additionalFiles
                    f = path.relative path.dirname(componentPath), f
                    files.push f

        return [key, files]

    # if manifest.client?.translations?
    #     translations = _(convertFileType(_(manifest.client.translations).values())).map addPrefix
    #     keyValuePairs.push ['translations', translations]

    processedPaths = _(keyValuePairs).object()

    if manifest.client?.dependencies?.production?.local?

        localProdDependencies = manifest
            .client
            .dependencies
            .production
            .local
            
        processedPaths.localFeatures =
            _(localProdDependencies).map (localpath) ->
                return path.basename localpath

        processedPaths.localPaths =
            _.uniq _(localProdDependencies).map (localpath) ->
                absoluteManifestPath = path.dirname path.resolve manifestPath
                absoluteComponentPath = path.dirname path.resolve componentPath

                debug "Manifest is in #{absoluteManifestPath}"
                debug "component.json will be in #{absoluteComponentPath}"

                absolutePath = path.join absoluteManifestPath, localpath
                debug 'processing path of local dependency at #{absolutePath}'
                absolutePath = path.dirname absolutePath

                relativeToProjectRoot = path.relative projectRoot, absolutePath
                # in component.json we will be referencing the tree in
                # build/local_components because it reflects the structure that
                # component build expects.
                absolutePath = path.join projectRoot,
                    'build',
                    'local_components',
                    relativeToProjectRoot

                #relative to component.json
                path.relative absoluteComponentPath, absolutePath

        processedPaths.main = if manifest.client?.main?.length
            convertFileType path.join(sourceFilePrefix, manifest.client.main)
    else
        ''

    return processedPaths


generateComponent = (projectRoot, manifestPath, componentPath, options = {}) ->
    debug "creating #{componentPath} from #{manifestPath}"
    debug "project root is #{projectRoot}"

    ###
    
    In a scenario like this:
    
    foo/
        component.json
            {
                scripts: [
                    'bar/client.js'
                ]
            }
        bar/
            client.js
    
    foo is componentPath, bar is the sourceFilePrefix
    
    In the following scenario, sourceFilePrefix is '.'
    
    foo/
        component.json
            {
                scripts: [
                    './client.js'
                ]
            }
        client.js
    
    ###
    {sourceFilePrefix} = options
    sourceFilePrefix ?= '.'

    manifest = require path.resolve manifestPath

    processedPaths = processPaths manifest,
        projectRoot,
        manifestPath,
        componentPath,
        sourceFilePrefix,
        options

    component =
        name: manifest.name or 'GIVE ME A NAME!'
        description: manifest.description or ''
        version: manifest.version or '0.0.1'
        license: manifest.license or 'MIT'
        keywords: manifest.keywords or []
        dependencies: manifest.client?.dependencies?.production?.remote or {}
        local: processedPaths.localFeatures or []
        paths: processedPaths.localPaths or []
        development: manifest.client?.dependencies?.development?.remote or {}
        scripts: _([processedPaths.scripts, processedPaths.templates or []]).flatten() 
        main: processedPaths.main
        styles: processedPaths.styles
        fonts: processedPaths.fonts
        images: manifest.client?.images or [],


    # clean up
    if component.local.length is 0
        delete component.local
        delete component.paths

    if component.scripts.length is 0
        delete component.scripts
        delete component.main


    # remove some empty lists
    for key in ['images', 'fonts', 'styles']
        if component[key].length is 0
            delete component[key]

    fs.writeFileSync componentPath, JSON.stringify component, null, 4

usage = "USAGE: #{path.basename process.argv[1]} <path to manifest> " +
"<path to component.json>"

parseCommandline = (argv) ->
    debug 'processing arguments ...'

    knownOpts =
        help : Boolean
        'add-script': [String, Array]
        'add-style': [String, Array]
        'add-font': [String, Array]

    shortHands =
        h: ['--help']

    parsedArgs = nopt knownOpts, shortHands, argv, 0
    return parsedArgs


main = ->
    debug 'started standalone'
    parsedArgs = parseCommandline process.argv.splice 2

    if parsedArgs.help or parsedArgs.argv.remain.length isnt 2
        console.log parsedArgs
        console.log require('../package.json').version
        console.log usage
        process.exit 1

    findProjectRoot (err, projectRoot) ->
        if err?
            console.error err.message
            process.exit 1

        debug 'started standalone'
        [manifestPath, componentPath] = parsedArgs.argv.remain
        generateComponent projectRoot, manifestPath, componentPath, {
            additionalFiles:
                scripts: parsedArgs['add-script']
                styles: parsedArgs['add-style']
                fonts: parsedArgs['add-font']
        }


module.exports.generateComponent = generateComponent
module.exports.parseCommandline = parseCommandline
module.exports.main = main





