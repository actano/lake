# Std library
fs = require 'fs'
path = require 'path'
{inspect} = require 'util'

# Third party
async = require 'async'
{_} = require 'underscore'
debug = require('debug')('lake.create_mk')

# Local dep
RuleBook = require './rulebook'
cfg = require './local-make'

MANIFEST_FILE_NAME = 'Manifest'

createLocalMakefileInc = (lakeConfig, projectRoot, absoluteFeaturePath, cb) ->

    featurePath = path.relative projectRoot, absoluteFeaturePath
    # check manifest
    absoluteManifestPath = path.join absoluteFeaturePath, MANIFEST_FILE_NAME
    try
        manifest = require absoluteManifestPath
    catch err
        console.error "#{MANIFEST_FILE_NAME} for #{featurePath} " +
            "cannot be parsed: #{err.message}"
        return cb err

    ruleBook = new RuleBook()
    for ruleFile in lakeConfig.rules
        ruleFilePath = path.join projectRoot, ruleFile
        # filename has no extension -> be flexible coffee or js
        #unless fs.existsSync ruleFilePath
        #    return cb new Error "rule file not found at #{ruleFilePath}"
        try
            rules = require ruleFilePath
            rules.addRules lakeConfig, featurePath, manifest, ruleBook
        catch err
            console.error "cannot load rulefile #{ruleFile} for " +
                "feature '#{featurePath}'"
            [message, firstStackElem] = err.stack.split '\n'
            if cfg.verbose
                console.error err.stack
            else
                console.error firstStackElem
            return cb err

    # close the rule to be on the safe side, regardless if it's closed already
    ruleBook.close()

    try
        # evaluate the rules, call 'factory()'
        ruleBook.getRules()
    catch err
        console.error "cannot load rulefile #{ruleFile} " +
            "for feature '#{featurePath}'"
        [message, firstStackElem] = err.stack.split '\n'
        if cfg.verbose
            console.error err.stack
        else
            console.error firstStackElem
        return cb err

    globalTargets = {}
    stream = createStream globalTargets,
        lakeConfig, projectRoot, featurePath, cb

    writeToStream stream, ruleBook, globalTargets
    stream.end()


createStream = (globalTargets, lakeConfig, projectRoot, featurePath, cb) ->

    featureName = path.basename featurePath
    mkFilePath = path.join lakeConfig.lakePath, 'build', featureName + '.mk'
    mkDirectory = path.dirname mkFilePath
    unless fs.existsSync mkDirectory
        fs.mkdirSync mkDirectory

    stream = fs.createWriteStream mkFilePath, {encoding: 'utf8'}
    stream.on 'error', (err) ->
        console.error "error while stream to #{mkFilePath}"
        return cb err

    stream.once 'finish', ->
        debug 'Makefile stream finished'
        return cb null, mkFilePath, globalTargets


writeToStream = (stream, ruleBook, globalTargets) ->
    for id, rule of ruleBook.getRules()
        if rule.globalTargets?
            for globalKey in rule.globalTargets
                unless globalTargets[globalKey]?
                    globalTargets[globalKey] = []
                globalTargets[globalKey].push rule.targets

        rule.dependencies or= []
        # wrap everything into an array and then flatten
        # so user can use string or (nested) array
        for prop in ['targets', 'dependencies', 'actions']
            if rule[prop]?
                rule[prop] = _([ rule[prop] ]).flatten()

        # print the rule only if a target exists
        # otherwise user created the rule for RuleBook API features
        if rule.targets?
            stream.write "# #{id}\n"
            stream.write "#{rule.targets.join ' '}: "+
                "#{rule.dependencies.join ' '}\n"
            if rule.actions?
                stream.write "\t#{rule.actions.join '\n\t'}\n\n"
            else
                stream.write '\n'

module.exports = {
    createLocalMakefileInc
    createStream
    writeToStream
}