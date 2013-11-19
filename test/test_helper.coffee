# Std library
fs = require 'fs'
path = require 'path'
{spawn} = require('child_process')

# Third party
async = require 'async'
{expect} = require 'chai'
debug = require('debug')('test-helper')
{Sink} = require 'pipette'

# Local dep
{findProjectRoot, locateNodeModulesBin} = require '../src/file-locator'

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
        "#{env.libPath}/views/demo.jade"
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
    debug 'lake test started ...'
    arg = [target]

    async.waterfall [

        (cb) ->
            findProjectRoot cb

        (projectRoot, cb) ->
            locateNodeModulesBin (err, binPath) ->
                cb err, projectRoot, binPath

        (projectRoot, binPath, cb) ->
            env.libPath = path.join projectRoot, env.libPrefix, env.name
            # TODO: refactor, extract names
            localMake = path.join binPath, '..', '..', '..', 'bin', 'lake'
            console.log "spawning #{localMake}"
            opt = {cwd: env.libPath}

            lmake = spawn localMake, arg, opt
            lmake.on 'error', (err) ->
                console.error "failed to spawn #{localMake}"
            output = []
            lmake.stdout.on 'data', (data) ->
                output.push data
            lmake.stderr.on 'data', (data) ->
                output.push data

            debug "lake spawned with args: #{arg} and cwd: #{opt.cwd}"
            #lmake.stdout.pipe(process.stdout, { end: false })
            lmake.on 'exit', (exitCode) ->
                if exitCode isnt 0
                    process.stdout.write o for o in output
                cb(null, exitCode)

        (exitCode, cb) ->
            unless exitCode is 0
                throw new Error "make exited with #{exitCode}"

            fs.stat (path.join env.libPath, "build"), cb

        (stat, cb) ->
            expect(stat.isDirectory()).to.be.equal(true)
            cb()

    ], outerCb
