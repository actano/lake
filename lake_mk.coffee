###

    THIS ARE SOME API IDEAS / DRAFTS

    this can be used as configuration file (JSON as coffe) for the genertion of the Makefile.mk files
    the example rules are based on the Manifest.coffe / Lakefile format and structure

    motivation is to create a generic API for the Makefile.mk creation

###


# feature-independant settings


lookup = require 'foobar'

lake # is immutable
config
projectRoot
getBuildPath(feature)


module.exports =
    title: 'Jade'
    description: "compile .jade to .js"
    addRules: (lake, featurePath, manifest, ruleBook) ->
        #buildPath = lake.getBuildPath feature

        ruleBook.add "clean", [tags], ->
            target: "clean"
            actions: ruleBook.getRuleByTag 'bla'
            dependencies: ruleBook.getRuleById "bla"

        ruleBook.add "clean", [tags], ->


        ruleBook.add "clean", [tags], ->


class RuleBook
    add = (id, tags, ruleFactory) ->
        factories[id] = ruleFactory


    getRuleById = (id) ->
    return factories[id](manifest, this)


for rule in ruleBook.rules
    factories[rule.id](manifest, this)