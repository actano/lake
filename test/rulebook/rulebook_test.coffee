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

        rules.addRules
            projectRoot: projectRoot
            buildDir: 'build'
        , featurePath, manifest, ruleBook

        ruleBook.close()
        ruleBook.getRules()

        # don't throw an exception
        done()

    it 'throws exception on circular dependencies', (done) ->
        ruleBook = new RuleBook()

        circularRules.addRules
            projectRoot: projectRoot
            buildDir: 'build'
        , featurePath, manifest, ruleBook
        ruleBook.close()

        # evaluate the rules, call 'factory()'
        errorMessage = 'circular dependency found for id: rule3\n' +
        'build order: rule1 -> rule3 -> rule2 -> rule2false'
        
        try
            ruleBook.getRules()
        catch err
            if err.root?
                expect(err.root.code).to.be.equal('CIRCULAR')
                expect(err.root.message).to.be.equal(errorMessage)
            else
                expect().fail()

        done()

    it 'called getRuleById multiple times', (done) ->
        rb = new RuleBook()
        rb.addRule 'rule1', [], ->
            targets: 'target'
            dependencies: 'dep'

        rb.addRule 'rule2', [], ->
            targets: rb.getRuleById('rule1').targets
            dependencies: 'depy'
        
        expect(->
            rb.getRuleById('rule2')
        ).to.throw('close the RuleBook before using it')

        done()


    it 'getRulesByTag return rules with the given tag', (done) ->
        rb = new RuleBook()
        rb.addRule 'rule1', ['foo'], ->
            targets: 'target'
            dependencies: 'dep'

        rb.addRule 'rule2', [], ->
            targets: 'target2'
            dependencies: rb.getRulesByTag('foo')[0].dependencies

        rb.close()

        rule1 = rb.getRuleById('rule1')
        expect(rule1.tags[0]).to.be.equal('foo')

        rule2 = rb.getRuleById('rule2')
        expect(rule2.dependencies).to.be.equal('dep')

        done()


    it 'addToGlobalTarget add a factory to a global target', (done) ->
        rb = new RuleBook()

        factory1 = rb.addRule 'rule1', [], ->
            targets: 'target1'
            dependencies: 'dep1'

        rb.addToGlobalTarget 'globalFoo', factory1
        rb.addToGlobalTarget 'globalBar', factory1

        rb.addToGlobalTarget 'globalFoo', rb.addRule 'rule2', [], ->
            targets: 'target2'
            dependencies: 'dep2'

        rb.close()

        rules = rb.getRules()
        expect(rules.length).to.be.not.equal(0)

        expect(rules['rule1'].globalTargets[0]).to.be.equal('globalFoo')
        expect(rules['rule2'].globalTargets[0]).to.be.equal('globalFoo')
        expect(rules['rule1'].globalTargets[1]).to.be.equal('globalBar')

        done()

    it 'fails if try to add a rule after closing the rulebook', (done) ->
        rb = new RuleBook()
        rb.addRule 'rule1', ['foo'], ->
            targets: 'target'
            dependencies: 'dep'

        rb.close()
        expect(->
            rb.addRule 'rule2', [], ->
                targets: 'target2'
                dependencies: 'dep2'
        ).to.throw('RuleBook is already closed, you can\'t add rules anymore')

        done()

    it 'factory._build() return a rule', (done) ->
        rb = new RuleBook()
        factory = rb.addRule 'rule', ['foo'], ->
            targets: 'target'
            dependencies: 'dep'

        rb.close()

        expect(factory.targets).to.be.equal(undefined)
        expect(factory.dependencies).to.be.equal(undefined)
        expect(factory._init).to.be.equal(false)
        expect(factory._processed).to.be.equal(false)

        # resolve factory
        rule = rb.getRuleById('rule')
        expect(factory._processed).to.be.equal(true)

        expect(rule.targets).to.be.equal('target')
        expect(rule.dependencies).to.be.equal('dep')

        sameRule = factory._build()
        expect(rule).to.be.eql(sameRule)

        done()


    it 'use nested arrays of strings which are flatten', (done) ->

        rb = new RuleBook()
        factory = rb.addRule 'rule', [], ->
            targets: [
                'target-1', [
                    'target-2-a'
                    'target-2-b'
                ], [
                    'target-3-a'
                    'target-3-b'
                ]
                'target-3'
            ]
            dependencies: ['dep-a', ['dep-b', ['dep-c']]]
            actions: 'action'

        rb.close()

        rule = rb.getRuleById('rule')
        expect(rule.targets).to.be.eql(
            ['target-1'
            'target-2-a'
            'target-2-b'
            'target-3-a'
            'target-3-b'
            'target-3'
            ])
        expect(rule.dependencies).to.be.eql(['dep-a', 'dep-b', 'dep-c'])
        done()

    #TODO: test .mk and Makefile output
    # -> refactor create_mk to pass a stream instead of a filepath
    #   -> better abstraction and testable