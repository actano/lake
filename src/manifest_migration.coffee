path = require 'path'
fs = require 'fs'
{_} = require 'underscore'
js2coffee = require 'js2coffee'
nopt = require 'nopt'
{inspect} = require 'util'
async = require 'async'
debug = require('debug')('lake.manifest-migration')
{exec, spawn} = require 'child_process'
{findProjectRoot, locateNodeModulesBin} = require './file-locator'

{replaceExtension} = require './rulebook_helper'
Glob = require './globber'

access = (context, key, opt) ->
    if key.indexOf('.') is -1
        if not context[key]?
            if opt.mode isnt "create"
                debug "key '#{key}' of #{context} not found"
                return null

        switch opt.mode
            when "delete" then delete context[key]
            when "create" then context[key] = opt.content
            when "fetch" then return context[key]
            else throw new Error "action key for migration is invalid: #{inspect opt}"

        return true

    else
        # if context had nested keys, use recursive strategy
        [firstKey, rest...] = key.split '.'

        if not context[firstKey]?
            if opt.mode is "create"
                context[firstKey] = {}
            else
                debug "key '#{key}' of #{context} not found"
                return null

    return access context[firstKey], rest.join('.'), opt

factory =
    copy: (manifest, obj) ->
        from = obj.from
        to = obj.to
        content = access manifest, from, {mode: "fetch"}
        if content?
            if _(to).isFunction()
                to = to(content)
                return access manifest, to, {mode:"create", content}
            else
                return access manifest, to, {mode:"create", content}

        debug "no content fonud for key '#{from}'"
        return null

    replace: (manifest, obj) ->
        param = access manifest, obj.key, {mode: "fetch"}
        content = obj.content param
        return access manifest, obj.key, {mode: "create", content}

    delete: (manifest, key) ->
        return access manifest, key, {mode:"delete"}

    create: (manifest, obj) ->
        return access manifest, obj.key, {mode:"create", content: obj.content}


finish = (err) ->
    if err? and err.length isnt 0
        for e in err
            console.error e
        process.exit 1

    else
        console.log "finished"
        process.exit 0

migrate = (manifest, outputFile, logKey, outerCb) ->

    header = undefined
    manifestJsFile = undefined

    if logKey?
        content = access manifest, logKey, {mode: "fetch"}
        console.log "#{manifest.name}:"
        console.dir content
        console.log ""
        return outerCb null

    async.waterfall [

        (cb) ->
            findProjectRoot cb

        (projectRoot, cb) ->
            lakeConfigPath = path.join projectRoot, ".lake", "config"

            unless (fs.existsSync lakeConfigPath)
                throw new Error "lake config not found at #{lakeConfigPath}"

            lakeConfig = require lakeConfigPath
            migrationFile = lakeConfig.manifestMigrationFile

            unless (migrationFile)
                throw new Error "lake config has no migration entry '#{manifestMigrationFile}'"

            migrationFile = path.join projectRoot, migrationFile
            unless (fs.existsSync migrationFile)
                throw new Error "migration file not found at #{migrationFile}"

            migration = require migrationFile


            header = migration.header
            eval header # eval the header variables to provide access to the factory closure

            cb null, migration

        (migration, cb) ->
            manifestJsFile = replaceExtension outputFile, '.js'
            fs.writeFile manifestJsFile, header, (err) ->
                cb err, migration

        (migration, cb) ->

            for element in migration.actions()
                for action, value of element
                    keyName = undefined
                    if value.from?
                        keyName = value.from
                    else if value.key?
                        keyName = value.key
                    else
                        keyName = value

                    if value.condition?
                        conditionResult = access manifest, value.condition, {mode: "fetch"}
                        debug "condition result: #{conditionResult}"
                        #debug "skipping, because key #{value.condition} doesn't exist"
                        if conditionResult is null
                            debug "skipping ..."
                            continue

                    retVal = factory[action](manifest, value)
                    console.log "#{if retVal? then 'ok' else 'failed'} for #{action} -> #{keyName}"

            # write manifest as javascript to a file, then convert with js2coffee
            fs.appendFile manifestJsFile, "module.exports = ", cb

        (cb) ->
            manifestAsString = JSON.stringify manifest, null, 4
            fs.appendFile manifestJsFile, manifestAsString, 'utf8', (err) ->
                cb err, manifestJsFile

        (manifestJsFile, cb) ->
            locateNodeModulesBin (err, nodeBin) ->
                cb err, manifestJsFile, nodeBin

        (manifestJsFile, nodeBin, cb) ->
            exec "#{path.join nodeBin, 'js2coffee'} #{manifestJsFile} > #{outputFile}", (err) ->
                cb err, manifestJsFile

        (manifestJsFile) ->
            fs.unlink manifestJsFile, outerCb

    ]


knownOpts = {
    name: String
    output: String
    scan: Boolean
    help: Boolean
    exclude: String
    log: String
}
shortHands = {
    "n" : ["--name", "Manifest.coffee"]
    "s" : ["--scan"]
    "o" : ["--output", "Manifest_dev.coffee"]
}

parsed = nopt(knownOpts, shortHands, process.argv, 2)

if parsed.argv.remain.length isnt 1
    console.log "[--#{Object.keys(knownOpts).join '] [--'}] manifestDirectory"
    console.log inspect(shortHands)
    process.exit 1

featurePath = parsed.argv.remain[0]
errors = []

if parsed.scan? and parsed.scan is true

    debug "scan is enabled"
    queue = async.queue (manifestFile, cb) ->
        directory = path.dirname manifestFile
        manifest = require path.resolve manifestFile

        migrate manifest, path.resolve(directory, parsed.output), parsed.log, cb
    , 1

    globber = new Glob "#{featurePath}/**/#{parsed.name}", parsed.exclude, {cwd: process.cwd()}
    globber.on 'match', (manifestFile) ->
        debug "found #{manifestFile}"
        directory = path.dirname manifestFile
        queue.push manifestFile, (err) ->
            if err?
                console.error "error occurs during globbing"
                errors.push err
            debug "pushed #{manifestFile}"

    globber.on 'end', (err) ->
        if err?
            console.error "error occurs at the end of globbing"
            errors.unshift err
        debug "globber stopped"

    queue.drain = ->
        debug "draining queue ..."
        finish errors


else
    manifest = require path.resolve featurePath, parsed.name
    migrate manifest, path.join(featurePath, parsed.output), null, (err) ->
        if err?
            finish [err]
