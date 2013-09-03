#!/usr/bin/env coffee

fs = require 'fs'
path = require 'path'
{exec} = require 'child_process'

mkdirp = require 'mkdirp'
async = require 'async'
debug = require('debug')("create-makefile")
eco = require 'eco'
{_} = require 'underscore'

createLocalMakefileInc = require './create_local_makefile_inc'
Glob = require '../lib/globber'
{findProjectRoot, locateNodeModulesBin} = require './file-locator'

subfolder = "lib"

mergeObject = (featureTargets, globalTargets) ->
    _(featureTargets).each (value, key, list) ->
        if globalTargets[key]?
            globalTargets[key].push value
        else
            globalTargets[key] = value
    , globalTargets


createMakefiles = (cb) ->

    async.waterfall [
        (cb) ->
            debug 'locateNodeModulesBin'
            locateNodeModulesBin cb

        (binPath, cb) ->
            debug 'findProjectRoot'
            findProjectRoot (err, projectRoot) ->
                cb err, binPath, projectRoot

        (binPath, projectRoot, cb) ->
            makefileIncPathList = []
            globalTargets = {}

            options =
                cwd: path.join projectRoot, subfolder

            globber = new Glob "**/Manifest.coffee", "/components/", options

            q = async.queue (target, cb) ->
                cwd = path.join projectRoot, target
                console.log "Creating Makefile.mk for #{target}"
                createLocalMakefileInc projectRoot, cwd, (err, makefileContent, globalFeatureTargets) ->
                    if err? then return cb err

                    mergeObject globalFeatureTargets, globalTargets

                    relativePath = path.join target, "build", "Makefile.mk"
                    fullPath = path.join projectRoot, relativePath 
                    buildDir = path.dirname fullPath
                    debug "making sure #{buildDir} exists."
                    mkdirp buildDir, (err) ->
                        if err? then return cb err
                        fs.writeFile fullPath, makefileContent, (err) ->
                            if err? then return cb err
                            cb null, relativePath
            , 1

            globber.on 'match', (filePath) ->
                target = path.join subfolder, path.dirname(filePath)
                q.push target, (err, relativePath) ->
                    if not err?
                        debug "created #{relativePath}"
                        makefileIncPathList.push relativePath

                    else
                        message = "failed to create Makefile.mk for #{target}: #{err}"
                        debug message
                        # we have to make sure that the callback is only called once
                        globber.removeAllListeners()
                        cb new Error message

            globber.on 'end', (err) ->
                q.drain = ->
                    debug globalTargets
                    cb err, binPath, projectRoot, makefileIncPathList, globalTargets

        (binPath, projectRoot, makeFileIncPathList, globalTargets, cb) ->
            fs.readFile "#{__dirname}/Makefile.eco", "utf-8", (err, template) ->

                cb err, projectRoot, eco.render template,
                    binPath: binPath
                    toolPath: path.join projectRoot, "tools"
                    includes: makeFileIncPathList
                    globalTargets: globalTargets

        (projectRoot, makefileContent, cb) ->
            fs.writeFile path.join(projectRoot, 'Makefile'), makefileContent, (err) ->
                cb err
        ], cb


if require.main is module
    createMakefiles (err) ->
         if err?
            console.error "error: #{err}"
            process.exit 1
         else
            console.log "created global Makefile"

else
    module.exports = createMakefiles
