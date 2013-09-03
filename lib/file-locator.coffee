fs = require 'fs'
path = require 'path'
{exec} = require 'child_process'

async = require 'async'
debug = require('debug')('file-locator')

nodeModulesBin = undefined
projectRoot = undefined

npm_bin = (cb) ->
    exec 'npm bin', (err, stdout, stderr) ->
        cb err, stdout

exports.locateNodeModulesBin = (cb) ->
    if nodeModulesBin?
        return cb null, nodeModulesBin
    debug('painstakenly finding node_modules/.bin')
    exports.findProjectRoot (err, result) ->
        if not err?
            nodeModulesBin = path.join result, 'node_modules', '.bin'
            return cb null, nodeModulesBin
        npm_bin (err, result) ->
            if err? then return cb err
            nodeModulesBin = result
            cb null, result

exports.findProjectRoot = (cb) ->
    if projectRoot?
        return cb null, projectRoot
    debug('painstakenly finding project root')
    currPath = process.cwd()
    found = false
    fn = (cb) ->
        filePath = path.join currPath, 'package.json'
        fs.exists filePath, (exists) ->
            found = exists
            if not found
                l = currPath.split path.sep
                if l.length isnt 1
                    l.pop()
                    currPath = path.sep + path.join.apply null, l
                    cb null
                else
                    cb new Error "package.json could not be found."
            else
                cb null

    test = -> found

    async.doUntil fn, test, (err) ->
        projectRoot = currPath
        cb err, currPath
