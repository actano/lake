fs = require 'fs'
path = require 'path'
async = require 'async'
{_} = require 'underscore'
debug = require('debug')('lake.create_mk')


MANIFEST_FILE_NAME = "Manifest"
MAKEFILE_MK_NAME = "dev_Makefile.mk"
BUILD_SUFFIX = 'build'

# config key names, for better refactoring
CFG_CONDITION = "condition"
CFG_TARGET = "target"
CFG_DEPENDENCIES = "dependencies"
CFG_ACTIONS = "actions"
CFG_TARGET_REGEX = "targetRegex"
CFG_GLOBAL_TARGET = "globalTarget"
CFG_TARGET_AS_FIRST_DEP = "targetAsFirstDependency"
CFG_FIRST_DEPENDENCY = "firstDependecy"


projectRoot = undefined             # absolute path: /Users/john/projectX
absoluteFeaturePath = undefined     # absolute path: /Users/john/projectX/foo/bar/featureA
featurePath = undefined             # for example: foo/bar/featureA
featureBuildPath = undefined        # for example: foo/var/featureA/build
manifestPath = undefined            # for example: foo/bar/featureA/Manifest.coffee
manifest = undefined                # manifest object
rules = undefined                   # container objects for all rule configration

###
    last parameter (outerCb) is a callback with thre params (err, mkContent, globalTargets)
###
createLocalMakefileInc = (pr, fp, outerCb) ->
    projectRoot = pr
    absoluteFeaturePath = fp
    featurePath = path.relative projectRoot, absoluteFeaturePath
    featureBuildPath = path.join featurePath, BUILD_SUFFIX

    # check manifest
    absoluteManifestPath = path.join absoluteFeaturePath, MANIFEST_FILE_NAME
    manifestPath = path.relative projectRoot, absoluteManifestPath # relative manifest path
    try
        manifest = require absoluteManifestPath
    catch err
        console.error "#{MANIFEST_FILE_NAME} for #{featurePath} cannot be parsed: #{err.message}"
        throw err

    # Makfile rules

    componentPath = path.join featureBuildPath, "components"

    rules = {}
    rules["component.json"] =
        globaleTarget: true
        target: path.join featureBuildPath, "component.json"
        dependencies: manifestPath
        actions: [
            "mkdir -p #{featureBuildPath}"
            "$(COMPONENT_GENERATOR) $< $@"
        ]

    rules["build"] =
        target: () -> lookup manifest, 'description'
        dependencies: [
            () -> getTarget "component.json"
            () -> getTarget "component.install"
        ]
        actions: () -> keyValues manifest.client.dependencies.development.remote
         

    rules["component.install"] =
        target: () -> componentPath
        dependencies: path.join featureBuildPath, "component.json"
        actions: [
            "cd #{featureBuildPath} && $(COMPONENT_INSTALL) $(COMPONENT_INSTALL_FLAGS) || rm -rf #{componentPath}"
            "test -d #{componentPath}"
            "touch #{componentPath}"
        ]

    ###
       lib/planning-objects/integration_test: lib/planning-objects/build
        $(MOCHA) -R $(MOCHA_REPORTER) --compilers coffee:coffee-script lib/planning-objects/test/server-itest.coffee
        $(MOCHA) -R $(MOCHA_REPORTER) --compilers coffee:coffee-script lib/planning-objects/test/sorting-itest.coffee
        $(MOCHA) -R $(MOCHA_REPORTER) --compilers coffee:coffee-script lib/planning-objects/test/workpackage-itest.coffee
    ###

    rules["integration-test"] =
        condition: () ->  lookup manifest, 'integrationTest' # create the rule only if the manifest property exist, interpret error as false
        target: path.join featurePath ,'integration_test'
        dependencies: featureBuildPath
        actions: () ->
            _(lookup manifest, 'integrationTests.mocha').map (item) ->
                "$(MOCHA) -R $(MOCHA_REPORTER) --compilers coffee:coffee-script #{item}"




    ruleNameList = _(rules).keys()

    # parse the CFG_TARGET keys
    _(ruleNameList).each (ruleName) ->
        currentRule = rules[ruleName]
        condition = currentRule[CFG_CONDITION]
        if condition? and _(condition).isFunction()
            try
                if not condition()
                    error = new Error ""
                    error.code = FALSE_CONDITION
                    throw error
            catch err
                if err.code is 'KEY_NOT_FOUND' or err.code is 'FALSE_CONDITION'
                    debug "delete rule #{ruleName} because condition is false #{condition}"
                    ruleNameList = _(ruleNameList).without ruleName
                    return
                throw err

        target = currentRule[CFG_TARGET]
        result = undefined # evaluated target

        type = getType target

        if type is 'function'
            # check the type again after calling the function
            target = target()
            type = getType target

        if type is 'string'
            result = target

        else if type is 'array'
            result = target.join ' '

        else
            throwError "#{ruleName}.#{CFG_TARGET}", "string, array or function", type

        if currentRule[CFG_TARGET_AS_FIRST_DEP]?
            currentRule[CFG_FIRST_DEPENDENCY] = result # 

        if currentRule[CFG_TARGET_REGEX]?
            obj = currentRule[CFG_TARGET_REGEX]
            pattern = undefined
            replacement = undefined
            try
                pattern = obj.pattern
                replacement = obj.replacement
                if not pattern? and not replacement?
                    throw new Error ""
            catch err
                throwError "#{ruleName}.#{CFG_TARGET_REGEX}", "{pattern, replacement}", obj

            # TODO: let the user choose, if he wants replace only basename or fullname?
            dirName = path.dirname result
            fileName = path.baseneme result
            newFileName = fileName.replace pattern, replacement
            result = path.join dirName, newFileName

        currentRule[CFG_TARGET] = result


    # parse the CFG_DEPENDENCIES keys
    _(ruleNameList).each (ruleName) ->
        result = undefined # evaluated target
        currentRule = rules[ruleName]
        dependencies = currentRule[CFG_DEPENDENCIES]

        type = getType dependencies

        if type is 'function'
            # check the type again after calling the function
            dependencies = dependencies()
            type = getType dependencies

        if type is 'string'
            result = dependencies

        else if type is 'array'
            result = []
            # parse each array ruleName
            _(dependencies).each (element, index) ->
                dependency = element
                type = getType dependency
                if type is 'string'
                    result[index] = dependency
                else if type is 'function'
                    result[index] = dependency()
                else
                    throwError "#{ruleName}.#{CFG_DEPENDENCIES}.#{index}", "string or function", type
                
            result = result.join " "

        else 
            throwError "#{ruleName}.#{CFG_DEPENDENCIES}", "string, function, or array", type

        if currentRule[CFG_FIRST_DEPENDENCY]?
            result = currentRule[CFG_FIRST_DEPENDENCY] + " " + result

        currentRule[CFG_DEPENDENCIES] = result


    # parse the CFG_ACTIONS keys
    _(ruleNameList).each (ruleName) ->
        result = undefined # evaluated target
        currentRule = rules[ruleName]
        actions = currentRule[CFG_ACTIONS]
        if not actions?
            debug "no #{CFG_ACTIONS} defined for rule #{CFG_ACTIONS}"
            return

        type = getType actions

        if type is 'function'
            # check the type again after calling the function
            actions = actions()
            type = getType actions

        if type is 'string'
            result = actions

        else if type is 'array'
            result = []
            # parse each array element
            _(actions).each (element, index) ->
                action = element
                type = getType action
                if type is 'string'
                    result[index] = action
                else if type is 'function'
                    result[index] = action()
                else
                    throwError "#{ruleName}.#{CFG_ACTIONS}#{index}", "string or function", type
                
            result = result.join "\n\t"

        else 
            throwError "#{ruleName}.#{CFG_ACTIONS}", "string, function, or array", type

        currentRule[CFG_ACTIONS] = result


    console.log rules

    writeMkFile rules, ruleNameList, (err, relativeMkPath, globalTargets) ->
        if err?
            return outerCb err
        console.log "########################################"
        outerCb new Error "create_mk is not fully implemented"
        #outerCb err, relativeMkPath, globalTargets

writeMkFile = (rules, ruleNameList, cb) ->
    buffer = ""
    globalTargets = []
    _(ruleNameList).each (ruleName) ->
        localBuffer = ""
        currentRule = rules[ruleName]
        target = currentRule[CFG_TARGET]
        if currentRule[CFG_GLOBAL_TARGET]? and currentRule[CFG_GLOBAL_TARGET] is true
            globalTargets.push target
        dependencies = currentRule[CFG_DEPENDENCIES]
        actions = currentRule[CFG_ACTIONS]
        localBuffer 
        localBuffer += "# #{ruleName}\n"
        localBuffer += "#{target}: #{dependencies}\n"
        if actions?
            localBuffer += "\t#{actions}\n\n"
        else
            localBuffer += "\n"

        console.log localBuffer
        buffer += localBuffer


    mkFilePath = path.join projectRoot, featurePath, MAKEFILE_MK_NAME
    relativeMkPath = path.relative projectRoot, mkFilePath
    fs.writeFile mkFilePath, buffer, (err) ->
        if err?
            console.error "error writing #{mkFilePath}"
            throw err
        cb null, relativeMkPath, globalTargets

###
    prints the key and value of an object: key:value
    it also works if the object has an array of key value pairs
    you can pass options to change 
     * the seperator bewteen key and value
     * the seperator between the array elements
     * wrapping characters arround the each key and value, only if 
     * wrapping characters arround the 
###
keyValues = (obj, opts) ->
    if not opts?
        opts = {
            keyValueSeperator: ':'
            keyValueWrapper: ''
            arraySeperator: ' '
            arraywrapper: ''
        }

    pairs = _(obj).pairs()
    result = undefined
    if pairs.length is 0
        debug "no key value pair found"
        throw new Error "no key value found for #{obj}"
    else if pairs.length is 1
        pair = pairs[0]
        key = pair[0]
        value = pair[1]
        # display <WRAPPER><KEY><SEP><VALUE><WRAPPER>
        result =  "#{opts.keyValueWrapper}#{key}#{opts.keyValueSeperator}#{value}#{opts.keyValueWrapper}"
    else 
        tmpArray = []
        _(pairs).each (pair) ->
            key = pair[0]
            value = pair[1]
            tmpArray.push "#{opts.keyValueWrapper}#{key}#{opts.keyValueSeperator}#{value}#{opts.keyValueWrapper}"
        
        # display <KEY-VALUE-PAIR><ARRAY-SEPERATOR><KEY-VALUE-PAIR>
        result = tmpArray.join opts.arraySeperator
        # display <ARRAY-WRAPPER><ALL-KEY-VALUE-PAIRS><ARRAY-WRAPPER>
        result = "#{opts.arraywrapper}#{result}#{opts.arraywrapper}"

    return result

lookup = (context, key) ->
    if key.indexOf('.') is -1
        if not context[key]?
            err = new Error "key '#{key}' is null of context '#{context}'"
            err.code = 'KEY_NOT_FOUND'
            return throw err

        return context[key]
     else
        # if context had nested keys, use recursive strategy
        [firstKey, rest...] = key.split '.'

        if context[firstKey]?
            lastKey = _(rest).last()
            err = new Error "key '#{lastKey}' is null in '#{key}'"
            err.code = 'KEY_NOT_FOUND'
            return throw err

        return lookup context[firstKey], rest.join('.')

        
        

getTarget = (ruleName) ->
    debug "checking for rule: #{ruleName}"
    debug rules
    rule = rules[ruleName]
    if rule?
        rule.target
    else
        throw new Error "rule with name #{ruleName} not found"

getType = (param) ->
    if _(param).isArray()
        return 'array'
    if _(param).isFunction()
        return 'function'
    if _(param).isObject()
        return 'object'
    return typeof param

throwError = (key, expected, type) ->
    throw new Error "expected #{expected} for #{key}, but get #{type}"

module.exports = createLocalMakefileInc

###
 # component-install
                makefileLines.push formatRule
                    targetPath: "#{libPrefix}/build/components"
                    preequisits: ["#{libPrefix}/build/component.json"]
                    actions: [
                        "cd #{libPrefix}/build && $(COMPONENT_INSTALL) $(COMPONENT_INSTALL_FLAGS) || rm -rf #{libPrefix}/components"
                        "test -d #{libPrefix}/build/components"
                        "touch #{libPrefix}/build/components"
                    ]


###

