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

getHelpTopics = (projectRoot) ->
    topics = []

    lakeConfig = require path.join projectRoot, '.lake', 'config'
    for ruleFile in lakeConfig.rules
        rule = require path.join projectRoot, ruleFile

        if rule.readme?.name? and rule.readme?.path?
            topic =
                name: rule.readme.name
                description: rule.description
                path: rule.readme.path

            topics.push topic

    return topics

printHelpTopic = (projectRoot, topics, requestedTopic) ->
    topicFound = false

    for topic in topics
        if topic.name is requestedTopic
            helpText = fs.readFileSync topic.path, 'utf8'

            console.log "\nHelp for '#{requestedTopic}':\n"
            console.log helpText

            topicFound = true

            break

    console.log "\nHelp topic '#{requestedTopic}' doesn't exist." if not topicFound

module.exports.build = ->
    knownOpts =
        preventMakefileRebuild: Boolean
        preventMakeRun: Boolean
        input: [String, Array]
        output: String
        global: String
        help: String
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
        findProjectRoot (err, projectRoot) ->
            usage = ->
                console.log 'USAGE'
                console.log inspect shortHands

            listTopics = (topics) ->
                for topic in topics
                    text = '\t' + topic.name
                    text += ' - ' + topic.description if topic.description?
                    console.log text

            return usage() if err?

            topics = getHelpTopics projectRoot

            if parsedArgs.help.toString() is 'true'
                usage()

                console.log "\nRun 'lake -h [topic]' to show additional information about a specific topic."
                console.log "Available topics are:"

                listTopics topics
            else if parsedArgs.help is 'topics'
                listTopics topics
            else
                printHelpTopic projectRoot, topics, parsedArgs.help

            process.exit 0
        return

    parsedArgs.preventMakefileRebuild ?= true

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
                return

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
