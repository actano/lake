# Std library
fs = require 'fs'
path = require 'path'
{inspect} = require 'util'

# Third party
nopt = require 'nopt'
debug = require('debug')('local-make')

# magic hook for the right coffee stacktrace
require 'coffee-errors'

# Local dep
pkg = require '../package'
{createMakefiles} = require('./create_makefile')
{findProjectRoot} = require('./file-locator')

module.exports.build = ->
    knownOpts =
        input: [String, Array]
        output: String
        help: String
        version: Boolean

    shortHands = {
        i: ['--input']
        o: ['--output']
        h: ['--help']
        v: ['--version']
    }

    parsedArgs = nopt(knownOpts, shortHands, process.argv, 2)

    if parsedArgs.version
        console.log pkg.version
        return process.exit 0

    if parsedArgs.help
        console.log 'USAGE'
        console.log inspect shortHands
        process.exit 0

    debug('createMakefiles')
    err = createMakefiles parsedArgs.input, parsedArgs.output
    if err?
        console.error err.message
        process.exit 1
    else
        console.log 'done'
        process.exit 0
