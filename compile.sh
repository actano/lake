#!/usr/bin/env bash

# delete out
rm -rf lib

# compile from src to lib
`npm bin`/coffee -o lib -c src

# copy make-feature assets (ignore coffee files, which already coverted to js)
rsync -av --exclude "*.coffee" src/make-feature lib/make-feature
