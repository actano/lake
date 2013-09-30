path = require 'path'
fs = require 'fs'
{_} = require 'underscore'
js2coffee = require 'js2coffee'
nopt = require 'nopt'
{inspect} = require 'util'
async = require 'async'
debug = require('debug')('lake.manifest-migration')

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
        console.log "finihsed"
        process.exit 0

foobar = (manifest, outputFile, outerCb) ->
    migration = module.exports.migration

    header = migration.header
    eval header # eval the header variables to provide access to the factory closure

    async.waterfall [

        (cb) ->
            fs.writeFile outputFile, header, cb

        (cb) ->
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
            fs.appendFile outputFile, "module.exports = ", cb

        () ->
            manifestAsString = JSON.stringify manifest, null, 4
            fs.appendFile outputFile, manifestAsString, 'utf8', outerCb
    ]


module.exports.migration =
    header: """JADE_TEMPLATES = ["views/markup.jade", "../testlmake-dep/views/page.jade"]
            WIDGET_TEMPLATES = ["views/markup.jade", "../testlmake-dep/views/widget.jade"]\n\n
            """
    actions: -> [
        copy:
            from: "server.scripts.files"
            to: "server.scripts"
    ,
        copy:
            from: "server.tests.integration"
            to: "integrationTests.mocha"
    ,
        copy:
            from: "server.tests.unit"
            to: "server.tests"
    ,
        copy:
            from: "htdocs.page"
            # the value is obj: {html, ...} html is a array with one element
            # it must be converted into a string: join('')
            to: ({html}) -> "htdocs.#{path.basename(html.join(''), path.extname(html.join('')))}"
    ,
        create:
            condition: "htdocs.widget"
            key: "htdocs.widget.dependencies"
            content:
                templates: WIDGET_TEMPLATES
    ,
        create:
            condition: "htdocs.index"
            key: "htdocs.index.dependencies"
            content:
                templates: JADE_TEMPLATES
    ,
        create:
            condition: "htdocs.demo"
            key: "htdocs.demo.dependencies"
            content:
                templates: JADE_TEMPLATES
    ,

        create:
            key: "client.tests.browser.dependencies"
            content: JADE_TEMPLATES
    ,
        create:
            key: "client.tests.browser.assets"
            content:
                styles:
                    ["__NODE_MODULES__/mocha/mocha.css"]
                scripts:
                    ["__NODE_MODULES__/mocha/mocha.js",
                     "__NODE_MODULES__/chai/chai.js",
                     "__PROJECT_ROOT__/vendor/sinon-1.7.3.js",
                     "__PROJECT_ROOT__/vendor/jquery-1.10.2.js"
                    ]
    ,
        delete: "client.views"
    ,
        delete: "htdocs.page"
    ,
        delete: "library"
    ,
        delete: "client.tests.browser.preequisits"
    ,
        delete: "client.tests.mocha"
    ]



knownOpts = {
    name: String
    output: String
    scan: Boolean
    help: Boolean
    exclude: String
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

    queue = async.queue (manifestFile, cb) ->
        directory = path.dirname manifestFile
        manifest = require path.resolve manifestFile
        foobar manifest, path.resolve(directory, parsed.output), cb
    , 1

    globber = new Glob "#{featurePath}/**/#{parsed.name}", parsed.exclude, {cwd: process.cwd()}
    globber.on 'match', (manifestFile) ->
        directory = path.dirname manifestFile
        queue.push manifestFile, (err) ->
            if err? then errors.push err
            console.log "# migrated #{directory}"

    globber.on 'end', (err) ->
        if err? then errors.unshift err

    queue.drain = ->
        console.log 'migration finished'
        finish errors


else
    manifest = require path.resolve featurePath, parsed.name
    foobar manifest, path.join(featurePath, parsed.output), (err) ->
        if err?
            finish [err]
