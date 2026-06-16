#!/usr/bin/env bash
set -euo pipefail
# Baseline: exit 0 = green; non-zero = broken — fix before closing session.
# IMPORTANT: keep this fast (< 10s). Use type-checking and linting only.
# Full test suites belong in /verify, not here — they block every session close.

# <typecheck_command>   e.g. npx tsc --noEmit
# <lint_command>        e.g. npx eslint src --max-warnings 0
