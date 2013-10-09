fs = require 'fs'
path = require 'path'
async = require 'async'
{_} = require 'underscore'
debug = require('debug')('lake.create_mk')
{inspect} = require 'util'
RuleBook = require './rulebook'


MANIFEST_FILE_NAME = "Manifest.coffee"
MAKEFILE_MK_NAME = path.join "build", "Makefile.mk"


createLocalMakefileInc = (lakeConfig, projectRoot, absoluteFeaturePath, outerCb) ->

    featurePath = path.relative projectRoot, absoluteFeaturePath
    # check manifest
    absoluteManifestPath = path.join absoluteFeaturePath, MANIFEST_FILE_NAME
    try
        manifest = require absoluteManifestPath
    catch err
        console.error "#{MANIFEST_FILE_NAME} for #{featurePath} cannot be parsed: #{err.message}"
        throw err

    ruleBook = new RuleBook()
    for ruleFile in lakeConfig.ruleCollection
        ruleFilePath = path.join projectRoot, ruleFile
        unless fs.existsSync ruleFilePath
            throw new Error "rule file not found at #{ruleFilePath}"
        rules = require ruleFilePath
        rules.addRules lakeConfig, featurePath, manifest, ruleBook

    # evaluate the rules, call 'factory()'
    ruleBook.resolveAllFactories()

    writeMkFile ruleBook, lakeConfig, projectRoot, featurePath, outerCb

writeMkFile = (ruleBook, lakeConfig, projectRoot, featurePath, cb) ->
    buffer = ""
    globalTargets = {}
    for id, rule of ruleBook.getRules()
        localBuffer = ""
        if rule.global?
            for globalKey in rule.global
                unless globalTargets[globalKey]?
                    globalTargets[globalKey] = []
                globalTargets[globalKey].push rule.targets

        rule.dependencies or= []
        # wrap everything into an array and then flatten
        for prop in ["targets", "dependencies", "actions"]
            if rule[prop]?
                rule[prop] = _([ rule[prop] ]).flatten()

        localBuffer += "# #{id}\n"
        localBuffer += "#{rule.targets.join ' '}: #{rule.dependencies.join ' '}\n"
        if rule.actions?
            localBuffer += "\t#{rule.actions.join '\n\t'}\n\n"
        else
            localBuffer += "\n"

        #console.log localBuffer
        buffer += localBuffer

    #console.log "#{projectRoot} #{featurePath} #{MAKEFILE_MK_NAME}"
    mkFilePath = path.join projectRoot, featurePath, MAKEFILE_MK_NAME
    relativeMkPath = path.relative projectRoot, mkFilePath
    buildDirectory = path.join projectRoot, featurePath, lakeConfig.featureBuildDirectory
    unless fs.existsSync buildDirectory
        fs.mkdirSync buildDirectory

    fs.writeFile mkFilePath, buffer, (err) ->
        if err?
            console.error "error writing #{mkFilePath}"
            throw err

        cb null, relativeMkPath, globalTargets


module.exports = createLocalMakefileInc

