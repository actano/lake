path = require 'path'
fs = require 'fs'
coffee = require 'coffee-script/register'
{findProjectRoot} = require './file-locator'

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

            console.log "Help for '#{requestedTopic}':\n"
            console.log helpText

            topicFound = true

            break

    console.log "Help topic '#{requestedTopic}' doesn't exist." if not topicFound

module.exports.help = ->
    projectRoot = findProjectRoot()

    listTopics = (topics) ->
        for topic in topics
            text = '\t' + topic.name
            text += ' - ' + topic.description if topic.description?
            console.log text

    topics = getHelpTopics projectRoot

    [node, script, command] = process.argv

    if not command?
        console.log "Run 'lake-help [topic]' to show additional information about a specific topic."
        console.log "Available topics are:"
        listTopics topics
    else if command == 'topics'
        listTopics topics
    else
        printHelpTopic projectRoot, topics, command
