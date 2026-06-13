#!/usr/bin/env bash
# Stop hook: refuse to close a session if the baseline is broken.
# Reads ai/init.sh from the current working directory (the project repo).
# Exit 0 = allow session close. Exit 2 = block with message (exit 1 is non-blocking in Claude Code).

if [ ! -f ai/init.sh ]; then
    exit 0
fi

if ! output=$(bash ai/init.sh 2>&1); then
    printf 'STOP: baseline failed — fix before closing session.\n\n%s\n' "$output"
    exit 2
fi

exit 0
