# Std library
fs = require 'fs'
path = require 'path'

# Third party
{_} = require 'underscore'
debug = require('debug')('lake.create_mk')

# Local dep
RuleBook = require './rulebook'

module.exports.createLocalMakefileInc = createLocalMakefileInc = (rules, config, manifest, output, cb) ->
    ruleBook = new RuleBook()
    for ruleFile in rules
        ruleFilePath = path.join config.projectRoot, ruleFile
        rules = require ruleFilePath
        rules.addRules config, manifest, ruleBook
    ruleBook.close()

    mkFilePath = getFilename config.projectRoot, config.featurePath, output
    stream = createStream mkFilePath
    stream.on 'error', (err) ->
        return cb err
    stream.once 'finish', ->
        debug 'Makefile stream finished'
        return cb null, mkFilePath
    writeToStream stream, ruleBook
    stream.end()

getFilename = (projectRoot, featurePath, output) ->
    featureName = path.basename featurePath
    mkFilePath = path.join path.resolve(projectRoot, output), featureName + '.mk'
    return mkFilePath

createStream = (filename) ->
    mkDirectory = path.dirname filename
    unless fs.existsSync mkDirectory
        fs.mkdirSync mkDirectory
    stream = fs.createWriteStream filename, {encoding: 'utf8'}

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
