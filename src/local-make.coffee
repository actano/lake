fs = require 'fs'
{exec, spawn} = require 'child_process'
path = require 'path'
{inspect} = require 'util'
{_} = require 'underscore'
pkg = require '../package'

async = require 'async'
nopt = require 'nopt'

createMakefiles = require('./create_makefile')

{locateNodeModulesBin, findProjectRoot} = require('./file-locator')
debug = require('debug')('local-make')

knownOpts =
    preventMakefileRebuild : Boolean
    help : Boolean
    version : Boolean

shortHands = {
    p: ['--preventMakefileRebuild']
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


if parsedArgs.preventMakefileRebuild
    console.log "(don't update Makefile.mk)"

[target] = parsedArgs.argv.remain
target ?= ''

waterFallTasks = []

waterFallTasks = waterFallTasks.concat [
    (cb) ->
        findProjectRoot cb
    ]

unless parsedArgs.preventMakefileRebuild
    waterFallTasks.push (projectRoot, cb) ->
        debug('createMakefiles')
        createMakefiles (err) ->
            cb err, projectRoot
            
waterFallTasks = waterFallTasks.concat [
    (projectRoot, cb) ->

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

        make.on 'close', (exitCode) ->
            cb null, exitCode

        make.stdout.pipe process.stdout
        make.stderr.pipe process.stderr
]

async.waterfall waterFallTasks, (err, exitCode) ->
    console.log '------------------------------'
    if err?
        console.error err.message
        exitCode or= 1
    else if exitCode is 0
        console.log 'done'
    else
        console.log 'done with make errors'
    process.exit exitCode
    