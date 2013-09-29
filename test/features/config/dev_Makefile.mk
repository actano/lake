# server-scripts
integrationtest/config/index.js: integrationtest/config/build/index.coffee
	@mkdir -p integrationtest/config/build
	$(COFFEEC) -c $(COFFEE_FLAGS) -o integrationtest/config/build $^

# feature
integrationtest/config: 

# runtime
integrationtest/config/install: 
	rsync -rR $^ build/integrationtest/config

# global-coverage
build/coverage/integrationtest/config: integrationtest/config
	@mkdir -p build/coverage/integrationtest/config
	@cp -r integrationtest/config/* build/coverage/integrationtest/config
	$(COFFEEC) -c $(COFFEE_FLAGS) -o build/coverage/uninstrumented_js_files/integrationtest/config integrationtest/config
	$(ISTANBUL) instrument --no-compact -x "**/test/**" -x "**/build/**" -x "**/_design/**" -x "**/components/**" --output build/coverage/integrationtest/config build/coverage/uninstrumented_js_files/integrationtest/config
	touch build/coverage/integrationtest/config

# test-all
integrationtest/config/test: 

# clean
integrationtest/config/clean: 
	rm -rf integrationtest/config/build

