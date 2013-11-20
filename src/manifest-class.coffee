path = require 'path'
{_} = require 'underscore'
debug = require('debug')('Manifest')
Accessors = require 'accessors'

class ManifestError extends Error

class Manifest
    constructor: (@projectRoot, @featurePath) ->
        manifestPath = path.join @getAbsolteDirectory(), 'Manifest'
        debug "requiring #{manifestPath}"
        m = require manifestPath
        if _(m).isEmpty()
            throw new ManifestError 'Manifest is empty or has no module.exports'
        _.extend(@, m)

    getAbsolteDirectory: ->
        path.join @projectRoot, @featurePath

    resolveRelativePath: (relativePath) ->
        absolutePath = path.resolve @getAbsolteDirectory(), relativePath
        path.relative @projectRoot, absolutePath

    replacePlaceholders: (value) ->
        value = value.replace /__PROJECT_ROOT__/g, @projectRoot
        nodeModules = path.join @projectRoot, 'node_modules'
        
        # TODO: implement config override
        value = value.replace /__NODE_MODULES__/g, nodeModules

    lookup: (key) ->
        value = Accessors.get this, key
        if value?
            if _.isArray value
                return (@replacePlaceholders entry for entry in value)
            return @replacePlaceholders value
        else
            undefined

    lookupPath: (key) ->
        value = @lookup key
        if value?
            if _.isArray value
                return ((@replacePlaceholders @resolveRelativePath entry) for entry in value)
            return @replacePlaceholders @resolveRelativePath value
        else
            undefined

module.exports = Manifest