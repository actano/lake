fs = require 'fs'
path = require 'path'
{exec} = require 'child_process'
carrier = require 'carrier'
{_} = require 'underscore'

async = require 'async'
debug = require('debug')('file-locator')

nodeModulesBin = undefined
projectRoot = undefined
DOT_LAKE_FILENAME = '.lake'

npm_bin = (cb) ->
    exec 'npm bin', (err, stdout, stderr) ->
        cb err, stdout

exports.getDotLakeList = (cb) ->
    async.waterfall [
        (cb) ->
            if projectRoot?
                cb null, projectRoot
            else
                exports.findProjectRoot cb

        (projectRoot, cb) ->
            dotLakePath = path.join projectRoot, DOT_LAKE_FILENAME
            fs.readFile dotLakePath, 'utf8', cb

        (fileContent, cb) ->
            lines = fileContent.split '\n'
            lines = _(lines).map (line) ->
                # trim
                line.replace /^\s+|\s+$/g, ''
            cb null, lines

    ], (err, result) ->
        if err?
            console.error err
            return err
        cb null, result




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
                if l.length isnt 1
                    l.pop()
                    currPath = path.sep + path.join.apply null, l
                    cb null
                else
                    cb new Error "#{DOT_LAKE_FILENAME} could not be found."
            else
                cb null

    test = -> found

    async.doUntil fn, test, (err) ->
        projectRoot = currPath
        cb err, currPath

exports.locateNodeModulesBin = (cb) ->
    if nodeModulesBin?
        return cb null, nodeModulesBin
    debug('painstakingly finding node_modules/.bin')
    exports.findProjectRoot (err, result) ->
        if not err?
            nodeModulesBin = path.join result, 'node_modules', '.bin'
            return cb null, nodeModulesBin
        npm_bin (err, result) ->
            if err? then return cb err
            nodeModulesBin = result
            cb null, result