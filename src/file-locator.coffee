# Std library
fs = require 'fs'
path = require 'path'

projectRoot = undefined
DOT_LAKE_FILENAME = '.lake'

exports.findProjectRoot = ->
    if projectRoot?
        return projectRoot

    currPath = process.cwd().split(path.sep)
    while !fs.existsSync(path.sep + path.join(currPath..., DOT_LAKE_FILENAME))
        currPath.pop()
        if currPath.length == 0
            return undefined
    return path.sep + path.join(currPath...)
