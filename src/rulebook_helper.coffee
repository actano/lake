# Std library
path = require 'path'
fs = require 'fs'

# Third party
{_} = require 'underscore'

###
    replace the extension of a file (have to be dot seperated),
    ignoring the rest of the path (directories)
    last parameter needs to be in this format: '.html'

module.exports.replaceExtension = (sourcePath, newExtension) ->
    path.join (path.dirname sourcePath),
        ((path.basename sourcePath, path.extname sourcePath) + newExtension)

###

###
    path manipulation
    prepend the prefix to the path of each array element and call the hook (cb)
    with the already manipulated path, unless hook is null

module.exports.concatPaths = (array, opt, hook) ->
    opt.pre or= ''
    opt.post or= ''

    _(array).map (item) ->
        buildPathItem = path.join opt.pre, item, opt.post
        if hook?
            buildPathItem =  hook buildPathItem

        return buildPathItem
###

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