{inspect} = require 'util'
debug = require('debug')('lake.rulebook')
{_} = require 'underscore'

class RuleBook

    constructor: ->
        @ruleFactories = {} # id: factory func
        @ruleTags = {} # tag: ["ruleId1", "ruleId2"]
        @factoryOrder = [] # [id1, id4, id2, id3] # show if circular dependency is found

    getRules: (rulesIds = Object.keys(@ruleFactories)) ->
        rules = {}
        rules[id] = @ruleFactories[id].factory() for id in rulesIds
        return rules # return the rules = id: {targets, dependenceis, actions}

    resolveAllFactories: ->
        for id, container of @ruleFactories
            @callRuleFactory id

    add: (id, wrapper) ->
        if @ruleFactories[id]?
            throw new Error "rule already exists with id: #{id}"

        if wrapper.condition? and wrapper.condition is false
            return

        wrapper.tags or= []

        for tag in wrapper.tags
            tagList = @ruleTags[tag] or= [] # init if null
            tagList.push id

        @ruleFactories[id] =
            factory: wrapper.factory
            factoryParams: wrapper.factoryParams
            tags: wrapper.tags
            init: false
            processed: false


    getRuleById: (id) ->
        return @callRuleFactory id

    getRulesByTag: (tag, arrayMode) ->
        rulesForTag = @ruleTags[tag]
        unless rulesForTag?
            throw new Error "no rules for tag: #{tag}\n#{inspect @ruleTags}"

        # return as array = [{targets, dependencies, actions}, {targets, dependencies, actions}]
        if arrayMode? and arrayMode is true
            return (@callRuleFactory rule for rule in rulesForTag)

        # return as pairs = id:{targets, dependencies, actions}
        return @getRules rulesForTag

    callRuleFactory: (id) ->
        @factoryOrder.push id

        wrapper = @ruleFactories[id]
        unless wrapper
            throw new Error "no rule defined for id: #{id}"

        if wrapper.processed is true

            return wrapper.factory()

        if wrapper.init is true
            throw new Error "circular dependency found for id: #{id}\nbuild order: #{@factoryOrder.join ' -> '}"

        wrapper.init = true
        tupel = undefined
        if wrapper.factoryParams?
            console.log "id: #{id} has params for factory(#{wrapper.factoryParams})"
            tupel = wrapper.factory(wrapper.factoryParams)
        else
            tupel = wrapper.factory() # targets, dependencies, actions

        resolvedValues = {}
        for key in Object.keys tupel
            if _(tupel[key]).isArray()
                resolvedValues[key] = _(tupel[key]).flatten()
            else
                resolvedValues[key] = tupel[key]

            resolvedValues["tags"] = wrapper.tags

        wrapper.factory = ->
            resolvedValues

        wrapper.processed = true

        return wrapper.factory()

module.exports = RuleBook
