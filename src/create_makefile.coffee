#!/usr/bin/env coffee

# Std library
fs = require 'fs'
path = require 'path'
{exec} = require 'child_process'

# Third party
async = require 'async'
debug = require('debug')('create-makefile')
{_} = require 'underscore'

# Local dep
{createLocalMakefileInc} = require './create_mk'
{
    findProjectRoot
    locateNodeModulesBin
    getFeatureList
} = require './file-locator'

Manifest = require './manifest-class'

mergeObject = (featureTargets, globalTargets) ->
    for key, value of featureTargets
        unless globalTargets[key]?
            globalTargets[key] = []
        unless _(_(value).flatten()).isEmpty()
            globalTargets[key].push value

    return


createMakefiles = (input, output, global, cb) ->

    async.waterfall [
        (cb) ->
            debug 'locateNodeModulesBin'
            locateNodeModulesBin cb

        (binPath, cb) ->
            debug 'findProjectRoot'
            findProjectRoot (err, projectRoot) ->
                if err? then return cb err
                cb null, binPath, projectRoot

        (binPath, projectRoot, cb) ->
            debug 'retrieve feature list'
            if input?
                cb null, binPath, projectRoot, input
            else
                getFeatureList (err, list) ->
                    if err? then return cb err
                    cb null, binPath, projectRoot, list

        (binPath, projectRoot, featureList, cb) ->
            lakeConfigPath = path.join projectRoot, '.lake', 'config'

            ###
            # don't check file existence with extension
            # it should be flexible coffee or js, ...?
            ###
            #unless (fs.existsSync lakeConfigPath)
            #    throw new Error "lake config not found at #{lakeConfigPath}"

            lakeConfig = require lakeConfigPath
            mkFiles = []

            # Default output points to current behavior: .lake/build
            # This can be changed once all parts expect the includes at build/lake
            output ?= path.join lakeConfig.lakePath, 'build'

            # queue worker function
            q = async.queue (manifest, cb) ->
                console.log "Creating .mk file for #{manifest.featurePath}"
                createLocalMakefileInc lakeConfig, manifest, output,
                (err, mkFile) ->
                    if err? then return cb err

                    debug "finished with #{mkFile}"
                    cb null, mkFile
                    
            , 4

            errorMessages = []
            for featurePath in featureList
                manifest = null
                try
                    manifest = new Manifest projectRoot, featurePath
                catch err
                    err.message = "Error in Manifest #{featurePath}: " +
                    "#{err.message}"
                    debug err.message
                    return cb err

                q.push manifest, (err, mkFile) ->
                    if not err?
                        debug "created #{mkFile}"
                        mkFiles.push mkFile
                    else
                        message = 'failed to create Makefile.mk for ' +
                        "#{featurePath}: #{err}"
                        debug message
                        errorMessages.push message

        
            # will be called when queue proceeded last item
            # TODO: why this assignment have to be in this scope
            # and not a scope more outer
            q.drain = ->
                debug 'Makefile generation finished ' +
                'for feature all features in .lake'
                if errorMessages.length
                    cb new Error "failed to create Makefile" + errorMessages
                else
                    cb null, lakeConfig, binPath, projectRoot, mkFiles

        (lakeConfig, binPath, projectRoot, mkFiles, cb) ->
            if not global
                return cb()
            stream = fs.createWriteStream global
            stream.on 'error', (err) ->
                console.error 'error occurs during streaming global Makefile'
                return cb err

            stream.once 'finish', ->
                debug 'Makefile stream finished'
                return cb null
            stream.write("")
        ], cb

module.exports = {
        createMakefiles
}
