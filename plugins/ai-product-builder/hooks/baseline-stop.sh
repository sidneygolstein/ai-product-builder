#!/usr/bin/env bash
# Stop hook: refuse to close a session if the baseline is broken.
# Reads ai/init.sh from the current working directory (the project repo).
# Exit 0 = allow session close. Exit 1 = block with message.

if [ ! -f ai/init.sh ]; then
    exit 0
fi

if ! output=$(bash ai/init.sh 2>&1); then
    printf 'STOP: baseline failed — fix before closing session.\n\n%s\n' "$output"
    exit 1
fi

exit 0
