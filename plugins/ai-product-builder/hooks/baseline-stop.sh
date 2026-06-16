#!/usr/bin/env bash
# Stop hook: refuse to close a session if the baseline is broken OR if the
# active slice has an unresolved verifier block.
# Exit 0 = allow session close. Exit 2 = block with message.

# 1. Baseline check (timeout 30s — keep ai/init.sh fast)
if [ -f ai/init.sh ]; then
    output=$(timeout 30 bash ai/init.sh 2>&1)
    exit_code=$?
    if [ $exit_code -ne 0 ]; then
        if [ $exit_code -eq 124 ]; then
            printf 'STOP: baseline timed out after 30s — ai/init.sh must complete in under 10s.\nMove slow commands (test suites) to /verify.\n'
        else
            printf 'STOP: baseline failed — fix before closing session.\n\n%s\n' "$output"
        fi
        exit 2
    fi
fi

# 2. Verifier-block check (requires jq; skips silently if unavailable)
if [ -f ai/feature_list.json ] && command -v jq &>/dev/null; then
    active_id=$(jq -r '[.slices[] | select(.status == "DOING")] | first | .id // ""' ai/feature_list.json 2>/dev/null)
    if [ -n "$active_id" ] && [ "$active_id" != "null" ] && [ "$active_id" != "" ]; then
        verdict_file="ai/verdicts/${active_id}.md"
        if [ -f "$verdict_file" ] && grep -q '^VERDICT: block' "$verdict_file"; then
            printf 'STOP: verifier returned block for slice %s — run /fix %s before closing.\n\nFailures: ai/verdicts/%s.md\n' \
                "$active_id" "$active_id" "$active_id"
            exit 2
        fi
    fi
fi

exit 0
