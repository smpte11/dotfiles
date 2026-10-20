#!/bin/sh
set -eu

cd "$(dirname "$0")"

if [ ! -d .jj ]; then
    exec git pull --autostash --rebase
fi

jj git fetch
jj rebase --branch @ --destination 'trunk()'

if [ -n "$(jj log --no-graph -r '(trunk()..@) & conflicts()' -T 'change_id ++ "\n"')" ]; then
    echo "jj rebase left conflicts in the source directory; resolve them before applying" >&2
    exit 1
fi
