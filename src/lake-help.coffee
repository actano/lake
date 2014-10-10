path = require 'path'
fs = require 'fs'
Config = require './config'
projectRoot = Config.projectRoot()

getHelpTopics = ->
    topics = []

    lakeConfig = Config.config()
    for ruleFile in lakeConfig.rules
        rule = require path.join projectRoot, ruleFile

        if rule.readme?.name? and rule.readme?.path?
            topic =
                name: rule.readme.name
                description: rule.description
                path: rule.readme.path

            topics.push topic

    return topics

printHelpTopic = (topics, requestedTopic) ->
    topicFound = false

    for topic in topics
        if topic.name is requestedTopic
            helpText = fs.readFileSync topic.path, 'utf8'

            console.log "Help for '#{requestedTopic}':\n"
            console.log helpText

            topicFound = true

            break

    console.log "Help topic '#{requestedTopic}' doesn't exist." if not topicFound

module.exports.help = ->
    listTopics = (topics) ->
        for topic in topics
            text = '\t' + topic.name
            text += ' - ' + topic.description if topic.description?
            console.log text

    topics = getHelpTopics()

    command = process.argv[2]

    if not command?
        console.log "Run 'lake-help [topic]' to show additional information about a specific topic."
        console.log "Available topics are:"
        listTopics topics
    else if command == 'topics'
        listTopics topics
    else
        printHelpTopic topics, command
