#!/usr/bin/env bash

# delete out
rm -rf out

# compile lib to out
node_modules/.bin/coffee -o out -c lib

# copy make-feature assets (ignore coffee files, which already coverted to js)
rsync -av --exclude "*.coffee" lib/make-feature out/make-feature
