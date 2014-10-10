# Std library
path = require 'path'
fs = require 'fs'

# Third party
debug = require('debug')('create-makefile')

# Local dep
Config = require './config'
RuleBook = require './rulebook'

_flatten = (result, array) ->
  for x in array
    if Array.isArray x
      _flatten result, x
    else
      result.push x
  return result

flatten = (array) ->
  _flatten [], array

module.exports.createMakefiles = (input, output) ->

    projectRoot = Config.projectRoot()
    lakeConfig = Config.config()
    output ?= path.join lakeConfig.config.lakeOutput

    CustomConfig = (featurePath) ->
      @featurePath = featurePath
      @projectRoot = projectRoot
    CustomConfig.prototype = lakeConfig.config

    process.stdout.write "Generating Makefiles"
    for featurePath in input
        manifest = null
        try
            manifestPath = path.join projectRoot, featurePath, 'Manifest'
            manifest = require manifestPath
        catch err
            err.message = "Error in Manifest #{featurePath}: #{err.message}"
            debug err.message
            return err

        customConfig = new CustomConfig(featurePath)

        #console.log "Creating .mk file for #{featurePath}"
        createLocalMakefileInc lakeConfig.rules, customConfig, manifest, output
        process.stdout.write "."
    console.log ""
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

flatten = (array, result = []) ->
    for x in array
        if Array.isArray(x)
            flatten x, result
        else
            result.push x
    result

writeToFile = (filename, ruleBook) ->
    contents = ""

    for rule in ruleBook.getRules()
        rule.dependencies or= []
        # wrap everything into an array and then flatten
        # so user can use string or (nested) array
        for prop in ['targets', 'dependencies', 'actions']
            if rule[prop]?
                rule[prop] = flatten [ rule[prop] ]

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
