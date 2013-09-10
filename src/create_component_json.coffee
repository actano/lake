#!/usr/bin/env coffee

fs = require 'fs'
path = require 'path'
async = require 'async'
{inspect} = require 'util'
coffee = require 'coffee-script'
{_} = require 'underscore'
nopt = require 'nopt'
debug = require('debug')('create-component.json')

{findProjectRoot} = require('./file-locator')

debug "require done"

EXTENSION_MAPPING =
    '.coffee': '.js'
    '.styl': '.css'
    '.jade': '.js'



convertFileType = (filenames) ->
    if not filenames? then throw new Error "convertFileType expects string or array instead of #{filenames}"
    if not filenames.length? then return ""

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
        for filename in filenames
            convertExtension filename


processPaths = (manifest, projectRoot, manifestPath, componentPath, sourceFilePrefix) ->

    addPrefix = (localpath) ->
        return path.join sourceFilePrefix, localpath

    keyValuePairs = ["scripts", "templates", "styles"].map (key) ->
        value = _(convertFileType(manifest.client?[key] or [])).map addPrefix
        [key, value]

    processedPaths = _(keyValuePairs).object()

    if manifest.client?.dependencies?.production?.local?
        processedPaths.localFeatures = _(manifest.client.dependencies.production.local).map (localpath) ->
            return path.basename localpath

        processedPaths.localPaths = _.uniq _(manifest.client.dependencies.production.local).map (localpath) ->
            absoluteManifestPath = path.dirname path.resolve manifestPath
            absoluteComponentPath = path.dirname path.resolve componentPath

            debug "Manifest is in #{absoluteManifestPath}"
            debug "component.json will be in #{absoluteComponentPath}"

            absolutePath = path.join absoluteManifestPath, localpath
            debug "processing path of local dependency at #{absolutePath}"
            absolutePath = path.dirname absolutePath

            relativeToProjectRoot = path.relative projectRoot, absolutePath
            # in component.json we will be referencing the tree in build/local_components
            # because it reflects the structure that component build expects.
            absolutePath = path.join projectRoot, "build", "local_components", relativeToProjectRoot

            #relative to component.json
            path.relative absoluteComponentPath, absolutePath

    processedPaths.main = if manifest.client?.main?.length
        convertFileType( path.join(sourceFilePrefix, manifest.client.main))
    else
        ""

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
                    "bar/client.js"    
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
                    "./client.js"    
                ]
            }
        client.js
    
    ###
    {sourceFilePrefix} = options
    sourceFilePrefix ?= '.'

    manifest = require path.resolve manifestPath

    processedPaths = processPaths manifest, projectRoot, manifestPath, componentPath, sourceFilePrefix

    component = {
        name: manifest.name or "GIVE ME A NAME!"
        description: manifest.description or ""
        version: manifest.version or "0.0.1"
        license: manifest.license or "MIT"
        keywords: manifest.keywords or []
        dependencies: manifest.client?.dependencies?.production?.remote or {}
        local: processedPaths.localFeatures or []
        paths: processedPaths.localPaths or []
        development: manifest.client?.dependencies?.development?.remote or {}
        scripts: processedPaths.scripts.concat processedPaths.templates or []
        styles: processedPaths.styles
        main: processedPaths.main
    }

    fs.writeFileSync componentPath, JSON.stringify component, null, 4


module.exports = generateComponent


if require.main is module
    usage = """
        USAGE: #{path.basename process.argv[1]} <path to manifest> <path to component.json>
    """

    debug "processing arguments ..."


    knownOpts =
        "help" : Boolean

    shortHands = {
        "h": ["--help"]
    }

    parsedArgs = nopt(knownOpts, shortHands, process.argv, 2)


    if parsedArgs.help or parsedArgs.argv.remain.length isnt 2
        console.log usage
        process.exit 0    
    
    findProjectRoot (err, projectRoot) ->
        if err?
            console.error err.message
            process.exit 1

        debug "started standalone"
        [manifestPath, componentPath] = parsedArgs.argv.remain
        generateComponent projectRoot, manifestPath, componentPath
    





