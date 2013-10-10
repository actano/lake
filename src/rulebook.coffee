{inspect} = require 'util'
debug = require('debug')('lake.rulebook')
{_} = require 'underscore'

class RuleBook

    constructor: ->
        @ruleFactories = {} # id: factory func
        @ruleTags = {} # tag: ["ruleId1", "ruleId2"]
        @factoryOrder = [] # [id1, id4, id2, id3] # show if circular dependency is found

    getRules: (rulesIds) ->
        #console.dir @ruleFactories
        rulesIds or= (key for key of @ruleFactories)
        debug "getting #{rulesIds}"
        rules = {}
        for id in rulesIds
            debug id
            rules[id] = @ruleFactories[id].factory()
        return rules # return the rules = id: {targets, dependenceis, actions}

    resolveAllFactories: ->
        for id of @ruleFactories
            @callRuleFactory id

    addToGlobalTarget: (targetName, rule) ->
        rule.global = [targetName]

    addRule: (id, tags, factory) ->
        debug "adding rule #{id}"
        if @ruleFactories[id]?
            throw new Error "rule already exists with id: #{id}"

        tags or= []

        for tag in tags
            tagList = @ruleTags[tag] or= [] # init if null
            tagList.push id

        entry = {
            tags: tags
            factory: factory
            init: false
            processed: false
        }
        @ruleFactories[id] = entry
        return entry

    getRuleById: (id) ->
        return @callRuleFactory id

    getRulesByTag: (tag, arrayMode) ->
        rulesForTag = @ruleTags[tag]
        unless rulesForTag?
            debug "no rules for tag: #{tag}\n#{inspect @ruleTags}"
            return if arrayMode is true then [] else {}

        # return as array = [{targets, dependencies, actions}, {targets, dependencies, actions}]
        if arrayMode? and arrayMode is true
            return (@callRuleFactory rule for rule in rulesForTag)

        # return as pairs = id:{targets, dependencies, actions}
        return @getRules rulesForTag

    callRuleFactory: (id) ->
        @factoryOrder.push id

        wrapper = @ruleFactories[id]
        unless wrapper
            debug "no rule defined for id: #{id}"
            return {}

        if wrapper.processed is true

            return wrapper.factory()

        if wrapper.init is true
            throw new Error "circular dependency found for id: #{id}\nbuild order: #{@factoryOrder.join ' -> '}"

        wrapper.init = true
        tuple = undefined
        try
            tuple = wrapper.factory() # targets, dependencies, actions
        catch err
            err.message = "RuleBook factory failed for rule #{id}: #{err.message}"
            throw err

        resolvedObject = {}
        for key of tuple
            if _(tuple[key]).isArray()
                resolvedObject[key] = _(tuple[key]).flatten()
            else
                resolvedObject[key] = tuple[key]

            # add this value to the (targets, dependencies, actions) tupel
            # when access to getRule()
            resolvedObject["tags"] = wrapper.tags
            resolvedObject["global"] = wrapper.global

        wrapper.factory = ->
            resolvedObject

        wrapper.processed = true

        return resolvedObject

module.exports = RuleBook
