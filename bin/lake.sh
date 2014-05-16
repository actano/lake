#!/bin/bash
LAKE=.lake
CWD=$(pwd)

# Search for .lake upwards
while [ ! -d $LAKE -a "$(pwd)" != "/" ]; do
    cd ..
done

# No .lake found
if [ ! -d $LAKE ]; then
    exit 255
fi

# Compute target prefix
ROOT=$(pwd)
PREFIX=${CWD:$((${#ROOT}+1))}

if [ "$*" = "" ]; then
    # No arguments given, execute default target
    make $PREFIX
else
    # Collect targets and execute them
    TARGETS=()
    if [ "$PREFIX" != "" ]; then PREFIX="$PREFIX/"; fi
    for arg in $@; do
        TARGETS+=("${PREFIX}${arg}")
    done
    make ${TARGETS[@]}
fi

# Restore directory
cd $CWD
