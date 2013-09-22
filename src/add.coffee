fs = require 'fs'
path = require 'path'
async = require 'async'
nopt = require 'nopt'
debug = require('debug')('lake-add')
{inspect} = require 'util'
{findProjectRoot, getFeatureList} = require('./file-locator')

knownOpts =
    "help" : Boolean

shortHands = {
    "h": ["--help"]
}

parsedArgs = nopt(knownOpts, shortHands, process.argv, 2)

features = parsedArgs.argv.remain

debug "adding #{features}"

if parsedArgs.help or not features?.length
    console.log 'USAGE'
    console.log inspect knownOpts
    console.log inspect shortHands
    process.exit 0

async.waterfall [
    findProjectRoot
    (projectRoot, cb) ->
        getFeatureList (err, list) ->
            cb err, projectRoot, list
    (projectRoot, preexistingFeatures, cb) ->
        outPath = path.join projectRoot, ".lake/features"
        addList = []
        for feature in features
            feature = path.resolve feature
            if feature.length < projectRoot.length or feature.substr(0, projectRoot.length) isnt projectRoot
                return cb new Error "Unable to add feature #{feature}"
            feature = feature.substr(projectRoot.length+1)
            if preexistingFeatures.indexOf(feature) isnt -1
                console.log "ignoring pre-existing feature #{feature}"
            else
                debug "adding feature #{feature}"
                addList.push feature

        fs.appendFile outPath, addList.join("\n")+"\n", cb

], (err) ->
    if err?
        console.error err
        process.exit 1
    process.exit 0    