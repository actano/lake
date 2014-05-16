# Std library
fs = require 'fs'
path = require 'path'
{exec} = require 'child_process'

# Third party
carrier = require 'carrier'
{_} = require 'underscore'
async = require 'async'
debug = require('debug')('file-locator')

nodeModulesBin = undefined
projectRoot = undefined
DOT_LAKE_FILENAME = '.lake'

npm_bin = (cb) ->
    if nodeModulesBin?
        debug 'reuse npm_bin path'
        cb null, nodeModulesBin
    debug 'spawn "npm bin" to locate .bin path'
    exec 'npm bin', (err, stdout, stderr) ->
        cb err, stdout

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

exports.locateNodeModulesBin = (cb) ->
    if nodeModulesBin?
        debug 'reuse locateNodeBin'
        return cb null, nodeModulesBin
    debug('painstakingly finding node_modules/.bin')
    exports.findProjectRoot (err, projectRoot) ->
        if not err?
            binPath = path.join projectRoot, 'node_modules', '.bin'
            debug "try to locate .bin path: #{binPath}"
            exists = fs.existsSync binPath
            if exists
                nodeModulesBin = binPath
                return cb null, binPath
            debug 'node_modues/.bin is not in project root\'s directory'

        npm_bin (err, binPath) ->
            debug 'use npm bin to locate .bin path'
            if err? then return cb err

            nodeModulesBin = binPath
            return cb null, binPath
