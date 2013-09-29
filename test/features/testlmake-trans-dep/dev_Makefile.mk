# coffee-client
integrationtest/testlmake-trans-dep/build/client.js integrationtest/testlmake-trans-dep/build/trans_module.js: integrationtest/testlmake-trans-dep/client.coffee integrationtest/testlmake-trans-dep/trans_module.coffee
	$(COFFEEC) -c $(COFFEE_FLAGS) -o integrationtest/testlmake-trans-dep/build $^

# sylus
integrationtest/testlmake-trans-dep/build/styles/testlmake-trans-dep.css: integrationtest/testlmake-trans-dep/styles/testlmake-trans-dep.styl
	mkdir -p integrationtest/testlmake-trans-dep/build/stylus
	$(STYLUSC) $(STYLUS_FLAGS) -o integrationtest/testlmake-trans-dep/build/stylus $^

# component.json
integrationtest/testlmake-trans-dep/build/component.json: integrationtest/testlmake-trans-dep/Manifest.coffee
	mkdir -p integrationtest/testlmake-trans-dep/build
	$(COMPONENT_GENERATOR) $< $@

# component-install
integrationtest/testlmake-trans-dep/build/components: integrationtest/testlmake-trans-dep/build/component.json
	cd integrationtest/testlmake-trans-dep/build && $(COMPONENT_INSTALL) $(COMPONENT_INSTALL_FLAGS) || rm -rf integrationtest/testlmake-trans-dep/build/components
	test -d integrationtest/testlmake-trans-dep/build/components
	touch integrationtest/testlmake-trans-dep/build/components

# component-build
integrationtest/testlmake-trans-dep/testlmake-trans-dep.js integrationtest/testlmake-trans-dep/testlmake-trans-dep.css: integrationtest/testlmake-trans-dep/build/component.json integrationtest/bind-jade integrationtest/testlmake-trans-dep/build/client.js integrationtest/testlmake-trans-dep/build/trans_module.js integrationtest/testlmake-trans-dep/build/styles/testlmake-trans-dep.css
	cd integrationtest/testlmake-trans-dep/build && $(COMPONENT_BUILD) $(COMPONENT_BUILD_FLAGS) --name testlmake-trans-dep -v -o ./

# local-components
build/local_components/integrationtest/testlmake-trans-dep: integrationtest/testlmake-trans-dep/build/client.js integrationtest/testlmake-trans-dep/build/trans_module.js integrationtest/testlmake-trans-dep/build/styles/testlmake-trans-dep.css integrationtest/testlmake-trans-dep/build/component.json integrationtest/testlmake-trans-dep/build/components integrationtest/testlmake-trans-dep/testlmake-trans-dep.js integrationtest/testlmake-trans-dep/testlmake-trans-dep.css
	mkdir -p build/local_components/integrationtest/testlmake-trans-dep
	cp -r integrationtest/testlmake-trans-dep/build/* build/local_components/integrationtest/testlmake-trans-dep
	touch build/local_components/integrationtest/testlmake-trans-dep

# feature
integrationtest/testlmake-trans-dep: integrationtest/testlmake-trans-dep/build/client.js integrationtest/testlmake-trans-dep/build/trans_module.js integrationtest/testlmake-trans-dep/build/styles/testlmake-trans-dep.css integrationtest/testlmake-trans-dep/build/component.json integrationtest/testlmake-trans-dep/build/components integrationtest/testlmake-trans-dep/testlmake-trans-dep.js integrationtest/testlmake-trans-dep/testlmake-trans-dep.css build/local_components/integrationtest/testlmake-trans-dep

# runtime
integrationtest/testlmake-trans-dep/install: integrationtest/testlmake-trans-dep/build/client.js integrationtest/testlmake-trans-dep/build/trans_module.js integrationtest/testlmake-trans-dep/build/styles/testlmake-trans-dep.css integrationtest/testlmake-trans-dep/build/component.json integrationtest/testlmake-trans-dep/build/components integrationtest/testlmake-trans-dep/testlmake-trans-dep.js integrationtest/testlmake-trans-dep/testlmake-trans-dep.css build/local_components/integrationtest/testlmake-trans-dep
	rsync -rR $^ build/integrationtest/testlmake-trans-dep

# global-coverage
build/coverage/integrationtest/testlmake-trans-dep: integrationtest/testlmake-trans-dep
	@mkdir -p build/coverage/integrationtest/testlmake-trans-dep
	@cp -r integrationtest/testlmake-trans-dep/* build/coverage/integrationtest/testlmake-trans-dep
	$(COFFEEC) -c $(COFFEE_FLAGS) -o build/coverage/uninstrumented_js_files/integrationtest/testlmake-trans-dep integrationtest/testlmake-trans-dep
	$(ISTANBUL) instrument --no-compact -x "**/test/**" -x "**/build/**" -x "**/_design/**" -x "**/components/**" --output build/coverage/integrationtest/testlmake-trans-dep build/coverage/uninstrumented_js_files/integrationtest/testlmake-trans-dep
	touch build/coverage/integrationtest/testlmake-trans-dep

# test-all
integrationtest/testlmake-trans-dep/test: 

# clean
integrationtest/testlmake-trans-dep/clean: 
	rm -rf integrationtest/testlmake-trans-dep/build

# jade.template.views/dummy-partial.jade
integrationtest/testlmake-trans-dep/build/views/dummy-partial.js: integrationtest/testlmake-trans-dep/views/dummy-partial.jade
	@mkdir -p integrationtest/testlmake-trans-dep/build/views
	@echo "module.exports=" > $@
	$(JADEC) --client --path $< < $< >> $@

# htdocs.demo
integrationtest/testlmake-trans-dep/build/views/demo.html: integrationtest/testlmake-trans-dep/views/page.jade
	$(JADEC) $< --pretty --obj {"name":"testlmake-trans-dep"} -o integrationtest/testlmake-trans-dep/build

# htdocs.widget
integrationtest/testlmake-trans-dep/build/views/widget.html: 
	$(JADEC) $< --pretty --obj {"name":"testlmake-trans-dep"} -o integrationtest/testlmake-trans-dep/build

