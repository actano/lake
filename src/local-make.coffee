# Std library
fs = require 'fs'
path = require 'path'
{exec, spawn} = require 'child_process'
{inspect} = require 'util'

# Third party
{_} = require 'underscore'
async = require 'async'
nopt = require 'nopt'
debug = require('debug')('local-make')

# Local dep
pkg = require '../package'
{createMakefiles} = require('./create_makefile')
{findProjectRoot} = require('./file-locator')

module.exports.build = ->
    knownOpts =
        preventMakefileRebuild: Boolean
        preventMakeRun: Boolean
        input: String
        output: String
        global: String
        help: Boolean
        version: Boolean
        verbose: Boolean

    shortHands = {
        p: ['--preventMakefileRebuild']
        d: ['--preventMakeRun']
        i: ['--input']
        o: ['--output']
        g: ['--global']
        h: ['--help']
        v: ['--version']
        V: ['--verbose']
    }

    parsedArgs = nopt(knownOpts, shortHands, process.argv, 2)

    module.exports.verbose = parsedArgs.verbose

    if parsedArgs.version
        console.log pkg.version
        return process.exit 0

    if parsedArgs.help
        console.log 'USAGE'
        console.log inspect shortHands
        process.exit 0


    if parsedArgs.preventMakefileRebuild
        console.log '(don\'t update Makefile.mk)'

    [target] = parsedArgs.argv.remain
    target ?= ''

    async.waterfall [
        (cb) ->
            findProjectRoot cb

        (projectRoot, cb) ->
            if parsedArgs.preventMakefileRebuild
                cb null, projectRoot

            debug('createMakefiles')
            createMakefiles parsedArgs.input, parsedArgs.output, parsedArgs.global, (err) ->
                cb err, projectRoot

        (projectRoot, cb) ->
            if parsedArgs.preventMakeRun
                cb null, 0
                return
            console.log '------------------------------'
            console.log "project root is #{projectRoot}"

            prefix = path.relative projectRoot, process.cwd()
            if prefix is ''
                console.log 'building default target'
            else
                console.log "building '#{prefix}'"

            target = path.join prefix, target
            target = '' if target is '.'

            args = _.compact [
                '-C'
                projectRoot
                target
            ]
            make = spawn 'make', args

            make.stdout.pipe process.stdout
            make.stderr.pipe process.stderr

            make.on 'close', (exitCode) ->
                console.log '------------------------------'
                if exitCode isnt 0
                    cb new Error "make exit code is #{exitCode}"
                cb null, exitCode
    ], (err, exitCode) ->
        if err?
            console.error err.message
            exitCode or= 1
        else if exitCode is 0
            console.log 'done'
        else
            console.log 'done with make errors'
        process.exit exitCode
