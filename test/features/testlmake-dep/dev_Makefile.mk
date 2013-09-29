# coffee-client
integrationtest/testlmake-dep/build/client.js: integrationtest/testlmake-dep/client.coffee
	$(COFFEEC) -c $(COFFEE_FLAGS) -o integrationtest/testlmake-dep/build $^

# sylus
integrationtest/testlmake-dep/build/styles/testlmake-dep.css: integrationtest/testlmake-dep/styles/testlmake-dep.styl
	mkdir -p integrationtest/testlmake-dep/build/stylus
	$(STYLUSC) $(STYLUS_FLAGS) -o integrationtest/testlmake-dep/build/stylus $^

# component.json
integrationtest/testlmake-dep/build/component.json: integrationtest/testlmake-dep/Manifest.coffee
	mkdir -p integrationtest/testlmake-dep/build
	$(COMPONENT_GENERATOR) $< $@

# component-install
integrationtest/testlmake-dep/build/components: integrationtest/testlmake-dep/build/component.json
	cd integrationtest/testlmake-dep/build && $(COMPONENT_INSTALL) $(COMPONENT_INSTALL_FLAGS) || rm -rf integrationtest/testlmake-dep/build/components
	test -d integrationtest/testlmake-dep/build/components
	touch integrationtest/testlmake-dep/build/components

# component-build
integrationtest/testlmake-dep/testlmake-dep.js integrationtest/testlmake-dep/testlmake-dep.css: integrationtest/testlmake-dep/build/component.json integrationtest/bind-jade integrationtest/testlmake-trans-dep integrationtest/testlmake-dep/build/client.js integrationtest/testlmake-dep/build/styles/testlmake-dep.css
	cd integrationtest/testlmake-dep/build && $(COMPONENT_BUILD) $(COMPONENT_BUILD_FLAGS) --name testlmake-dep -v -o ./

# local-components
build/local_components/integrationtest/testlmake-dep: integrationtest/testlmake-dep/build/client.js integrationtest/testlmake-dep/build/styles/testlmake-dep.css integrationtest/testlmake-dep/build/component.json integrationtest/testlmake-dep/build/components integrationtest/testlmake-dep/testlmake-dep.js integrationtest/testlmake-dep/testlmake-dep.css
	mkdir -p build/local_components/integrationtest/testlmake-dep
	cp -r integrationtest/testlmake-dep/build/* build/local_components/integrationtest/testlmake-dep
	touch build/local_components/integrationtest/testlmake-dep

# feature
integrationtest/testlmake-dep: integrationtest/testlmake-dep/build/client.js integrationtest/testlmake-dep/build/styles/testlmake-dep.css integrationtest/testlmake-dep/build/component.json integrationtest/testlmake-dep/build/components integrationtest/testlmake-dep/testlmake-dep.js integrationtest/testlmake-dep/testlmake-dep.css build/local_components/integrationtest/testlmake-dep

# runtime
integrationtest/testlmake-dep/install: integrationtest/testlmake-dep/build/client.js integrationtest/testlmake-dep/build/styles/testlmake-dep.css integrationtest/testlmake-dep/build/component.json integrationtest/testlmake-dep/build/components integrationtest/testlmake-dep/testlmake-dep.js integrationtest/testlmake-dep/testlmake-dep.css build/local_components/integrationtest/testlmake-dep
	rsync -rR $^ build/integrationtest/testlmake-dep

# global-coverage
build/coverage/integrationtest/testlmake-dep: integrationtest/testlmake-dep
	@mkdir -p build/coverage/integrationtest/testlmake-dep
	@cp -r integrationtest/testlmake-dep/* build/coverage/integrationtest/testlmake-dep
	$(COFFEEC) -c $(COFFEE_FLAGS) -o build/coverage/uninstrumented_js_files/integrationtest/testlmake-dep integrationtest/testlmake-dep
	$(ISTANBUL) instrument --no-compact -x "**/test/**" -x "**/build/**" -x "**/_design/**" -x "**/components/**" --output build/coverage/integrationtest/testlmake-dep build/coverage/uninstrumented_js_files/integrationtest/testlmake-dep
	touch build/coverage/integrationtest/testlmake-dep

# test-all
integrationtest/testlmake-dep/test: 

# clean
integrationtest/testlmake-dep/clean: 
	rm -rf integrationtest/testlmake-dep/build

# htdocs.demo
integrationtest/testlmake-dep/build/views/demo.html: integrationtest/testlmake-dep/views/markup.jade integrationtest/testlmake-trans-dep/views/page.jade
	$(JADEC) $< --pretty --obj {"name":"testlmake-dep"} -o integrationtest/testlmake-dep/build

# htdocs.widget
integrationtest/testlmake-dep/build/views/widget.html: integrationtest/testlmake-dep/views/markup testlmake-dep/views/widget
	$(JADEC) $< --pretty --obj {"name":"testlmake-dep"} -o integrationtest/testlmake-dep/build

