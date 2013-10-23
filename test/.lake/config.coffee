module.exports = 
    lakePath: __dirname
    featureBuildDirectory: "build"
    localComponentsPath: "build/local_components"
    runtimePath: "build/runtime"
    coveragePath: "build/coverage"
    uninstrumentedPath: "build/coverage/uninstrumented_js_files"

    ruleCollection: [
        "rules.coffee"
    ]

    makeAssignments: [
        TOOLS: '$(ROOT)/tools'
        COFFEEC: '$(NODE_BIN)/coffee'
        STYLUSC: '$(NODE_BIN)/stylus'
        JADEC: '$(NODE_BIN)/jade'
        MOCHA: '$(NODE_BIN)/mocha'
        ISTANBUL: '$(NODE_BIN)/istanbul'
        ISTANBUL_TEST_RUNNER: '$(TOOLS)/mocha_istanbul_test_runner.coffee'
        COMPONENT_BUILD: '$(NODE_BIN)/component-build'
        COMPONENT_INSTALL: '$(NODE_BIN)/component-install'
        COMPONENT_GENERATOR: '$(NODE_BIN)/create_component_json'
        COUCHVIEW_INSTALL: '$(TOOLS)/install_couch_view.coffee'
        MOCHA_REPORTER: 'tap'
        JADE_FLAGS: '--pretty --client'
        COFFEE_FLAGS: ''
        STYLUS_FLAGS: '-u nib'
        COMPONENT_BUILD_FLAGS: '--dev'
        COMPONENT_INSTALL_FLAGS: '--dev'
    ]

    makeDefaultTarget: {
        target: 'all'
        dependencies: 'build'
    }

    globalRules: 
        """
        build/clean: build/local_components/clean build/runtime/clean build/coverage/clean
        test: unit_test integration_test client_test
        build/local_components/clean:
        \t  rm -rf build/local_components
        build/runtime/clean:
        \t  rm -rf build/runtime
        .PHONY: clean
        """
