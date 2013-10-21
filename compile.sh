#!/usr/bin/env bash

# delete out
rm -rf lib

# compile from src to lib
`npm bin`/coffee -o lib -c src
