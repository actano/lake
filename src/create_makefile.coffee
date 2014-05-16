# Std library
path = require 'path'
fs = require 'fs'

# Third party
debug = require('debug')('create-makefile')
{_} = require 'underscore'

# Local dep
{findProjectRoot} = require './file-locator'
RuleBook = require './rulebook'

module.exports.createMakefiles = (input, output) ->
    debug 'findProjectRoot'
    projectRoot = findProjectRoot()
    lakeConfigPath = path.join projectRoot, '.lake', 'config'
    lakeConfig = require(lakeConfigPath)

    # Default output points to current behavior: .lake/build
    # This can be changed once all parts expect the includes at build/lake
    output ?= path.join lakeConfig.lakePath, 'build'

    for featurePath in input
        manifest = null
        try
            manifestPath = path.join projectRoot, featurePath, 'Manifest'
            manifest = require manifestPath
        catch err
            err.message = "Error in Manifest #{featurePath}: #{err.message}"
            debug err.message
            return err

        customConfig = _.clone lakeConfig.config
        _.extend customConfig,
            featurePath: featurePath
            projectRoot: projectRoot

        console.log "Creating .mk file for #{featurePath}"
        createLocalMakefileInc lakeConfig.rules, customConfig, manifest, output
    return null

createLocalMakefileInc = (ruleFiles, config, manifest, output) ->
    ruleBook = new RuleBook()
    for ruleFile in ruleFiles
        ruleFilePath = path.join config.projectRoot, ruleFile
        rules = require ruleFilePath
        rules.addRules config, manifest, ruleBook
    ruleBook.close()

    mkFilePath = getFilename config.projectRoot, config.featurePath, output

    writeToFile mkFilePath, ruleBook

getFilename = (projectRoot, featurePath, output) ->
    featureName = path.basename featurePath
    mkFilePath = path.join path.resolve(projectRoot, output), featureName + '.mk'
    return mkFilePath

writeToFile = (filename, ruleBook) ->
    contents = ""

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
            contents += "#{rule.targets.join ' '}: "+
                "#{rule.dependencies.join ' '}\n"
            if rule.actions?
                actions = ['@echo ""', "@echo \"\u001b[3;4m#{rule.targets}\u001b[24m\""]
                actions = actions.concat rule.actions
                contents += "\t#{actions.join '\n\t'}\n\n"
            else
                contents += '\n'

    fs.writeFileSync filename, contents
