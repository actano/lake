BIN          := $(shell npm bin)
TOOLS        := $(realpath $(BIN)/../../tools)
HTMLDOC      := $(realpath $(BIN)/../../tools/htmldoc)

NAME 	     := $(shell node -e "j=require('./component.json');console.log(j.name);")

COFFEEC      = $(BIN)/coffee
STYLUSC      = $(BIN)/stylus
JADEC        = $(BIN)/jade
LOCATEDEPS   = $(TOOLS)/locate_local_component_dependencies
COMPONENT_BUILD  = $(BIN)/component-build
COMPONENT_INSTALL= $(BIN)/component-install
MD_TO_HTML   = $(HTMLDOC)/md2html.coffee

MOCHA_REPORTER = tap

JADEVARS     = {\"name\":\"$(NAME)\"}
COMPONENTDEPS=$(shell $(LOCATEDEPS) ./component.json)

JADE_FLAGS   = --pretty --client
COFFEE_FLAGS =
STYLUS_FLAGS =
COMPONENT_BUILD_FLAGS = --dev --name $(NAME)
COMPONENT_INSTALL_FLAGS = --dev

ROOT_FILES := $(wildcard *.coffee)
LIB_FILES := $(wildcard lib/*.coffee)
TEST_FILES := $(wildcard test/*.coffee)
BROWSER_TEST_FILES := $(wildcard test/*-btest.coffee)
VIEW_FILES := $(wildcard views/*.jade)

MD_FILES := $(wildcard *.md)
HTML_FILES := $(patsubst %.md, build/%.html, $(MD_FILES))

ROOT_JS_FILES := $(patsubst %.coffee, build/%.js, $(ROOT_FILES))
LIB_JS_FILES := $(patsubst lib/%.coffee, build/lib/%.js, $(LIB_FILES))
TEST_JS_FILES := $(patsubst test/%.coffee, build/test/%.js, $(TEST_FILES))
VIEW_JS_FILES := $(patsubst views/%.jade, build/views/%.js, $(VIEW_FILES))

JS_FILES := $(ROOT_JS_FILES) $(LIB_JS_FILES) $(TEST_JS_FILES) $(VIEW_JS_FILES)

STYLUS_FILES := $(wildcard styles/*.styl)
CSS_FILES := $(patsubst styles/%.styl, build/styles/%.css, $(STYLUS_FILES))

BROWSER_TEST_JS_FILES := $(patsubst test/%.coffee,%.js, $(BROWSER_TEST_FILES))
JADETESTVARS = \{\"name\":\"$(NAME)\"\,\"tests\":\"$(BROWSER_TEST_JS_FILES)\"\}

all: build

build/lib/%.js: lib/%.coffee
	$(COFFEEC) -c $(COFFEE_FLAGS) --output build/lib $<

build/test/%.js: test/%.coffee
	$(COFFEEC) -c $(COFFEE_FLAGS) --output build/test $<

build/%.js: %.coffee
	$(COFFEEC) -c $(COFFEE_FLAGS) --output build $< 

build/styles/%.css: styles/%.styl
	@mkdir -p build/styles
	$(STYLUSC) $(STYLUS_FLAGS) --out build/styles $<

build/views/%.js: views/%.jade
	@mkdir -p build/views
	@echo "module.exports=" > $@
	$(JADEC) --client --path $< < $< >> $@

build: components $(JS_FILES) $(CSS_FILES) component.json html_doc
	$(COMPONENT_BUILD) $(COMPONENT_BUILD_FLAGS)

components: component.json
	$(COMPONENT_INSTALL) $(COMPONENT_INSTALL_FLAGS)

client_test: build
server_test: build
test: client_test server_test

integration_test: build
phantom_test: build
run: build

build/%.html: %.md
	@mkdir -p build
	@markdown $< > $@

html_doc: $(HTML_FILES)

clean:
	rm -fr build components

.PHONY: clean
