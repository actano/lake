###
    make syntax

    $@ (full target name of the current target)
    $? (returns the dependencies that are newer than the current target)
    $* (returns the text that corresponds to % in the target)
    $< (name of the first dependency)
    $^ (name of all the dependencies with space as the delimiter)
###



###
    "$(JADEC) $< --pretty --obj {\\\"name\\\":\\\"#{manifest.name}\\\"} --out #{targetBuildPath}"
###

jadeHtmlAction = [
    [
        {bin: "$(JADEC)"}
        {firstDependecy: "$<"}
        {param1: "--pretty"}
        {param2: "--obj"}
        {param3: "__OBJECT__"}
        {param4: "--out"}
        {param5: "__BUILD_TARGET__"}
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
    [
        {compile: "$(JADEC)"}
        {toJavaScript: "--client"}
        {withPath: "--path"}
        {ofFirstDependency: "$<"}
        {readFrom: "<"}
        {firstDependency: "$<"}
        {appendTo: ">>"}
        {allDependencies: "$@"}
    ]
]

actionDescriptions =
    "jade.html": jadeHtmlAction
    "jade.partial": jadePartialAction




###
    lib/timeline/build/test.html: lib/timeline/test/test.jade lib/timeline/views/markup.jade /Users/awilhelm/actano-rplan/lib/views/page.jade lib/timeline/build/test/timeline-browser.js
	$(JADEC) $< --pretty --obj {\"name\":\"timeline\"\,\"tests\":\"timeline-browser.js\"} --out lib/timeline/build

   "$(JADEC) $< --pretty --obj {\\\"name\\\":\\\"#{manifest.name}\\\"} --out #{targetBuildPath}"

###


###
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
## pass only the manifest subtree and compile engine / mode
# rule for html with jade compiler, html mode
createRuleSuperHigh client.htdocs.index, 'jade.html'

# rule for a partial/template, compile with jade, partial mode
createRuleSuperHigh client.templates, 'jade.partial'



createRuleLow = (target, dependecies, actionDescriptions, param) ->

    action = []
    firstAction = actionDescriptions[0]
    _(firstAction).each (key,value) ->
        regex = /__(.*)__/
        match = value.match regex
        if match?
            value = param[match[1]]

        action.push value

    buffer = "#{target}: #{dependencies.join ' '}"
    buffer += action.join " "
return buffer