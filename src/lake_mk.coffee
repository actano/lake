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


# if targetExtReplacement is set then
# the the a dependency will be unshifted to the dependencies 
# with the same name as the target, but replaced the extension
# example
# foo/bar/target.from: foo/bar/target.to dependency1 dependecy2

# there are some BUILT-IN variables, accessable when wrapping with 2 underscores: __EXAMPLE__
# PROJECT_ROOT - where the .lake directory is
# NAME - name of the feature's directory
# CLASS_NAME - if the class name replace special chars like dash and underscore and return a camelCase name
# FQ_PATH - feature path relative to the project root
# BUILD_SUFFIX - default 'build', can be overwritten
# FQ_BUILD_PATH - FQ_PATH / BUILD_SUFFIX (using path.join)
# MANIFEST_PATH - path to Manifest / Lakefile

# You can set the TARGET, DEPENDENCIES, ACTIONS, and ARG in different MODES

# string        - default, will be 'hard coded'
# manifest      - lookup in the Manifest.coffee object
# eval          - will be evaluated at runtime, you have access to the Manifest object

# for all MODES you can use the BUILT-IN variables
# pass the the value as 'v' property
# pass the mode as 'm' property, if you don't pass 'm' the default is be used (string)


actionDescriptions =

###
    lib/timeline/build/test.html: lib/timeline/test/test.jade lib/timeline/views/markup.jade /Users/awilhelm/actano-rplan/lib/views/page.jade lib/timeline/build/test/timeline-browser.js
    $(JADEC) $< --pretty --obj {\"name\":\"timeline\"\,\"tests\":\"timeline-browser.js\"} --out lib/timeline/build
###
    "jade.html":
        target: {v: 'htdocs.demo.html', m:'manifest'}
        dependencies: {v: ['htdocs.demo.prerequisits'], m: 'manifest'}
        actions: [
            {v: "$(JADEC) $< --pretty --obj __OBJECT__ --out __BUILD_TARGET__"}
        ]
        targetExtReplacement: {from: "jade", to: "html"}
        arg: {
            "OBJECT": {v: 'module.exports={name:manifest.name}', m:'eval'}
            "BUILD_TARGET": {v: "__FQ_BUILD_PATH__"}
        }

###
    lib/timeline/build/views/list-entry-partial.js: lib/timeline/views/list-entry-partial.jade
    @mkdir -p lib/timeline/build/views
    @echo "module.exports=" > $@
    $(JADEC) --client --path $< < $< >> $@
###
    "jade.partial":
        target: 'client.templates'
        actions: [
            "@mkdir -p __FQ_PATH__/__BUILD_DIR__/views"
            "@echo 'module.exports=' > $@"
            "$(JADEC) --client --path $< < $< >> $@"
        ]
        targetExtReplacement: {from: "jade", to: "js"}
###
   lib/planning-objects/build/component.json: lib/planning-objects/Manifest.coffee
	mkdir -p lib/planning-objects/build
	$(COMPONENT_GENERATOR) $< $@
###
    "component.remote":
        target: '__FQ_BUILD_PATH__/component.json'
        dependencies: '__MANIFEST_PATH__'
        actions: [
            {v: "mkdir -p __FQ_BUILD_PATH__"}
            {v: "$(COMPONENT_GENERATOR) $< $@"}
        ]
        targetExtReplacement: {from: "jade", to: "js"}





###

    here are some code snippets, "intern API"

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
