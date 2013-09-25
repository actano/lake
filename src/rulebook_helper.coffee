{_} = require 'underscore'
path = require 'path'

###
   replace the extension of a file (have to be dot seperated), ignoring the rest of the path (directories)
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