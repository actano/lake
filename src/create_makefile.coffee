#!/usr/bin/env coffee

fs = require 'fs'
path = require 'path'
{exec} = require 'child_process'
{inspect} = require 'util'
mkdirp = require 'mkdirp'
async = require 'async'
debug = require('debug')("create-makefile")
eco = require 'eco'
{_} = require 'underscore'

newApi = true
createLocalMakefileInc = undefined

if newApi is true
    createLocalMakefileInc = require './create_mk'
else
    createLocalMakefileInc = require './create_local_makefile_inc'


{findProjectRoot, locateNodeModulesBin, getFeatureList} = require './file-locator'

mergeObject = (featureTargets, globalTargets) ->
    for key, value of featureTargets
        unless globalTargets[key]?
            globalTargets[key] = []
        unless _(_(value).flatten()).isEmpty()
            globalTargets[key].push value

    return


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
            lakeConfigPath = path.join projectRoot, ".lake", "config"

            ###
            # don't check file existence with extension
            # it should be flexible coffee or js, ...?
            ###
            #unless (fs.existsSync lakeConfigPath)
            #    throw new Error "lake config not found at #{lakeConfigPath}"

            lakeConfig = require lakeConfigPath
            makefileIncPathList = []
            globalTargets = {}
            stopQueue = false
            # queue worker function
            q = async.queue (featurePath, queueCb) ->

                if stopQueue
                    return queueCb new Error "queue worker was stopped due stop flag"

                cwd = path.join projectRoot, featurePath
                console.log "Creating Makefile.mk for #{featurePath}"
                createLocalMakefileInc lakeConfig, projectRoot, cwd, (err, makefileContent, globalFeatureTargets) ->
                    if err
                        stopQueue = true
                        return queueCb err

                    mergeObject globalFeatureTargets, globalTargets
                    if newApi is true
                        debug "finished with #{makefileContent}"
                        queueCb null, makefileContent # this is the path for newApi, Makefile.mk already written
                    else
                        makefileMkPath = path.join featurePath, "build", "Makefile.mk"
                        absolutePath = path.join projectRoot, makefileMkPath
                        buildDir = path.dirname absolutePath
                        debug "making sure #{buildDir} exists."
                        mkdirp buildDir, (err) ->
                            if err? then return queueCb err
                            fs.writeFile absolutePath, makefileContent, (err) ->
                                if err? then return queueCb err
                                queueCb null, makefileMkPath


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
                    return cb err

                # will be called when queue proceeded last item
                # TODO: why this assignment have to be in this scope, and not a scope more outer
                q.drain = ->
                    debug 'Makefile.mk finished for feature all features in .lake'
                    debug globalTargets
                    cb null, lakeConfig, binPath, projectRoot, makefileIncPathList, globalTargets

        (lakeConfig, binPath, projectRoot, makeFileIncPathList, globalTargets, cb) ->
            # create temp Makefile.eco
            debug "open write stream for Makefile"
            stream = fs.createWriteStream path.join(projectRoot, 'Makefile'), {encoding: 'utf8'}
            stream.on 'error', (err) ->
                console.error "error occurs during streaming global Makefile"
                return cb err

            stream.once 'finish', ->
                debug 'Makefile stream finished'
                return cb null

            stream.write '# this file is generated by lake\n'
            stream.write "# generated at #{new Date()}\n"
            stream.write '\n'

            # assigments
            # built-in assignments
            stream.write "ROOT := #{projectRoot}\n"
            stream.write "NODE_BIN := #{binPath}\n"
            stream.write '\n'

            # custom assignments
            for assignment in lakeConfig.makeAssignments
                for left, right of assignment
                    stream.write "#{left} := #{right}\n"

            stream.write '\n'

            # default (first) rule
            defaultRule = lakeConfig.makeDefaultTarget
            if defaultRule.target?
                stream.write defaultRule.target
                if defaultRule.dependencies?
                    stream.write ": #{defaultRule.dependencies}"
                stream.write '\n'
                if defaultRule.actions?
                    stream.write '\t' + _([defaultRule.actions]).flatten().join '\n\t'

            # includes (Makefile.mk)
            stream.write '\n'
            stream.write ("include #{file}" for file in makeFileIncPathList).join '\n'
            stream.write '\n\n'

            # global targets, added by RuleBook API
            for targetName, dependencies of globalTargets
                stream.write "#{targetName}: #{dependencies.join ' '}\n"

            stream.write '\n'

            # global targets, added by .lake/config.js/.coffee
            if lakeConfig.globalRules?
                stream.write lakeConfig.globalRules + '\n'

            debug 'write last line to stream'
            stream.end ''
            debug 'written it'

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
