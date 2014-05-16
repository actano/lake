path = require 'path'
{spawn} = require 'child_process'
_ = require 'underscore'

{findProjectRoot} = require('./file-locator')

module.exports.build = ->
    target = process.argv[2] ? ''
    projectRoot = findProjectRoot()

    console.log '------------------------------'
    console.log "project root is #{projectRoot}"

    prefix = path.relative projectRoot, process.cwd()
    target = path.join prefix, target
    target = '' if target is '.'
    if target is ''
        console.log 'building default target'
    else
        console.log "building '#{target}'"

    args = _(['-C', projectRoot, target]).compact()
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
