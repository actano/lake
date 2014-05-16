# Std library
path = require 'path'

# Third party
debug = require('debug')('create-makefile')
{_} = require 'underscore'

# Local dep
{createLocalMakefileInc} = require './create_mk'
{findProjectRoot} = require './file-locator'

module.exports.createMakefiles = (input, output, cb) ->
    debug 'findProjectRoot'
    projectRoot = findProjectRoot()
    lakeConfigPath = path.join projectRoot, '.lake', 'config'
    lakeConfig = require(lakeConfigPath)

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
            return err

        customConfig = _.clone lakeConfig.config
        _.extend customConfig,
            featurePath: featurePath
            projectRoot: projectRoot

        console.log "Creating .mk file for #{featurePath}"
        createLocalMakefileInc lakeConfig.rules, customConfig, manifest, output
    return null
