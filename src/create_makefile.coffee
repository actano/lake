#!/usr/bin/env coffee

fs = require 'fs'
path = require 'path'
{exec} = require 'child_process'

mkdirp = require 'mkdirp'
async = require 'async'
debug = require('debug')("create-makefile")
eco = require 'eco'
{_} = require 'underscore'

#createLocalMakefileInc = require './create_local_makefile_inc'
createLocalMakefileInc = require './create_mk'

{findProjectRoot, locateNodeModulesBin, getFeatureList} = require './file-locator'

#TODO: ask regular why there is a second param 'globalTargets'
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
                if err? then return cb err
                cb null, binPath, projectRoot

        (binPath, projectRoot, cb) ->
            debug "retreive feature list"
            getFeatureList (err, list) ->
                if err? then return cb err
                cb null, binPath, projectRoot, list

        (binPath, projectRoot, featureList, cb) ->

            makefileIncPathList = []
            globalTargets = {}
            stopQueue = false
            # queue worker function
            q = async.queue (featurePath, queueCb) ->

                if stopQueue
                    return queueCb new Error "queue worker was stopped due stop flag"

                cwd = path.join projectRoot, featurePath
                console.log "Creating Makefile.mk for #{featurePath}"
                createLocalMakefileInc projectRoot, cwd, (err, makefileMkPath, globalFeatureTargets) ->
                    if err
                        console.error err.message
                        stopQueue = true
                        return queueCb err

                    mergeObject globalFeatureTargets, globalTargets
                    queueCb null, makefileMkPath
                    ###
                    makefileMkPath = path.join featurePath, "build", "Makefile.mk"
                    absolutePath = path.join projectRoot, makefileMkPath
                    buildDir = path.dirname absolutePath
                    debug "making sure #{buildDir} exists."
                    mkdirp buildDir, (err) ->
                        if err? then return queueCb err
                        fs.writeFile absolutePath, makefileContent, (err) ->
                            if err? then return queueCb err
                            queueCb null, makefileMkPath
                    ###

            , 1

            async.each featureList, (featurePath, eachCb) ->

                # manifest syntax check
                try
                    m = require path.join projectRoot, featurePath, 'Manifest'
                    if _(m).isEmpty()
                        eachCb new Error 'Manifest is empty or has no module.exports'
                catch err
                    err.message = "Error in Manifest #{featurePath}: #{err.message}"
                    debug err.message
                    eachCb err

                q.push featurePath, (err, makefileMkPath) ->
                    if not err?
                        debug "created #{makefileMkPath}"
                        makefileIncPathList.push makefileMkPath
                        eachCb()
                    else
                        message = "failed to create Makefile.mk for #{featurePath}: #{err}"
                        debug message
                        # we have to make sure that the callback is only called once
                        eachCb new Error message

            , (err) ->
                if err
                    console.error "worker queue error: #{err.message}"
                    return cb err

                # will be called when queue proceeded last item
                # TODO: why this assignment have to be in this scope, and not a scope more outer
                q.drain = ->
                    debug 'Makefile.mk finished for feature all features in .lake'
                    debug globalTargets
                    cb null, binPath, projectRoot, makefileIncPathList, globalTargets


        (binPath, projectRoot, makeFileIncPathList, globalTargets, cb) ->
            fs.readFile path.join(projectRoot, 'Makefile.eco'), 'utf-8', (err, template) ->
                if err?
                    console.error err
                    return err
                cb err, projectRoot, eco.render template,
                    binPath: binPath
                    projectRoot: projectRoot
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
