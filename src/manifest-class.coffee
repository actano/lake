path = require 'path'
{_} = require 'underscore'
debug = require('debug')('Manifest')

class ManifestError extends Error

class Manifest
    construcotr: (@projectRoot, @featurePath) ->
        manifestPath = path.join @projectRoot, @featurePath, 'Manifest'
        debug "requiring #{manifestPath}"
        m = require manifestPath
        if _(m).isEmpty()
            throw new ManifestError 'Manifest is empty or has no module.exports'
        _.extend(@, m)


module.exports = Manifest