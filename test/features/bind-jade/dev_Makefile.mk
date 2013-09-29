# coffee-client
integrationtest/bind-jade/build/client.js: integrationtest/bind-jade/client.coffee
	$(COFFEEC) -c $(COFFEE_FLAGS) -o integrationtest/bind-jade/build $^

# sylus
: 
	mkdir -p integrationtest/bind-jade/build/stylus
	$(STYLUSC) $(STYLUS_FLAGS) -o integrationtest/bind-jade/build/stylus $^

# component.json
integrationtest/bind-jade/build/component.json: integrationtest/bind-jade/Manifest.coffee
	mkdir -p integrationtest/bind-jade/build
	$(COMPONENT_GENERATOR) $< $@

# component-install
integrationtest/bind-jade/build/components: integrationtest/bind-jade/build/component.json
	cd integrationtest/bind-jade/build && $(COMPONENT_INSTALL) $(COMPONENT_INSTALL_FLAGS) || rm -rf integrationtest/bind-jade/build/components
	test -d integrationtest/bind-jade/build/components
	touch integrationtest/bind-jade/build/components

# component-build
integrationtest/bind-jade/bind-jade.js integrationtest/bind-jade/bind-jade.css: integrationtest/bind-jade/build/component.json integrationtest/bind-jade/build/client.js
	cd integrationtest/bind-jade/build && $(COMPONENT_BUILD) $(COMPONENT_BUILD_FLAGS) --name bind-jade -v -o ./

# local-components
build/local_components/integrationtest/bind-jade: integrationtest/bind-jade/build/client.js integrationtest/bind-jade/build/component.json integrationtest/bind-jade/build/components integrationtest/bind-jade/bind-jade.js integrationtest/bind-jade/bind-jade.css
	mkdir -p build/local_components/integrationtest/bind-jade
	cp -r integrationtest/bind-jade/build/* build/local_components/integrationtest/bind-jade
	touch build/local_components/integrationtest/bind-jade

# feature
integrationtest/bind-jade: integrationtest/bind-jade/build/client.js integrationtest/bind-jade/build/component.json integrationtest/bind-jade/build/components integrationtest/bind-jade/bind-jade.js integrationtest/bind-jade/bind-jade.css build/local_components/integrationtest/bind-jade

# runtime
integrationtest/bind-jade/install: integrationtest/bind-jade/build/client.js integrationtest/bind-jade/build/component.json integrationtest/bind-jade/build/components integrationtest/bind-jade/bind-jade.js integrationtest/bind-jade/bind-jade.css build/local_components/integrationtest/bind-jade
	rsync -rR $^ build/integrationtest/bind-jade

# global-coverage
build/coverage/integrationtest/bind-jade: integrationtest/bind-jade
	@mkdir -p build/coverage/integrationtest/bind-jade
	@cp -r integrationtest/bind-jade/* build/coverage/integrationtest/bind-jade
	$(COFFEEC) -c $(COFFEE_FLAGS) -o build/coverage/uninstrumented_js_files/integrationtest/bind-jade integrationtest/bind-jade
	$(ISTANBUL) instrument --no-compact -x "**/test/**" -x "**/build/**" -x "**/_design/**" -x "**/components/**" --output build/coverage/integrationtest/bind-jade build/coverage/uninstrumented_js_files/integrationtest/bind-jade
	touch build/coverage/integrationtest/bind-jade

# test-all
integrationtest/bind-jade/test: 

# clean
integrationtest/bind-jade/clean: 
	rm -rf integrationtest/bind-jade/build

