# Std library
fs = require 'fs'
path = require 'path'
{exec} = require 'child_process'
{inspect} = require 'util'

# Third party
async = require 'async'
debug = require('debug') 'manifest-generator.i-test'
difflet = require('difflet') indent: 4
js2c = require 'js2coffee'
{_} = require 'underscore'

# Local dep
Glob = require './globber'
componentGenerator = require './create_component_json'
manifestGenerator = require './create_manifest'

createManifest = (absolutePath, outputDirectory, outputFileName, callback) ->
    async.waterfall [

        (callback) ->
            componentFilePath =  absolutePath
            debug "reading component file: #{componentFilePath}"
            fs.readFile componentFilePath, 'utf8', callback

        (componentJsonFileContent, callback) ->
            debug 'generating manifest ...'
            componentObject = JSON.parse componentJsonFileContent.toString()
            componentDirectory = path.dirname absolutePath
            manifestGenerator componentObject,
                componentDirectory,
                (err, manifest) ->
                    return callback new Error "error when generating " +
                        "manifest file: #{err.message}" if err?
                    debug 'done'
                    callback null, manifest, componentObject

        (manifest, componentObject, callback) ->
            debug 'convert from manifest to component ...'

            manifest = js2c.build manifest,
                pretty_arrays:false
                indent:true

            component = componentGenerator manifest,
                sourceFilePrefix: 'build'

            debug 'comparing component.json files (original and converted)'

            success = _(componentObject).isEqual component
            debug 'result was computed'
            if not success
                diff = difflet.compare componentObject, component
                console.log diff
            callback null, success, manifest

        (result, manifest, callback) ->
            outputPath = path.join outputDirectory, outputFileName
            fs.writeFile outputPath, manifest, {encoding:'utf8'}, (err) ->
                return callback err if err?

                callback null, result, outputDirectory

    ], callback


componentFile = 'component.json'
pattern = '*/component.json'
manifestFileName = '_Manifest.coffee'
cwd = '..'

globber = new Glob pattern, 'build/', {cwd}
globber.on 'match', (filePath) ->
    console.log "converting #{filePath} ..."
    absolutePath = path.resolve cwd, filePath
    directory = path.dirname absolutePath
    createManifest absolutePath,
        directory,
        manifestFileName,
        (err, result, path) ->
            console.log "finished witht result: #{result} for path #{path}"

globber.on 'end', (err) ->
    return callback err if err?

