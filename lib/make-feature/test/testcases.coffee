async = require 'async'
fs = require 'fs'
path = require 'path'
{expect} = require 'chai'
debug = require('debug')('acano.rplanx.make-featre.testcases')
{findProjectRoot} = require '../../lib/file-locator'
{spawn} = require('child_process')


fileExists = (filePath, cb) ->
    fs.stat filePath, (err, stat) ->
        expect(err).to.be.equal(null)
        expect(stat.isFile()).to.be.equal(true)
        cb()

module.exports.files = (env, done) ->
    fileList = [
        "#{env.libPath}/Manifest.coffee"
        "#{env.libPath}/index.coffee"
        "#{env.libPath}/styles/#{env.name}.styl"
        "#{env.libPath}/views/#{if env.library then 'demo.jade' else 'index.jade'}"
        "#{env.libPath}/views/markup.jade"
        "#{env.libPath}/views/widget.jade"
        "#{env.libPath}/test/#{env.name}-unit.coffee"
        "#{env.libPath}/test/#{env.name}-browser.coffee"
        "#{env.libPath}/test/#{env.name}-integration.coffee"
        "#{env.libPath}/test/#{env.name}-phantom.coffee"
        "#{env.libPath}/test/test.jade"
    ]

    async.each fileList, (file, cb) ->
        fileExists file, cb
    , (err) ->
        expect(err).to.be.equal(null)
        debug 'file test passed'
        done()

module.exports.manifest =  (manifest, env, cb) ->
    expect(require("#{env.libPath}/Manifest.coffee")).to.be.an('object')
    expect(manifest.name).to.equal(env.name)
    expect(manifest.description).to.be.a('string')
    expect(manifest.license).to.be.a('string')
    expect(manifest.version).to.be.a('string')
    expect(manifest.keywords).to.be.an('array')
    expect(manifest.documentation).to.be.an('array')
    expect(manifest.library).to.be.a('boolean')
    expect(manifest.htdocs).to.be.an('object')
    expect(manifest.client).to.be.an('object')
    expect(manifest.server).to.be.an('object')
    expect(manifest.database).to.be.an('object')
    debug 'manifest test passed'
    cb()

module.exports.lmake = (env, target, outerCb) ->
    debug 'lmake test started ...'
    arg = [target]

    async.waterfall [

        (cb) ->
            findProjectRoot cb

        (projectRoot, cb) ->
            env.libPath = path.join projectRoot, env.libPrefix, env.name
            localMake = path.join projectRoot, 'tools', 'local-make'
            opt = {cwd: env.libPath}
            lmake = spawn localMake, arg, opt
            debug "lmake spawned with args: #{arg} and cwd: #{opt.cwd}"
            #lmake.stdout.pipe(process.stdout, { end: false });
            lmake.on 'exit', (exitCode) ->
                cb(null, exitCode)

        (exitCode, cb) ->
            unless exitCode is 0
                throw new Error "make exited with #{exitCode}"

            fs.stat (path.join env.libPath, "build"), cb

        (stat, cb) ->
            expect(stat.isDirectory()).to.be.equal(true)
            cb()

    ], outerCb
