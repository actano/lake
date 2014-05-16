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

MANIFEST_FILE_NAME = 'Manifest'

createLocalMakefileInc = (lakeConfig, manifest, output, cb) ->
    {projectRoot, featurePath} = manifest

    ruleBook = new RuleBook()
    for ruleFile in lakeConfig.rules
        ruleFilePath = path.join projectRoot, ruleFile
        rules = require ruleFilePath
        rules.addRules lakeConfig, featurePath, manifest, ruleBook
        

    # close the rule to be on the safe side, regardless if it's closed already
    ruleBook.close()

    stream = createStream lakeConfig, projectRoot, featurePath, output, cb

    writeToStream stream, ruleBook
    stream.end()


createStream = (lakeConfig, projectRoot, featurePath, output, cb) ->

    featureName = path.basename featurePath
    mkFilePath = path.join path.resolve(projectRoot, output), featureName + '.mk'
    mkDirectory = path.dirname mkFilePath
    unless fs.existsSync mkDirectory
        fs.mkdirSync mkDirectory

    stream = fs.createWriteStream mkFilePath, {encoding: 'utf8'}
    stream.on 'error', (err) ->
        console.error "error while stream to #{mkFilePath}"
        return cb err

    stream.once 'finish', ->
        debug 'Makefile stream finished'
        return cb null, mkFilePath


writeToStream = (stream, ruleBook) ->
    for rule in ruleBook.getRules()

        rule.dependencies or= []
        # wrap everything into an array and then flatten
        # so user can use string or (nested) array
        for prop in ['targets', 'dependencies', 'actions']
            if rule[prop]?
                rule[prop] = _([ rule[prop] ]).flatten()

        # print the rule only if a target exists
        # otherwise user created the rule for RuleBook API features
        if rule.targets?
            stream.write "#{rule.targets.join ' '}: "+
                "#{rule.dependencies.join ' '}\n"
            if rule.actions?
                actions = ['@echo ""', "@echo \"\u001b[3;4m#{rule.targets}\u001b[24m\""]
                actions = actions.concat rule.actions
                stream.write "\t#{actions.join '\n\t'}\n\n"
            else
                stream.write '\n'

module.exports.createLocalMakefileInc = createLocalMakefileInc
