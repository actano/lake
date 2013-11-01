# Std library
path = require 'path'
fs = require 'fs'
{exec} = require 'child_process'
{inspect} = require 'util'

# Third party
carrier = require 'carrier'
async = require 'async'
nopt = require 'nopt'
debug = require('debug')('makefile2dot')
{_} = require 'underscore'

makeDotFile = (inputFile, outputFile, args) ->
    inputStream = fs.createReadStream inputFile, {encoding: 'utf8'}
    graph =
        foo: []
        currentId: undefined

    carrier.carry inputStream, (line) =>
        parse line

    inputStream.on 'end', ->
        #console.log graph.foo

        buffer = ' digraph Makefile {\n   '
        #buffer += '   nodesep=0.7\n   '
        lines = graph.foo.join '\n   '
        buffer += lines
        buffer += '\n}'

        if args.onlydot
            fs.writeFileSync outputFile, buffer
        else
            unless args.algo?
                args.algo = 'dot'
            unless args.output?
                args.output = 'pdf'

            dotFile = "#{outputFile}.dot"
            fs.writeFileSync dotFile, buffer
            debug inspect args
            debug inspect args.algo

            command = "dot -K#{args.algo} -T#{args.output} " +
                "#{dotFile} -o #{outputFile}"
            debug "executing command: #{command}"
            exec command, (err, stdout, stderr) ->
                fs.unlinkSync dotFile

                if err?
                    console.log stderr
                    console.log stdout
                    console.log 'is graphvit installed ? ' +
                        '[http://www.graphviz.org/Download..php]'
                    return process.exit 1

                console.log stdout
                return process.exit 0

    inputStream.resume()

    parse = (line) ->
        patterns =
            id: /\s*#-\s*(.*)\s*/
            comment: /\s*#.*/
            action: /\t.*/
            assignment: /\s*(.*)\s*(:=)\s*(.*)\s*/
            rule: /\s*(.*)\s*(:)\s*(.*)\s*/
            include: /\s*include\s*(.*)/


        for key, pattern of patterns
            matchResult = line.match pattern
            #console.log "#{key} : #{matchResult}"

            if matchResult?
                switch key
                    when 'id'
                        return processLakeId matchResult[1]
                    when 'comment' then return
                    when 'action' then return
                    when 'assignment'
                        return processAssigment matchResult[1], matchResult[3]
                    when 'rule'
                        return processRule matchResult[1], matchResult[3]
                    when 'include'
                        return processInclude matchResult[1]
                    else return

        #console.log '------------'


    processInclude = (path) ->
        #TODO: implement it
        debug "include not implemented: #{path}"


    processAssigment = (left, right) ->
        # TODO: implement it
        debug "assigment not implemented: #{left} := #{right}"

    processLakeId = (id) ->
        graph.currentId = id

    processRule = (targets, depenencies) ->
        targets = targets.split ' '
        depenencies = depenencies.split ' '
        for target in targets
            for depenency in depenencies
                if depenency is ''
                    debug "#{target} has no dependency"

                if graph.currentId?
                    graph.foo.push "\"#{target}\" -> \"#{depenency}\" " +
                        "[label=\"#{graph.currentId}\"]"
                else
                    graph.foo.push "\"#{target}\" -> \"#{depenency}\""

        graph.currentId = undefined


if require.main is module

    knownOpts =
        help : Boolean
        output: ['pdf', 'png', 'gif', 'jpg', 'eps', 'svg']
        algo: ['dot', 'neato', 'twopi', 'fdp', 'circo']
        onlydot: Boolean

    shortHands =
        h: ['--help']
        d: ['--algo', 'dot']
        t: ['--algo', 'twopi']
        c: ['--algo', 'circo']
        f: ['--algo', 'fdp']
        n: ['--algo', 'neato']
        o: ['--onlydot']

    parsedArgs = nopt(knownOpts, shortHands, process.argv, 2)

    [inputFile, outputFile] = parsedArgs.argv.remain

    if not (inputFile? and outputFile?) or parsedArgs.help?
        console.log 'inputFile outputFile [--?] '
        console.log inspect shortHands
        console.log inspect knownOpts
        return process.exit 0


    makeDotFile inputFile, outputFile, parsedArgs
