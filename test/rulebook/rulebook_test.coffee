rules = require './rules'
circularRules = require './circular_rules'
RuleBook = require '../../src/rulebook'
{inspect} = require 'util'

{expect} = require 'chai'

projectRoot = "/Users/joe/projectX"
featurePath = "lib/fooBarFeature"
manifest =
    client:
        main: "main.coffee"
    license: "MIT"

describe 'rulebook', ->

    it 'resolved the rules', (done) ->
        ruleBook = new RuleBook()

        ruleList = rules.addRules {projectRoot, buildDir: 'build'}, featurePath, manifest, ruleBook

        # add rules into ruleBook
        ruleBook.add id,wrapper for id, wrapper of ruleList

        ruleBook.resolveAllFactories()

        done()

    it 'throws exception on circular dependencies', (done) ->
        ruleBook = new RuleBook()

        ruleList = circularRules.addRules {projectRoot, buildDir: 'build'}, featurePath, manifest, ruleBook

        # add rules into ruleBook
        ruleBook.add id,wrapper for id, wrapper of ruleList

        # evaluate the rules, call 'factory()'
        errorMessage = "circular dependency found for id: rule3\nbuild order: rule1 -> rule3 -> rule2 -> rule2false -> rule3"
        # TODO: how to expect an error with a specific message
        expect(->
            ruleBook.resolveAllFactories()
        ).to.throw()



        done()