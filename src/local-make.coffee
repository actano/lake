path = require 'path'
{spawn} = require 'child_process'

{findProjectRoot} = require('./file-locator')

module.exports.build = build = ->
    projectRoot = findProjectRoot()
    featurePath = path.relative projectRoot, process.cwd()

    console.log '------------------------------'
    console.log "project root is #{projectRoot}"

    target = process.argv[2]
    if target
        target = path.join featurePath, target
    else
        target = featurePath

    args = ['-C', projectRoot]
    if target
        console.log "building '#{target}'"
        args.push target
    else
        console.log 'building default target'

    make = spawn 'make', args
    make.stdout.pipe process.stdout
    make.stderr.pipe process.stderr
    make.on 'close', (exitCode) ->
        console.log '------------------------------'
        if exitCode isnt 0
            console.log "make exit code is #{exitCode}"
            process.exit exitCode

        console.log 'done'
        process.exit exitCode

if require.main is module
    build()