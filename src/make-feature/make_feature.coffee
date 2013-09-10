#! /usr/bin/env coffee

###
    usage:
    make_feature <name>
###

nopt = require "nopt"
path = require "path"
{exec} = require "child_process"
dive = require "dive"
fs =   require "fs"
mkdirp = require "mkdirp"
once = require "once"
async = require "async"
eco = require "eco"
debug = require('debug')('make-feature')
{_} = require 'underscore'

{findProjectRoot} = require '../file-locator'


processFile = ({filepath, destPath, replacements}, cb) ->
    debug "Processing #{filepath}"
    destDir = path.dirname destPath

    content = fs.readFileSync filepath, "utf8"
    content = filterContent content, replacements

    mkdirp destDir, (err) ->
        if err? then return cb err

        debug "created directory #{destDir}"

        fs.writeFileSync destPath, content
        debug "wrote #{destPath}"
        cb null


copyFiles = (src, dest, replacements, cb) ->
    cb = once cb
    q = async.queue processFile, 1
    q.drain = ->
        debug "cb() by drain"
        cb()

    dive src, { all: true }, (err, filepath) ->
        if err? then throw err

        relativeSrcPath = path.relative src, filepath

        ## we apply __BOILERPLATE_XXX__ replacement patterns not only to
        ## file content but also to filepaths (including filenames)
        relativeDestPath = replaceFilename relativeSrcPath, replacements
        destPath = path.join dest, relativeDestPath

        q.push {filepath, destPath, replacements}, ->
            debug "queue item: #{filepath} finished"

    # DO NOT call cb() by dive, the callback will be fired too early!

replaceFilename = (content,replacements) ->
    for key, value of replacements
        content = content.replace new RegExp("__BOILERPLATE_#{key}__|#{key}$", 'g'), value

    return content


filterContent = (content, replacements) ->
    eco.render content, replacements

###
    replace _ and - and convert it to a CamelCase name
###
getClassName = (name) ->
    upperChunks = _(name.split('-')).map (item) ->
        item.substr(0, 1).toUpperCase() + item.substr(1)
    upperChunks = _(upperChunks.join('').split('_')).map (item) ->
        item.substr(0, 1).toUpperCase() + item.substr(1)
    return upperChunks.join('')

main = (name, libPrefix, description, cb) ->

    libPrefix = 'lib'
    className = getClassName(name)

    replacements =
        NAME: name
        CLASSNAME: className
        INSTANCENAME: "#{className[0].toLowerCase()}#{className.slice 1}"
        DESCRIPTION: description
        LOGGER_ID: "rplan.#{name}"
        DEBUG_ID: "rplan.#{name}"
        LOGGER_LIB_ID: "rplan.lib.#{name}"
        DEBUG_LIB_ID: "rplan.lib.#{name}"
        "coffee.eco": "coffee"

    findProjectRoot (err, projectRoot) ->
        if err? then return err

        featurePath = path.join projectRoot, libPrefix, name
        console.log "Creating feature #{name} in #{featurePath}"
        srcPath = "#{__dirname}/helloworld"
        copyFiles srcPath, featurePath, replacements, cb

###
    TODO: refactor local-make that libPrefix can be something other than 'lib'
###
if require.main is module
    knownOpts = {
        server : Boolean
        client : Boolean
        description : String
        path: String
    }
    shortHands = {
        "s" : ["--server"]
        "c" : ["--client"]
        "d" : ["--description"]
        "p" : ["--path"]
    }

    parsed = nopt(knownOpts, shortHands, process.argv, 2)

    name = parsed.argv.remain[0] if parsed.argv.remain.length is 1
    libPrefix = parsed.path or 'lib'

    if not name?
        console.log "Usage: #{path.basename process.argv[1]} <name> -d <description>"
        console.log ""
        process.exit 1


    main name, libPrefix, parsed.description, (err) ->
        if err?
            console.error err
            process.exit 1

        debug "feature creation finished"
        process.exit 0


module.exports = main
