#!/usr/bin/env bash

# delete out
rm -rf out

# compile js files only for files in lib/, not in lib/*/
# don't compile js file in lib/integrationtest
find . -name "*.coffee" -maxdepth 2 | xargs node node_modules/.bin/coffee -o out -c

# compile js files for lib/make-feature
node node_modules/.bin/coffee -o out/make-feature -c lib/make-feature

# compile js files for lib/test
node node_modules/.bin/coffee -o out/test -c lib/test

# copy lib to out (ignore coffee files for this step)
rsync -av --exclude "*.coffee" --exclude "integrationtest" lib/ out

# copy integration test (copy also coffee files)
rsync -av lib/integrationtest/ out/integrationtest