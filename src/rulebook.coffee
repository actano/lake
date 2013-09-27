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

        @ruleFactories[id] = _(wrapper).extend {init: false, processed: false}


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
            #TODO: discuss if execption should be thrown or not
            throw new Error "no rule defined for id: #{id}"

        if wrapper.processed is true

            return wrapper.factory()

        if wrapper.init is true
            throw new Error "circular dependency found for id: #{id}\nbuild order: #{@factoryOrder.join ' -> '}"

        wrapper.init = true
        tupel = undefined
        try
            factoryParams = null
            if wrapper.factoryParams?
                if _(wrapper.factoryParams).isFunction()
                    factoryParams = wrapper.factoryParams()
                else
                    factoryParams = wrapper.factoryParams

            tupel = wrapper.factory(factoryParams) # targets, dependencies, actions

        catch err
            err.message = "RuleBook factory faild for rule #{id}: #{err.message}"
            throw err

        resolvedObject = {}
        for key in Object.keys tupel
            if _(tupel[key]).isArray()
                resolvedObject[key] = _(tupel[key]).flatten()
            else
                resolvedObject[key] = tupel[key]

            # add this value to the (targets, dependencies, actions) tupel
            # when access to getRule()
            resolvedObject["tags"] = wrapper.tags
            resolvedObject["global"] = wrapper.global

        wrapper.factory = ->
            resolvedObject

        wrapper.processed = true

        return wrapper.factory()

module.exports = RuleBook
