#!/usr/bin/env bash

# unit tests
`npm bin`/mocha --compilers coffee:coffee-script test/rulebook/rulebook_test.coffee

# integration test
npm run build
cd test
../bin/lake features/testlmake/integration_test