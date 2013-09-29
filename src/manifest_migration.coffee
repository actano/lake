path = require 'path'
fs = require 'fs'
{_} = require 'underscore'


process = (manifest, outputFile) ->
    description = module.exports.migration()
    header = undefined
    keyName
    for element in description
        for value, action of element
            if action is "header"
                header = value
                # eval variables #TODO: test this works really? not onl yin REPL?
                eval header
            else
                retVal = action(manifest, value)
                if value.from?
                    keyName = value.from
                if value.key?
                    keyName = value.key
                else
                    keyName = value


                debug "migration for #{action}:#{keyName} was #{retVal}"

    #TODO: write manifest back to a file using heder and module.exports before

copy = (manifest, obj) ->
    from = obj.from
    to = obj.to
    content = lookup manifest, from
    if content?
        if _(to).isFunctino()
            return access manifest, to, {mode:"factory", content}
        else
            return access manifest, to, {mode:"create", content}

    return false

remove = (manifest, key) ->
    return access manifest, key, {mode:"delete"}

create = (manifest, obj) ->

    return access manifest, obj.key, {mode:"create", content: obj.content}

access = (context, key, opt) ->
    if key.indexOf('.') is -1
        if not context[key]?
            return false

        switch opt.mode
            when "delete" then remove context[key]
            when "create" then context[key] = opt.content
            when "factory" then context[key] = context[key](opt.content)
            when "fetch" then return context[key]
            else throw new Error "action for migration is invalid: #{opt}"

        return true

    else
        # if context had nested keys, use recursive strategy
        [firstKey, rest...] = key.split '.'

        if not context[firstKey]?
            return false

        return access context[firstKey], rest.join('.'), opt

module.exports.migration = [
    header: """JADE_TEMPLATES = ["views/markup.jade", "../testlmake-dep/views/page.jade"]
            WIDGET_TEMPLATES = ["views/markup.jade", "../testlmake-dep/views/widget.jade"]
            """
,
    copy:
        from: "server.scripts.files"
        to: "server.scripts"
,
    remove: "views"
,
    copy:
        from: "server.tests.unit"
        to: "server.tests"
,
    copy:
        from: "server.tests.integration"
        to: "integrationTests.mocha"
,
    copy:
        from: "htdocs.page"
        to: (htmlPage) -> "htdocs[#{path.basename(htmlPage.html.join'')}]"
,
    create:
        key: "htdocs.widget"
        content:
            dependencies:
                templates: WIDGET_TEMPLATES
,
    create:
        key: "htdocs.index"
        content:
            dependencies:
                templates: JADE_TEMPLATES
,
    create:
        key: "htdocs.demo"
        content:
            dependencies:
                templates: JADE_TEMPLATES
,
    remove: "library"
 ,
    remove: "client.tests.browser.preequisits"
 ,
    remove: "client.tests.mocha"
 ,
    create:
        key: "client.tests.browser"
        content:
            dependencies: JADE_TEMPLATES
 ,
    create:
        key: "client.tests.browser"
        content:
            assets:
                styles:
                    ["__NODE_MODULES__/mocha/mocha.css"]
                scripts:
                    ["__NODE_MODULES__/mocha/mocha.js",
                     "__NODE_MODULES__/chai/chai.js",
                     "__PROJECT_ROOT__/vendor/sinon-1.7.3.js",
                     "__PROJECT_ROOT__/vendor/jquery-1.10.2.js"
                    ]
]




