fs = require 'fs'
path = require 'path'
async = require 'async'


MANIFEST_FILE_NAME = "Manifest"
BUILD_SUFFIX = 'build'

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
        target: "featureBuildPath"
        dependencies: [
            () -> getTarget "component.json"
            () -> getTarget "component.install"
        ]

    rules["component.install"] =
        target: componentPath
        dependencies: path.join featureBuildPath, "component.json"
        actions: [
            "cd #{featureBuildPath} && $(COMPONENT_INSTALL) $(COMPONENT_INSTALL_FLAGS) || rm -rf #{componentPath}"
            "test -d #{componentPath}"
            "touch #{componentPath}"
        ]



    console.log rules
    outerCb new Error "create_mk is not fully implemented"

getTarget = (ruleName) ->
    rule = rules[ruleName]
    if rule?
        rules.target
    else
        throw new Error "rule with name #{ruleName} not found"

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

