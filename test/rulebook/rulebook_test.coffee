# Std library
fs = require 'fs'
path = require 'path'
{inspect} = require 'util'

# Third party
{expect} = require 'chai'
tmp = require 'tmp'
tmp.setGracefulCleanup()

# Local dep
rules = require './rules'
circularRules = require './circular_rules'
RuleBook = require '../../src/rulebook'
{writeToStream} = require '../../src/create_mk'
{writeMakefileToStream} = require '../../src/create_makefile'

# fake data
projectRoot = '/Users/joe/projectX'
featurePath = 'lib/fooBarFeature'
binPath = path.join projectRoot, 'node_modules/.bin'

manifest =
    client:
        main: 'main.coffee'
    license: 'MIT'

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
        rb.addRule 'rule', [], ->
            targets: [
                'target-1', [
                    'target-2-a'
                    'target-2-b'
                ], [
                    'target-3-a'
                    'target-3-b'
                ]
                'target-4'
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
            'target-4'
            ])
        expect(rule.dependencies).to.be.eql(['dep-a', 'dep-b', 'dep-c'])
        done()

    it 'write the .mk file from a rule to a stream', (done) ->
        rb = new RuleBook()
        rb.addRule 'rule_foo', [], ->
            targets: 'target1 target2'
            dependencies: ['dep1', 'dep2', 'dep3']
            actions: ['pwd', 'rm -rf /']

        rb.addRule 'rule_bar', [], ->
            targets: 'target0'
            dependencies: [rb.getRuleById('rule_foo').targets, 'target3']
            actions: 'clean'

        rb.close()

        expected = """
        # rule_foo
        target1 target2: dep1 dep2 dep3
        \tpwd
        \trm -rf /

        # rule_bar
        target0: target1 target2 target3
        \tclean\n\n
        """

        # resolve all factories
        rb.getRules()

        writeToStreamAndTest rb, (actual) ->
            expect(actual).to.be.equal(expected)
        , done

    it 'write the .mk and flatten nested arrays', (done) ->
        rb = new RuleBook()
        factory = rb.addRule 'rule_foobar', [], ->
            targets: [
                'target-1', [
                    'target-2-a'
                    'target-2-b'
                ], [
                    'target-3-a'
                    'target-3-b'
                ]
                'target-4'
            ]
            dependencies: ['dep-a', ['dep-b', ['dep-c']]]
            actions: 'action'

        rb.close()

        expected = """
        # rule_foobar
        target-1 target-2-a target-2-b target-3-a target-3-b target-4: """ +
        """dep-a dep-b dep-c
        \taction\n\n
        """

        writeToStreamAndTest rb, (actual) ->
            expect(actual).to.be.equal(expected)
        , done


    it 'test global Manifest generation', (done) ->

        lakeConfig =
            makeAssignments:
                TOOLS: '$(ROOT)/tools'
                COFFEEC: '$(NODE_BIN)/coffee'
                
            makeDefaultTarget:
                target: 'all'
                dependencies: 'build'

            globalRules: 'target: dep1 dep2\n\tpwd'

        mkFiles = [
            'mkFiles/lib/foo.mk'
            'mkFiles/lib/bar.mk'

        ]

        globalTargets =
            install: ['lib/foo/install', 'lib/bar/install']
            clean: ['lib/foo/clean', 'lib/bar/clean']

        expected = """
        ROOT := #{projectRoot}
        NODE_BIN := #{binPath}


        all: build

        include mkFiles/lib/foo.mk
        include mkFiles/lib/bar.mk

        install: lib/foo/install lib/bar/install
        clean: lib/foo/clean lib/bar/clean

        target: dep1 dep2
        \tpwd\n
        """

        tmp.file (err, file, fd) ->
            if err?
                console.err 'cannot create tmp.file'
                throw err

            stream = fs.createWriteStream file
            stream.on 'error', (err) ->
                console.error 'stream error'
                throw err

            stream.once 'finish', ->
                content = fs.readFileSync file, {encoding: 'utf8'}

                # ignore first 3 lines
                [first, second, empty, content...]= content.split('\n')
                content = content.join '\n'
                
                expect(content).to.be.equal(expected)
                done()

            writeMakefileToStream stream,
                lakeConfig, binPath, projectRoot, mkFiles, globalTargets
            stream.end()


writeToStreamAndTest = (rb, expectFactory, done) ->
    tmp.file (err, file, fd) ->
        if err?
            console.err 'cannot create tmp.file'
            throw err

        stream = fs.createWriteStream file
        stream.on 'error', (err) ->
            console.error 'stream error'
            throw err

        stream.once 'finish', ->
            content = fs.readFileSync file, {encoding: 'utf8'}
            expectFactory content
            done()

        writeToStream stream, rb, {}
        stream.end()