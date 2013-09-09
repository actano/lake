#!/usr/bin/env bash

rm -rf out
node node_modules/.bin/coffee -o out -c lib/
rsync -av --exclude "*.coffee" lib/ out