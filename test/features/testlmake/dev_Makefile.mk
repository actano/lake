# coffee-client
integrationtest/testlmake/build/client.js: integrationtest/testlmake/client.coffee
	$(COFFEEC) -c $(COFFEE_FLAGS) -o integrationtest/testlmake/build $^

# sylus
integrationtest/testlmake/build/styles/testlmake.css: integrationtest/testlmake/styles/testlmake.styl
	mkdir -p integrationtest/testlmake/build/stylus
	$(STYLUSC) $(STYLUS_FLAGS) -o integrationtest/testlmake/build/stylus $^

# component.json
integrationtest/testlmake/build/component.json: integrationtest/testlmake/Manifest.coffee
	mkdir -p integrationtest/testlmake/build
	$(COMPONENT_GENERATOR) $< $@

# component-install
integrationtest/testlmake/build/components: integrationtest/testlmake/build/component.json
	cd integrationtest/testlmake/build && $(COMPONENT_INSTALL) $(COMPONENT_INSTALL_FLAGS) || rm -rf integrationtest/testlmake/build/components
	test -d integrationtest/testlmake/build/components
	touch integrationtest/testlmake/build/components

# component-build
integrationtest/testlmake/testlmake.js integrationtest/testlmake/testlmake.css: integrationtest/testlmake/build/component.json integrationtest/bind-jade integrationtest/testlmake-dep integrationtest/testlmake/build/client.js integrationtest/testlmake/build/styles/testlmake.css
	cd integrationtest/testlmake/build && $(COMPONENT_BUILD) $(COMPONENT_BUILD_FLAGS) --name testlmake -v -o ./

# local-components
build/local_components/integrationtest/testlmake: integrationtest/testlmake/build/client.js integrationtest/testlmake/build/styles/testlmake.css integrationtest/testlmake/build/component.json integrationtest/testlmake/build/components integrationtest/testlmake/testlmake.js integrationtest/testlmake/testlmake.css
	mkdir -p build/local_components/integrationtest/testlmake
	cp -r integrationtest/testlmake/build/* build/local_components/integrationtest/testlmake
	touch build/local_components/integrationtest/testlmake

# documentation
integrationtest/testlmake/build/documentation: integrationtest/testlmake/Readme.md
	@mkdir -p integrationtest/testlmake/build/documentation
	markdown integrationtest/testlmake/Readme.md > integrationtest/testlmake/build/documentation/Readme.md
	touch integrationtest/testlmake/build/documentation

# database
integrationtest/testlmake/couchview: 
	mkdir -p integrationtest/testlmake/build/_design

# server-scripts
integrationtest/testlmake/server.js: integrationtest/testlmake/build/server.coffee
	@mkdir -p integrationtest/testlmake/build
	$(COFFEEC) -c $(COFFEE_FLAGS) -o integrationtest/testlmake/build $^

# feature
integrationtest/testlmake: integrationtest/testlmake/build/client.js integrationtest/testlmake/build/styles/testlmake.css integrationtest/testlmake/build/component.json integrationtest/testlmake/build/components integrationtest/testlmake/testlmake.js integrationtest/testlmake/testlmake.css build/local_components/integrationtest/testlmake integrationtest/testlmake/build/documentation integrationtest/testlmake/couchview

# runtime
integrationtest/testlmake/install: integrationtest/testlmake/build/client.js integrationtest/testlmake/build/styles/testlmake.css integrationtest/testlmake/build/component.json integrationtest/testlmake/build/components integrationtest/testlmake/testlmake.js integrationtest/testlmake/testlmake.css build/local_components/integrationtest/testlmake integrationtest/testlmake/build/documentation integrationtest/testlmake/couchview
	rsync -rR $^ build/integrationtest/testlmake

# global-coverage
build/coverage/integrationtest/testlmake: integrationtest/testlmake
	@mkdir -p build/coverage/integrationtest/testlmake
	@cp -r integrationtest/testlmake/* build/coverage/integrationtest/testlmake
	$(COFFEEC) -c $(COFFEE_FLAGS) -o build/coverage/uninstrumented_js_files/integrationtest/testlmake integrationtest/testlmake
	$(ISTANBUL) instrument --no-compact -x "**/test/**" -x "**/build/**" -x "**/_design/**" -x "**/components/**" --output build/coverage/integrationtest/testlmake build/coverage/uninstrumented_js_files/integrationtest/testlmake
	touch build/coverage/integrationtest/testlmake

# unit-test
integrationtest/testlmake/unit-test: 
	$(MOCHA) -R $(MOCHA_REPORTER) --compilers coffee:coffee-script integrationtest/testlmake/test/testlmake-unit.coffee

# test-all
integrationtest/testlmake/test: integrationtest/testlmake/unit-test

# clean
integrationtest/testlmake/clean: 
	rm -rf integrationtest/testlmake/build

# jade.template.views/list-entry-partial.jade
integrationtest/testlmake/build/views/list-entry-partial.js: integrationtest/testlmake/views/list-entry-partial.jade
	@mkdir -p integrationtest/testlmake/build/views
	@echo "module.exports=" > $@
	$(JADEC) --client --path $< < $< >> $@

# htdocs.demo
integrationtest/testlmake/build/views/demo.html: integrationtest/testlmake/views/markup.jade integrationtest/testlmake-dep/views/page.jade
	$(JADEC) $< --pretty --obj {"name":"testlmake"} -o integrationtest/testlmake/build

# htdocs.widget
integrationtest/testlmake/build/views/widget.html: integrationtest/testlmake/views/markup.jade integrationtest/testlmake-dep/views/widget.jade
	$(JADEC) $< --pretty --obj {"name":"testlmake"} -o integrationtest/testlmake/build

