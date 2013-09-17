fs = require 'fs'
{exec, spawn} = require 'child_process'
path = require 'path'
{inspect} = require 'util'
{_} = require 'underscore'

async = require 'async'
nopt = require 'nopt'

createMakefiles = require('./create_makefile')

{locateNodeModulesBin, findProjectRoot} = require('./file-locator')
debug = require('debug')('local-make')

knownOpts =
    "preventMakefileRebuild" : Boolean
    "help" : Boolean

shortHands = {
    "p": ["--preventMakefileRebuild", 'true']
    "h": ["--help"]
}

parsedArgs = nopt(knownOpts, shortHands, process.argv, 2)

if parsedArgs.help
    console.log 'USAGE'
    console.log inspect shortHands
    process.exit 0

[target] = parsedArgs.argv.remain
target ?= ""

console.log "building #{if target.length then ('target \"' + target+'\"') else 'default target'}"
if parsedArgs.preventMakefileRebuild
    console.log "(using pre-existing Makefile)"

waterFallTasks = []

waterFallTasks = waterFallTasks.concat [
    (cb) ->
        findProjectRoot cb
    ]

unless parsedArgs.preventMakefileRebuild
    waterFallTasks.push (projectRoot, cb) ->
        debug("createMakefiles")
        createMakefiles (err) ->
            cb err, projectRoot
            
waterFallTasks = waterFallTasks.concat [    
    (projectRoot, cb) ->

        console.log "project root is #{projectRoot}"

        prefix = path.relative projectRoot, process.cwd()
        console.log "local prefix is '#{prefix}'"

        target = path.join prefix, target
        target = '' if target is '.'

        args = _.compact [
            "-C"
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
    if err?
        console.error err
        exitCode or= 1
    else if exitCode is 0
        console.log "done"
    else 
        console.log "done with errors"
    process.exit exitCode
    