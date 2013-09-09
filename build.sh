#!/usr/bin/env bash

rm -rf out
find . -name "*.coffee" -maxdepth 2 | xargs node node_modules/.bin/coffee -o out -c
node node_modules/.bin/coffee -o out/make-feature -c lib/make-feature
node node_modules/.bin/coffee -o out/test -c lib/test
rsync -av --exclude "*.coffee" --exclude "integrationtest" lib/ out
rsync -av lib/integrationtest/ out/integrationtest