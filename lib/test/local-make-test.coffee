path = require 'path'
fs = require 'fs'
{exec, spawn} = require 'child_process'
async = require 'async'
debug = require('debug')('local-make.test')
{expect} = require 'chai'

makeFeature = require '../make-feature/make_feature'
testcases = require './test_helper'
{findProjectRoot} =  require '../file-locator'

env =
    name: 'my-funky_feature'
    library: true
    libPrefix: 'lib'

projectRoot = null

makeFeatureScript = '../make-feature/make_feature.coffee'

describe 'intergration test for create local makefile inc', ->

    before (done) ->
        findProjectRoot (err, pr) ->
            debug "found projectRoot: #{projectRoot}"
            projectRoot = pr
            env.libPath = path.join projectRoot, env.libPrefix, env.name
            done()

    it "throws exit code 1 and prints help when called with no parameters", (done) ->
        exec makeFeatureScript, (err, stdout)->
            expect(err.code).to.equal(1)
            expect(stdout).to.have.string("Usage: make_feature.coffee <name>")
            done()

    it "creates a folder actano-rplan/lib/ with the given feature name", (done) ->
        exec "#{makeFeatureScript} #{env.name}", (err)->
            expect(err).to.be.equal(null)
            fs.stat env.libPath, (err,stat) ->
                expect(err).to.be.equal(null)
                expect(stat.isDirectory()).to.be.equal(true)
                done()

    it "creates a list of files", (done) ->
        testcases.files env, done

    it 'remove the generated feature', (done) ->
        exec "rm -rf #{env.libPath}", (err) ->
            expect(err).to.be.equal null
            done()

describe 'integration test by makefeature API', ->

    it 'create-feature test pass', (done) ->
        @timeout(15000) # for `lmake test`

        async.waterfall [

            (cb) ->
                findProjectRoot cb
            (projectRoot, cb) ->
                debug "found projectRoot: #{projectRoot}"
                env.libPath = path.join projectRoot, env.libPrefix, env.name
                makeFeature env.name, env.libPrefix, 'for test', cb

            (cb) ->
                debug "check generated files"
                # test generated files
                testcases.files env, cb

            (cb) ->
                debug "check manifest file"
                # test properties of manifest file
                manifest = require("#{env.libPath}/Manifest.coffee")
                testcases.manifest manifest, env, cb

            (cb) ->
                debug "check lmake"
                # lmake with test target (client, integration)
                testcases.lmake env, 'test', cb

        ], ->
            console.log 'test finsihed'
            done()

    after (done) ->
        exec "rm -rf #{env.libPath}", (err)->
            console.error err
            done()
