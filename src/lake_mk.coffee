###

    THIS ARE SOME API IDEAS / DRAFTS

    this can be used as configuration file (JSON as coffe) for the genertion of the Makefile.mk files
    the example rules are based on the Manifest.coffe / Lakefile format and structure

    motivation is to create a generic API for the Makefile.mk creation

###


###
    example of how a make Makefile action looks like (to convert a jade file into a html)

    "$(JADEC) $< --pretty --obj {\"name\":\"#{manifest.name}\"} --out #{targetBuildPath}"

    Makefile action paramters
    $@ (full target name of the current target)
    $? (returns the dependencies that are newer than the current target)
    $* (returns the text that corresponds to % in the target)
    $< (name of the first dependency)
    $^ (name of all the dependencies with space as the delimiter)
###


# there are some BUILT-IN variables, accessable when wrapping with 2 underscores: __EXAMPLE__

# PROJECT_ROOT      - where the .lake directory is
# NAME              - name of the feature's directory
# CLASS_NAME        - if the class name replace special chars like dash and underscore and return a camelCase name
# FQ_PATH           - feature path relative to the project root
# BUILD_SUFFIX      - default 'build', can be overwritten
# FQ_BUILD_PATH     - FQ_PATH / BUILD_SUFFIX (using path.join)
# MANIFEST_PATH     - path to Manifest / Lakefile
# ITEM              - is only available when looping over an array or object keys

# You can set the TARGET, DEPENDENCIES and ACTIONS different value types: STRING and HASHED

# "$(COFFEEC) --help"   - STRING    - will be not evaluated at runtime, Makefile variables $(VAR) will be replaced at build time
# "#(manifest.client)"  - HASHED    - will be evaluated at runtime, to access the manifest object for example

# SUBSTITUTION AND EVAL ORDER FOR LOOPS
#
# first the BUILT-IN variables will be replaced
# then the expression will be evaluated
#
# EXAMPLE1: iterate over manifest.htdocs = [ {name: 'foo'}, {name:'bar'} ]
# EXAMPLE2: iterate over manifest.htdocs = { index:{html: 'foo'}, demo:{html: 'bar'} }
#
## target1: {item: 'FQ_PATH/#(__ITEM__["name"])', array: '#(manifest.htdocs)'}
## target2: {item: 'FQ_PATH/#(__ITEM__["html"])', object: '#(manifest.htdocs)'}
#
# after BUILT-IN substitution for the first iteration
#
## target1: {item: 'FQ_PATH/#(_array[0]["name"])', array: '#(manifest.htdocs)'}
## target2: {item: 'FQ_PATH/#(index["html"])', array: '#(manifest.htdocs)'}
#
# result:
#
## lib/feature/foo: dependencies
## actions
## lib/feature/bar: dependencies
## actions


# INTERN NOTE
# regex for hashed values:    #\(([\w*\.:={}\(\)]*)\)

###
# FULL EXAMPLES (result in the comment, config in the json)
###


# 1 EXAMPLE very simple, use BUILT-IN variables
#
###
   lib/planning-objects/build/component.json: lib/planning-objects/Manifest.coffee
	mkdir -p lib/planning-objects/build
	$(COMPONENT_GENERATOR) $< $@
###
"component.remote":
    target: '__FQ_BUILD_PATH__/component.json'
    dependencies: '__MANIFEST_PATH__'
    actions: [
        "mkdir -p __FQ_BUILD_PATH__"
        "$(COMPONENT_GENERATOR) $< $@"
    ]

# 2 EXAMPLE with access to the manifest object
#
###
    lib/timeline/build/views/list-entry-partial.js: lib/timeline/views/list-entry-partial.jade
    @mkdir -p lib/timeline/build/views
    @echo "module.exports=" > $@
    $(JADEC) --client --path $< < $< >> $@
###
    "partials":
        target: '__FQ_BUILD_PATH__/views/list-entry-partial.js'
        dependencies: '#(manifest.client.templates)' # can be a string or an array (will be joined with a whitespace)
        actions: [
            "@mkdir -p __FQ_PATH__/__BUILD_DIR__/views"
            "@echo 'module.exports=' > $@"
            "$(JADEC) --client --path $< < $< >> $@" # read from first dep, append content to target
        ]

# 3 EXAMPLE with multiple actions, iterating over an array
#
###
   lib/planning-objects/integration_test: lib/planning-objects/build
    $(MOCHA) -R $(MOCHA_REPORTER) --compilers coffee:coffee-script lib/planning-objects/test/server-itest.coffee
    $(MOCHA) -R $(MOCHA_REPORTER) --compilers coffee:coffee-script lib/planning-objects/test/sorting-itest.coffee
    $(MOCHA) -R $(MOCHA_REPORTER) --compilers coffee:coffee-script lib/planning-objects/test/workpackage-itest.coffee
###

"integration-test":
    condition: 'integrationTest' # create the rule only if the manifest property exist
    target: '__FQ_BUILD_PATH__/integration_test'
    dependencies: '__FQ_BUILD_PATH__'
    actions: [
        {
            item: "$(MOCHA) -R $(MOCHA_REPORTER) --compilers coffee:coffee-script __FQ_PATH__/__ITEM__"
            array: '#(integrationTests.mocha)' # iterate over the array to create multiple actions
        }
    ]


# 4 EXAMPLE with multiple targets, iterating over an object, replace extension, add $<
#
###
    lib/timeline/build/demo.html: lib/timeline/test/demo.jade lib/timeline/views/markup.jade /Users/awilhelm/actano-rplan/lib/views/page.jade lib/timeline/build/test/timeline-browser.js
    $(JADEC) $< --pretty --obj {\"name\":\"timeline\"\} --out lib/timeline/build

    lib/timeline/build/index.html: lib/timeline/test/index.jade lib/timeline/views/other.jade /Users/awilhelm/actano-rplan/lib/views/page.jade lib/timeline/build/test/timeline-browser.js
    $(JADEC) $< --pretty --obj {\"name\":\"timeline\"\} --out lib/timeline/build
###

    "jade.html":
        gobalTarget: true # will be passed to global Makefile
        target: {item: '#(__ITEM__["html"])', object: '#(manifest.htdocs)'} # build multiple rules, for each prop in the object
        dependencies: '#(__ITEM__["prerequisits"])' # item of the current iteration for the target array
        actions: [
            "$(JADEC) $< --pretty --obj #(module.exports={name:manifest.name})# --out __FQ_BUILD_PATH__"
        ]
        targetExtReplacement: {from: "jade", to: "html"} # replace target: lib/foo/bar.jade -> lib/foo/bar.html
        originalTargetAsFirstDependency: true # unshift 'demo.jade' as dependency, is referenced by Makefile's param: $<

