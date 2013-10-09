{_} = require 'underscore'
path = require 'path'
fs = require 'fs'

###
    replace the extension of a file (have to be dot seperated), ignoring the rest of the path (directories)
    last parameter needs to be in this format: '.html'
###
module.exports.replaceExtension = (sourcePath, newExtension) ->
    path.join (path.dirname sourcePath), ((path.basename sourcePath, path.extname sourcePath) + newExtension)

###
    dynamic lookup for nested object values
    use: lookup {foo:{bar:{baz:1}}}, "foo.bar.baz"
    result: 1
###
module.exports.lookup = (context, key) ->
    if key.indexOf('.') is -1
        if not context[key]?
            err = new Error "key '#{key}' is null of context '#{context}'"
            err.code = 'KEY_NOT_FOUND'
            return throw err

        return context[key]
    else
        # if context had nested keys, use recursive strategy
        [firstKey, rest...] = key.split '.'

        if not context[firstKey]?
            err = new Error "key '#{firstKey}' is null in '#{key}'"
            err.code = 'KEY_NOT_FOUND'
            return throw err

    return module.exports.lookup context[firstKey], rest.join('.')

###
    path manipulation
    prepend the prefix to the path of each array element and call the hook (callback)
    with the already manipulated path, unless hook is null
###
module.exports.concatPaths = (array, opt, hook) ->
    opt.pre or= ''
    opt.post or= ''

    _(array).map (item) ->
        buildPathItem = path.join opt.pre, item, opt.post
        if hook?
            buildPathItem =  hook buildPathItem

        return buildPathItem

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
    module.exports.concatPaths array, {}, (filePath) ->
        filePath = filePath.replace /__PROJECT_ROOT__/g, projectRoot
        nodeModules = module.exports.getNodeModulePath projectRoot
        filePath = filePath.replace /__NODE_MODULES__/g, nodeModules
        return filePath

module.exports.resolveFeatureRelativePaths = (array, projectRoot, featurePath) ->
    module.exports.concatPaths array, {}, (relativePath) ->
        absoluteFeaturePath = path.join projectRoot, featurePath        # /Users/john/project/foo/featureA
        absolutePath = path.resolve absoluteFeaturePath, relativePath   # /Users/john/project/bar/featureB
        return path.relative projectRoot, absolutePath                  # bar/featureB

module.exports.resolveLocalComponentPaths = (array, projectRoot, featurePath, localComponentPath) ->
    module.exports.concatPaths array, {}, (relativePath) ->
        absoluteFeaturePath = path.join projectRoot, featurePath                # /Users/john/project/foo/featureA
        absolutePath = path.resolve absoluteFeaturePath, relativePath           # /Users/john/project/bar/featureB
        relativeLocalComponentPath = path.relative projectRoot, absolutePath    # bar/featureB
        return path.join localComponentPath, relativeLocalComponentPath         # build/local_components/bar/featureB