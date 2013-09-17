###

    THIS ARE SOME API IDEAS / DRAFTS

    this can be used as configuration file (JSON as coffe) for the genertion of the Makefile.mk files
    the example rules are based on the Manifest.coffe / Lakefile format and structure

    motivation is to create a generic API for the Makefile.mk creation

###

module.exports = 
    title: 'Jade'
    description: "compile .jade to .js"
    addRules: (manifest, ruleBook) ->
        ruleBook.add "clean", [tags], ->
            target: "clean"
            actions: ruleBook.getRuleByTag 'bla'
            dependencies: ruleBook.getRuleByTitle "bla"



registerRule = (id, tags, ruleFactory) ->
    factories[id] = ruleFactory


ruleBook.getRuleById = (id) ->
    return factories[id](manifest, this)


factories['clean'](manifest, this)
