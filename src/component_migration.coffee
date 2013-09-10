manifestGenerator = require "./create_manifest"
componentGenerator = require "./create_component_json"
fs = require 'fs'
path = require 'path'
{exec} = require 'child_process'
async = require 'async'
debug = require('debug')('manifest-generator.i-test')
difflet = require('difflet')({indent: 4});
js2c = require "js2coffee"
{inspect} = require 'util'
{_} = require "underscore"
Glob = require "./globber"


createManifest = (absolutePath, outputDirectory, outputFileName, outerCb) ->
    async.waterfall [

        (cb) ->
            componentFilePath =  absolutePath
            debug "reading component file: #{componentFilePath}"
            fs.readFile componentFilePath, "utf8", cb

        (componentJsonFileContent, cb) ->
            debug "generating manifest ..."
            componentObject = JSON.parse(componentJsonFileContent.toString())
            componentDirectory = path.dirname absolutePath
            manifestGenerator componentObject, componentDirectory, (err, manifest) ->
                if err? then return cb new Error "error when generating manifest file: #{err.message}"
                debug "done"
                cb null, manifest, componentObject

        (manifest, componentObject, cb) ->
            debug "convert from manifest to component ..."

            manifest = js2c.build(manifest, {pretty_arrays:false, indent:true})
            #console.log manifest
            component = componentGenerator manifest, {sourceFilePrefix: "build"}

            debug "comparing component.json files (original and converted)"

            success = _(componentObject).isEqual component
            debug "result was computed"
            if not success
                diff = difflet.compare componentObject, component
                console.log diff
            cb null, success, manifest

        (result, manifest, cb) ->
            outputPath = path.join outputDirectory, outputFileName
            fs.writeFile outputPath, manifest, {encoding:'utf8'}, (err) ->
                if err? then return cb err

                cb null, result, outputDirectory

    ], outerCb


componentFile = 'component.json'
pattern = "*/component.json"
manifestFileName = "_Manifest.coffee"
cwd = ".."

globber = new Glob pattern, "build/", {cwd}
globber.on 'match', (filePath) ->
    console.log "converting #{filePath} ..."
    absolutePath = path.resolve cwd, filePath
    directory = path.dirname absolutePath
    createManifest absolutePath, directory, manifestFileName, (err, result, path) ->
        console.log "finished witht result: #{result} for path #{path}"

globber.on 'end', (err) ->
    if err? then return cb err

