# Std library
fs = require 'fs'
path = require 'path'
{inspect} = require 'util'

# Third party
async = require 'async'
nopt = require 'nopt'
debug = require('debug')('lake-list')

# Local dep
{getFeatureList} = require('./file-locator')

knownOpts =
    help : Boolean

shortHands = {
    h: ['--help']
}

parsedArgs = nopt(knownOpts, shortHands, process.argv, 2)

if parsedArgs.help
    console.log 'USAGE'
    console.log inspect knownOpts
    console.log inspect shortHands
    process.exit 0

getFeatureList (err, list) ->
    console.log l for l in list
    