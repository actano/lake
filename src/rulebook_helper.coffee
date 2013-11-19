# Std library
path = require 'path'
fs = require 'fs'

# Third party
{_} = require 'underscore'

module.exports.resolveLocalComponentPaths = (array, projectRoot, featurePath,
        localComponentPath) ->
    for relativePath in array
        # /Users/john/project/foo/featureA
        absoluteFeaturePath = path.join projectRoot, featurePath
        # /Users/john/project/bar/featureB
        absolutePath = path.resolve absoluteFeaturePath, relativePath
        # bar/featureB
        relativeLocalComponentPath = path.relative projectRoot, absolutePath
        # build/local_components/bar/featureB
        path.join localComponentPath, relativeLocalComponentPath