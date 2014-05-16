# Std library
fs = require 'fs'
path = require 'path'
{exec} = require 'child_process'

# Third party
{_} = require 'underscore'
async = require 'async'
debug = require('debug')('file-locator')

projectRoot = undefined
DOT_LAKE_FILENAME = '.lake'

exports.findProjectRoot = (cb) ->
    if projectRoot?
        return cb null, projectRoot
    debug('painstakingly finding project root')
    currPath = process.cwd()
    found = false
    fn = (cb) ->
        filePath = path.join currPath, DOT_LAKE_FILENAME
        fs.exists filePath, (exists) ->
            found = exists
            if not found
                l = currPath.split path.sep
                if l.length > 2
                    l.pop()
                    currPath = path.sep + path.join.apply null, l
                    debug "#{DOT_LAKE_FILENAME} not found at #{currPath}"
                    cb null
                else
                    cb new Error "#{DOT_LAKE_FILENAME} could not be found."
            else
                cb null

    test = -> found

    async.doUntil fn, test, (err) ->
        if err? then currPath = null
        projectRoot = currPath
        cb err, currPath
