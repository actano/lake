# Std library
{inspect} = require 'util'

# Third party
debug = require('debug')('lake.rulebook')
{_} = require 'underscore'

class RuleBook

    constructor: ->
        @ruleFactories = {} # key-value pairs: ruleId -> rule
        @ruleTags = {} # key-value pairs: tagName -> rule
        @factoryOrder = [] # show order if circular dependency is found
        @closed = false

    addToGlobalTarget: (targetName, factory) ->
        debug "adding globalTargets: #{targetName}"
        factory.globalTargets.push targetName

    # this method actually adds a FACTORY for a rule
    addRule: (id, tags, factoryFunction) ->
        if @closed
            throw new Error 'RuleBook is already closed, ' +
                'you can\'t add rules anymore'

        debug "adding factory #{id}"
        if @ruleFactories[id]?
            throw new Error "factory already exists with id: #{id}"

        tags or= []
        # add the tags of the factory to the tag database
        for tag in tags
            tagList = @ruleTags[tag] or= [] # init if null
            tagList.push id

        # init factory, add properties for resolving later
        factory = {
            tags: tags
            globalTargets: []
            _build: factoryFunction
            _init: false
            _processed: false
        }

        @ruleFactories[id] = factory
        return factory # unresolved factory (factory not called yet)

    getRuleById: (id, defaultValue = null) ->
        return @_getOrResolve id, defaultValue

    getRulesByTag: (tag, arrayMode = true) ->
        rulesForTag = @ruleTags[tag]
        unless rulesForTag?
            debug "no rules for tag: #{tag}\n#{inspect @ruleTags}"
            return if arrayMode is true then [] else {}

        # return as list = [rule1, rule2, ...]
        if arrayMode is false
            return @getRules rulesForTag

        # return as pairs = ruleId -> rule
        return (@_getOrResolve rule for rule in rulesForTag)

    close: ->
        @closed = true

    getRules: (factoryIds) ->
        factoryIds or= (key for key of @ruleFactories)
        debug "getting #{factoryIds}"
        factories = {}
        for id in factoryIds
            debug id
            factories[id] = @_getOrResolve id

        # return the factories: id -> {targets, dependenceis, actions}
        return factories

    _getOrResolve: (id, defaultValue) ->
        factory = @ruleFactories[id]
        unless factory
            debug "no factory defined for id: #{id}"
            return defaultValue

        # factory is already resolved, don't resolve it again
        if factory._processed is true
            return factory._build()

        if @closed is false
            throw new Error 'close the RuleBook before using it'

        if factory._init is true
            error = new Error 'circular dependency found for id: ' +
                "#{id}\nbuild order: #{@factoryOrder.join ' -> '}"
            error.code = 'CIRCULAR'
            throw error

        factory._init = true
        rule = undefined

        #try
        @factoryOrder.push id
        rule = factory._build() # {targets, dependencies, actions}

        ###
        catch err
            parentError = new Error("RuleBook failed for factory #{id}: #{err}")
            if err.root?
                parentError.root = err.root
            else
                parentError.root = err
            parentError.next = err
            throw parentError
        ###

        for key of rule
            if _(rule[key]).isArray()
                # if nested array, make it flat
                rule[key] = _(rule[key]).flatten()

        # copy tags and globalTargets
        # because isn't generated by the factory
        rule.tags = factory.tags
        rule.globalTargets = factory.globalTargets

        factory._processed = true
        factory._init = false

        factory._build = -> rule
        return rule

module.exports = RuleBook