fs = require 'fs'
path = require 'path'
async = require 'async'
nopt = require 'nopt'
debug = require('debug')('lake-init')
{inspect} = require 'util'
{locateNodeModulesBin, findProjectRoot} = require('./file-locator')

knownOpts =
    "help" : Boolean
    "force" : Boolean

shortHands = {
    "h": ["--help"]
}

parsedArgs = nopt(knownOpts, shortHands, process.argv, 2)

if parsedArgs.help
    console.log 'USAGE'
    console.log inspect knownOpts
    console.log inspect shortHands
    process.exit 0

# if we find a project root, --force is required
findProjectRoot (err, existingProjectRoot) ->
    if existingProjectRoot?
        if not parsedArgs.force
            console.log "WARNING: seems like a .lake directory already exists at #{existingProjectRoot}.\n
         Use --force to overwrite the files in .lake/"
            process.exit 1

        console.log "overwriting .lake directory"
    else
        console.log "creating .lake directory"

    try
        fs.mkdirSync '.lake'
    catch err
        if err.code is "EEXIST"
            unless parsedArgs.force
                console.log "please rm -rf .lake if you want to re-init. I will not do such a thing for you."
                process.exit 1
        else
            console.error "failed to create .lake directory: #{err}"
            process.exit 1

    # put a .gitignore file into .lake to ignore build/ directory
    debug "writing .lake/.gitignore"
    fs.writeFileSync ".lake/.gitignore", "build"

    # creating build/ directory
    debug "creating .lake/build"
    try
        fs.mkdirSync '.lake/build'
    catch err
        if err.code is not "EEXIST"
            console.error "failed to create .lake/build directory: #{err}"

    # write an empty config file
    debug "writing .lake/config"
    fs.writeFileSync ".lake/config", "# add your config here.\n; created on #{new Date()}\n"

    # write an empty features file
    debug "writing .lake/features"
    fs.writeFileSync ".lake/features", "# created on #{new Date()}\n"


###
async.waterfall [

    ], (err, exitCode) ->
        if err?
            console.error err
            exitCode or= 1
        else if exitCode is 0
            console.log "done"
        else 
            console.log "done with errors"
        process.exit exitCode
###
    