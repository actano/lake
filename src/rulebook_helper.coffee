# Std library
path = require 'path'
fs = require 'fs'

# Third party
{_} = require 'underscore'

###
    if a path (in a manifest) is relative to its feautre with a '../'
    it's necessary to resolve the absolute path
    and convert then into a relative path (relative to the project root)
    example:
    lib/foo/featureA has a dependency to ../featureB and ../../bar/featureC
    the dependencies have to be resolved into
    lib/foo/featureB and lib/bar/featureC

###

module.exports.getNodeModulePath = (filePath) ->
    if filePath is "/"
        throw new Error "node_modules doesn't exist"

    nodeModulePath = path.join filePath, "node_modules"
    if fs.existsSync nodeModulePath
        return nodeModulePath
    else
        # go directory up and search there
        return module.exports.getNodeModulePath path.resolve filePath, ".."

module.exports.resolveManifestVariables = (array, projectRoot) ->
    for filePath in array
        filePath = filePath.replace /__PROJECT_ROOT__/g, projectRoot
        nodeModules = module.exports.getNodeModulePath projectRoot
        filePath = filePath.replace /__NODE_MODULES__/g, nodeModules

module.exports.resolveFeatureRelativePaths = (array, projectRoot,
        featurePath) ->
    for relativePath in array
        # /Users/john/project/foo/featureA
        absoluteFeaturePath = path.join projectRoot, featurePath
        # /Users/john/project/bar/featureB
        absolutePath = path.resolve absoluteFeaturePath, relativePath
        # bar/featureB
        path.relative projectRoot, absolutePath

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