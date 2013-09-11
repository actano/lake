###

    THIS ARE SOME API MOCKS

    for lake's Makefile.mk generation
    which is baed on the Manifest.coffe / Lakefile format and structure

    motivation is to create a generic API for the Makefile.mk creation

###


###
    make syntax

    $@ (full target name of the current target)
    $? (returns the dependencies that are newer than the current target)
    $* (returns the text that corresponds to % in the target)
    $< (name of the first dependency)
    $^ (name of all the dependencies with space as the delimiter)
###

###
    example of how a make rule looks like

    "$(JADEC) $< --pretty --obj {\\\"name\\\":\\\"#{manifest.name}\\\"} --out #{targetBuildPath}"
###



# documentation version
# action is a array of actions
# each action can have a list of key value pairs
# the key is only for documantion, will not be evaluated
# value is a parameter
# values will be joined with a whitespace

jadeHtmlAction = [
    [
        {compile: "$(JADEC)"}
        {firstDependecy: "$<"}
        {withPrettyMode: "--pretty"}
        {andPass: "--obj"}
        {thisToTheTemplate: "__OBJECT__"}
        {resultGoes: "--out"}
        {toThisDir: "__BUILD_TARGET__"}
    ]
]
# short version
jadeHtmlAction = [
    [
        {compilePretty: "$(JADEC) $< --pretty --obj __OBJECT__ --out __BUILD_TARGET__"}
    ]
]

###
    @mkdir -p lib/timeline/build/views
	@echo "module.exports=" > $@
	$(JADEC) --client --path $< < $< >> $@
###

jadePartialAction = [
    [
        {createDir: "@mkdir"}
        {withParents: "-p"}
        {var1: "__BUILD_VIEWS__"}
    ]
    [
        {echo: "@echo"}
        {string: '"module.exports="'}
        {pipe: ">"}
        {toAllDependencies: "$@"}
    ]
    # short version
    [
        {compilePartial: "$(JADEC) --client --path $< < $< >> $@"}
    ]
]

actionDescriptions =
    "jade.html": jadeHtmlAction
    "jade.partial": jadePartialAction




###

    desired result
    case 1

    lib/timeline/build/test.html: lib/timeline/test/test.jade lib/timeline/views/markup.jade /Users/awilhelm/actano-rplan/lib/views/page.jade lib/timeline/build/test/timeline-browser.js
	$(JADEC) $< --pretty --obj {\"name\":\"timeline\"\,\"tests\":\"timeline-browser.js\"} --out lib/timeline/build

    case 2

    lib/timeline/build/views/list-entry-partial.js: lib/timeline/views/list-entry-partial.jade
	@mkdir -p lib/timeline/build/views
	@echo "module.exports=" > $@
	$(JADEC) --client --path $< < $< >> $@

###

## low level API
createRuleLow 'lib/timeline/test.html', ['lib/dep1/foo.bar', 'lib/timeline/local.bar'], actionDescriptions['jade.html'], {OBJECT:{foo:"bar"}, BUILD_TARGET:{bar:"baz"}}

## high level API
## add relative paths for targets and dependencies
creatRuleHigh 'test.html', ['../dep1/foo.bar', 'local.bar'], actionDescriptions['jade.html'], {OBJECT:{foo:"bar"}, BUILD_TARGET:{bar:"baz"}}


## super high level PAI
## pass only the Manifest/Lakefile subtree namespace and compile engine / mode
# rule for html with jade compiler, html mode
createRuleSuperHigh 'client.htdocs.index', 'jade.html'

# rule for a partial/template, compile with jade, partial mode
createRuleSuperHigh 'client.templates', 'jade.partial'



createRuleLow = (target, dependecies, actionDescriptions, param) ->

    action = []
    firstAction = actionDescriptions[0]
    _(firstAction).each (key, value) ->
        regex = /*__(.*)__*/
        matches = value.match regex
        if matches?
            # replace it for every match
            _(matches).each (match) ->
                value.replace(match, param[match])

        action.push value

    buffer = "#{target}: #{dependencies.join ' '}"
    buffer += action.join " "
return buffer