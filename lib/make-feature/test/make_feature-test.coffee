fs = require 'fs'
path = require 'path'
{exec, execFile, spawn} = require('child_process')
async = require 'async'
request = require 'superagent'
phantom = require 'phantom'
{expect} = require 'chai'
{inspect} = require 'util'
carrier = require 'carrier'
{findProjectRoot} = require '../../lib/file-locator'
testcases = require './testcases'

makeFeatureScript = path.join __dirname, '..', 'make_feature.coffee'

env =
    name: 'testfeature'
    library: true

before (done) ->
    findProjectRoot (err, projectRoot) ->
        env.libPath = path.join projectRoot, 'lib', env.name
        done()

# test object, which will be exported
tests = {}

describe "the boilerplate code generator ", ->

    it "throws exit code 1 and prints help when called with no parameters", (done) ->
        exec makeFeatureScript, (err, stdout)->
            expect(err.code).to.equal(1)
            expect(stdout).to.have.string("Usage: make_feature.coffee <name>")

            done()

    it "creates a folder with the given feature name", (done) ->
        exec "#{makeFeatureScript} #{env.name}", (err)->
            expect(err).to.be.equal(null)
            fs.stat env.libPath, (err,stat) ->
                expect(err).to.be.equal(null)
                expect(stat.isDirectory()).to.be.equal(true)
                done()

    it "creates a list of files", (done) ->

        testcases.files env, done

describe "the generated Manifest.coffee", ->

    it "exports an object that has basic properties set", (done)->

        manifest = require("#{env.libPath}/Manifest.coffee")
        testcases.manifest manifest, env, done

module.exports = tests

describe "the local-make", ->

    it "compiles the files into the build dir and run all tests with 'test' target", (done) ->

        @timeout(10000)
        testcases.lmake env, 'test', done


    after ->
        exec "rm -rf #{env.libPath}", (err)->
            console.log err





