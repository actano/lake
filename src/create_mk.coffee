fs = require 'fs'
path = require 'path'
async = require 'async'
{_} = require 'underscore'
debug = require('debug')('lake.create_mk')
{inspect} = require 'util'
RuleBook = require './rulebook'
cfg = require './local-make'

MANIFEST_FILE_NAME = "Manifest"

createLocalMakefileInc = (lakeConfig, projectRoot, absoluteFeaturePath, outerCb) ->

    featurePath = path.relative projectRoot, absoluteFeaturePath
    # check manifest
    absoluteManifestPath = path.join absoluteFeaturePath, MANIFEST_FILE_NAME
    try
        manifest = require absoluteManifestPath
    catch err
        console.error "#{MANIFEST_FILE_NAME} for #{featurePath} cannot be parsed: #{err.message}"
        return outerCb err

    ruleBook = new RuleBook()
    for ruleFile in lakeConfig.ruleCollection
        ruleFilePath = path.join projectRoot, ruleFile
        # filename has no extension -> be flexible coffee or js
        #unless fs.existsSync ruleFilePath
        #    return outerCb new Error "rule file not found at #{ruleFilePath}"
        try
            rules = require ruleFilePath
            rules.addRules lakeConfig, featurePath, manifest, ruleBook
        catch err
            console.error "stopped on loading rules for feature '#{featurePath}'"
            [message, firstStackElem] = err.stack.split '\n'
            if cfg.verbose
                console.error err.stack
            else
                console.error firstStackElem
            return outerCb err

    # close the rule to be on the safe side, regardless if it's closed already
    ruleBook.close()

    try
        # evaluate the rules, call 'factory()'
        ruleBook.getRules()
    catch err
        console.error "stopped on resolving rules for feature '#{featurePath}'"
        [message, firstStackElem] = err.stack.split '\n'
        if cfg.verbose
            console.error err.stack
        else
            console.error firstStackElem
        return outerCb err


    writeMkFile ruleBook, lakeConfig, projectRoot, featurePath, outerCb

writeMkFile = (ruleBook, lakeConfig, projectRoot, featurePath, cb) ->
    buffer = ""
    globalTargets = {}
    for id, rule of ruleBook.getRules()
        localBuffer = ""
        if rule.globalTargets?
            for globalKey in rule.globalTargets
                unless globalTargets[globalKey]?
                    globalTargets[globalKey] = []
                globalTargets[globalKey].push rule.targets

        rule.dependencies or= []
        # wrap everything into an array and then flatten
        # so user can use string or (nested) array
        for prop in ["targets", "dependencies", "actions"]
            if rule[prop]?
                rule[prop] = _([ rule[prop] ]).flatten()

        # print the rule only if a target exists
        # otherwise user created the rule for RuleBook API features
        if rule.targets?
            localBuffer += "# #{id}\n"
            localBuffer += "#{rule.targets.join ' '}: #{rule.dependencies.join ' '}\n"
            if rule.actions?
                localBuffer += "\t#{rule.actions.join '\n\t'}\n\n"
            else
                localBuffer += "\n"

            #console.log localBuffer
            buffer += localBuffer

    featureName = path.basename featurePath
    mkFilePath = path.join lakeConfig.lakePath, "build", featureName + ".mk"
    mkDirectory = path.dirname mkFilePath
    unless fs.existsSync mkDirectory
        fs.mkdirSync mkDirectory

    fs.writeFile mkFilePath, buffer, (err) ->
        if err?
            console.error "error writing #{mkFilePath}"
            return cb err

        cb null, mkFilePath, globalTargets


module.exports = createLocalMakefileInc

