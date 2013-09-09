app = require '../server'

request = require 'supertest'
{expect} = require 'chai'
{inspect} = require 'util'

{findProjectRoot, locateNodeModulesBin} =  require '../../file-locator'
path = require 'path'
{spawn} = require 'child_process'
async = require 'async'
debug = require('debug')('actano.rplanx.create_local_make_inc-test')
fs = require 'fs'

testcases = require '../../test/test_helper'

env =
    name: 'testlmake'
    library: true
    libPrefix: 'lib'
    depName: 'testlmake-dep'
    transDepName: 'testlmake-trans-dep'


describe 'testlmake feature dependencies', ->

    beforeEach (done) ->
        async.waterfall [

            (cb) ->
                findProjectRoot cb

            (projectRoot, cb) ->

                transDepFeaturePath = path.join projectRoot, env.libPrefix, env.transDepName
                stylusFile = path.join transDepFeaturePath, "styles", "#{env.transDepName}.styl"
                stylusFileTemplateFile = path.join transDepFeaturePath, "styles", "#{env.transDepName}_template.styl"

                fileContent = fs.readFileSync stylusFileTemplateFile, 'utf8'
                fs.writeFileSync stylusFile, fileContent

                dummyPartialFile = path.join transDepFeaturePath, "views", "dummy-partial.jade"
                fs.writeFileSync dummyPartialFile, ".empty= key\n"

                moduleContent = """
                module.exports =
                    key: 'hi'
                """
                moduleFile = path.join transDepFeaturePath, "trans_module.coffee"
                fs.writeFileSync moduleFile, moduleContent

                libPath = path.join projectRoot, env.libPrefix, env.name

                browserTestFile = path.join libPath, "test", "testlmake-browser.coffee"
                browserTestTemplateFile = path.join libPath, "test", "testlmake-browser_template.coffee"

                fileContent = fs.readFileSync browserTestTemplateFile, 'utf8'
                fs.writeFileSync browserTestFile, fileContent
                cb()

        ], done

    # TODO: make a real test
    it 'should return a friendly message from the route /helloworld', (done) ->
        request(app)
            .get('/testlmake')
            .end (err, res) ->
                expect(res.status).to.equal 200
                expect(res.body).to.exist
                expect(res.body.message).to.exist
                expect(res.body.message).to.be.a 'string'
                expect(res.body.message).to.equal 'Hello World'
                done(err)

    it 'call lmake with test target (all test types)', (done) ->
        @timeout(15000)

        debug 'lmake test started ...'

        testcases.lmake env, 'client_test', done



    it 'modify stylus source of depended features, recompile and test', (done) ->
        @timeout(15000)

        async.waterfall [

            (cb) ->
                findProjectRoot cb

            (projectRoot, cb) ->

                transDepFeaturePath = path.join projectRoot, env.libPrefix, env.transDepName
                stylusFile = path.join transDepFeaturePath, "styles", "#{env.transDepName}.styl"

                content = """
                          .testlmake.modify ul.content
                              white-space: pre-line
                          """
                fs.appendFile stylusFile, content, (err) ->
                    if err? then console.log err

                    expect(err).to.be.null
                    debug "stylus written"
                    cb(null, projectRoot)

            (projectRoot, cb) ->
                debug "write browser test ..."

                content = """
                \tit 'test css from a dependency after the it was modified', (done) ->
                \t\tlist = $('.testlmake.modify ul.content')
                \t\twhiteSpace = list.css('white-space')
                \t\texpect(whiteSpace).to.be.equal('pre-line')
                \t\tdone()
                          """

                content = content.replace(/\t/g, '    ')

                libPath = path.join projectRoot, env.libPrefix, env.name
                browserTestFile = path.join libPath, "test", "testlmake-browser.coffee"

                fs.appendFile browserTestFile, content, (err) ->
                    if err? then console.log err

                    expect(err).to.be.null
                    cb()

            (cb) ->

                testcases.lmake env, 'client_test', cb

        ], done


    it 'modify a jade sources of depended features, recompile and test', (done) ->
        @timeout(15000)
        debug 'modify some files now'

        async.waterfall [

            (cb) ->
                findProjectRoot cb

            (projectRoot, cb) ->

                transDepFeaturePath = path.join projectRoot, env.libPrefix, env.transDepName
                dummyPartialFile = path.join transDepFeaturePath, "views", "dummy-partial.jade"

                content = """
                          .helloClass hi
                          """
                fs.appendFile dummyPartialFile, content, (err) ->
                    if err? then console.log err

                    expect(err).to.be.null
                    debug "jade written"
                    cb(null, projectRoot)

            (projectRoot, cb) ->
                debug "write browser test ..."

                content = """
                \tit 'test markup of a dependency after it was modified', (done) ->
                \t\thellodiv = $('.helloClass')
                \t\texpect(hellodiv.text()).to.be.equal('hi')
                \t\tdone()
                          """

                content = content.replace(/\t/g, '    ')

                libPath = path.join projectRoot, env.libPrefix, env.name
                browserTestFile = path.join libPath, "test", "testlmake-browser.coffee"

                fs.appendFile browserTestFile, content, (err) ->
                    if err? then console.log err

                    expect(err).to.be.null
                    cb()

            (cb) ->

                testcases.lmake env, 'client_test', cb

        ], done

    it 'modify a the required module source of depended features, recompile and test', (done) ->
        @timeout(15000)

        async.waterfall [

            (cb) ->
                findProjectRoot cb

            (projectRoot, cb) ->

                transDepFeaturePath = path.join projectRoot, env.libPrefix, env.transDepName
                moduleFile = path.join transDepFeaturePath, "trans_module.coffee"

                moduleContent = """
                module.exports =
                    key: 'I am here'
                """

                fs.writeFile moduleFile, moduleContent, {flags:'w'}, (err) ->
                    if err? then console.log err

                    expect(err).to.be.null
                    debug "jade written"
                    cb(null, projectRoot)

            (projectRoot, cb) ->
                debug "write browser test ..."

                content = """
                \tit 'test markup of a dependency after it was modified', (done) ->
                \t\thellodiv = $('.empty')
                \t\texpect(hellodiv.text()).to.be.equal('I am here')
                \t\tdone()
                          """

                content = content.replace(/\t/g, '    ')

                libPath = path.join projectRoot, env.libPrefix, env.name
                browserTestFile = path.join libPath, "test", "testlmake-browser.coffee"

                fs.appendFile browserTestFile, content, (err) ->
                    if err? then console.log err

                    expect(err).to.be.null
                    cb()

            (cb) ->

                testcases.lmake env, 'client_test', cb

        ], done

    after (done) ->
        async.waterfall [

            (cb) ->
                findProjectRoot cb

            (projectRoot, cb) ->

                transDepFeaturePath = path.join projectRoot, env.libPrefix, env.transDepName
                stylusFile = path.join transDepFeaturePath, "styles", "#{env.transDepName}.styl"
                stylusFileTemplateFile = path.join transDepFeaturePath, "styles", "#{env.transDepName}_template.styl"

                fileContent = fs.readFileSync stylusFileTemplateFile, 'utf8'
                fs.writeFileSync stylusFile, fileContent

                dummyPartialFile = path.join transDepFeaturePath, "views", "dummy-partial.jade"
                fs.writeFileSync dummyPartialFile, ".empty= key\n"

                moduleContent = """
                module.exports =
                    key: 'hi'
                """
                moduleFile = path.join transDepFeaturePath, "trans_module.coffee"
                fs.writeFileSync moduleFile, moduleContent

                libPath = path.join projectRoot, env.libPrefix, env.name

                browserTestFile = path.join libPath, "test", "testlmake-browser.coffee"
                browserTestTemplateFile = path.join libPath, "test", "testlmake-browser_template.coffee"

                fileContent = fs.readFileSync browserTestTemplateFile, 'utf8'
                fs.writeFileSync browserTestFile, fileContent
                cb()

        ], done

