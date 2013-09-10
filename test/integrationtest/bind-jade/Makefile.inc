lib/bind-jade/build/client.js: lib/bind-jade/client.coffee
	$(COFFEEC) -c $(COFFEE_FLAGS) --output lib/bind-jade/build $<

lib/bind-jade/build/component.json: lib/bind-jade/Manifest.coffee
	mkdir -p lib/bind-jade/build
	/Users/awilhelm/actano-rplan/tools/create_component_json.coffee < $< > $@

lib/bind-jade/build/components: lib/bind-jade/build/component.json
	cd lib/bind-jade/build && $(COMPONENT_INSTALL) $(COMPONENT_INSTALL_FLAGS) || rm -rf lib/bind-jade/components
	test -d lib/bind-jade/build/components
	touch lib/bind-jade/build/components

lib/bind-jade/build/bind-jade.js: lib/bind-jade/build/components lib/bind-jade/build/client.js
	cd lib/bind-jade/build && $(COMPONENT_BUILD) $(COMPONENT_BUILD_FLAGS) --name bind-jade -v -o ./

lib/bind-jade/build/Readme.html: lib/bind-jade/Readme.md
	@mkdir -p lib/bind-jade/build
	markdown $< > $@

lib/bind-jade/build/History.html: lib/bind-jade/History.md
	@mkdir -p lib/bind-jade/build
	markdown $< > $@

lib/bind-jade/html_doc: lib/bind-jade/build/Readme.html lib/bind-jade/build/History.html

lib/bind-jade: lib/bind-jade/build/component.json lib/bind-jade/build/bind-jade.js lib/bind-jade/html_doc
	touch lib/bind-jade

lib/bind-jade/clean: 
	rm -rf lib/bind-jade/build
	rm -rf lib/bind-jade/components
.PHONY: lib/bind-jade/clean
