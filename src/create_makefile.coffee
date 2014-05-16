# Std library
fs = require 'fs'
path = require 'path'

# Third party
async = require 'async'
debug = require('debug')('create-makefile')
{_} = require 'underscore'

# Local dep
{createLocalMakefileInc} = require './create_mk'
{
    findProjectRoot
} = require './file-locator'

createMakefiles = (input, output, global, cb) ->

    async.waterfall [
        (cb) ->
            debug 'findProjectRoot'
            findProjectRoot (err, projectRoot) ->
                if err? then return cb err
                cb null, projectRoot

        (projectRoot, cb) ->
            lakeConfigPath = path.join projectRoot, '.lake', 'config'
            config = require(lakeConfigPath).config

            # Default output points to current behavior: .lake/build
            # This can be changed once all parts expect the includes at build/lake
            output ?= path.join lakeConfig.lakePath, 'build'

            for featurePath in input
                manifest = null
                try
                    manifestPath = path.join projectRoot, featurePath, 'Manifest'
                    manifest = require manifestPath
                catch err
                    err.message = "Error in Manifest #{featurePath}: #{err.message}"
                    debug err.message
                    return cb err

                customConfig = _.clone config
                _.extend customConfig,
                    featurePath: featurePath
                    projectRoot: projectRoot

                console.log "Creating .mk file for #{manifest.featurePath}"
                createLocalMakefileInc customConfig, manifest, output, (err, mkFile) ->
                    if err? then return cb err
                    debug "finished with #{mkFile}"
            cb null
        ], cb

module.exports = {
        createMakefiles
}
