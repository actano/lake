{exec, spawn} = require 'child_process'
carrier = require 'carrier'
events = require 'events'

# thisis way faster that the npm module 'glob'
class Glob extends events.EventEmitter
    constructor: (pattern, excludePattern, options) ->
        bashCommand = "ls #{pattern}"
        if excludePattern?.length
            bashCommand += "|grep -v #{excludePattern}"
        ls = spawn "bash", ['-c', bashCommand], options
        carrier.carry ls.stdout, (line) =>
            this.emit 'match', line

        ls.on 'close', (exitCode) =>
            if exitCode is 0 or exitCode is 1
                this.emit 'end', null
            else
                this.emit 'end', new Error "ls exited with code #{exitCode}"

module.exports = Glob