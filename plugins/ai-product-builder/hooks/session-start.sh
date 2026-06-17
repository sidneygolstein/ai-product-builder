#!/usr/bin/env bash
# SessionStart: scaffold ai/ if missing, display progress, run baseline (informational).

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# 1. Scaffold ai/ if it does not exist
if [ ! -d ai ]; then
    mkdir -p ai/config ai/decisions ai/plans ai/verdicts
    printf '{"project": "", "slices": []}\n' > ai/feature_list.json
    printf '# (project) — Progress\n\n**Last updated:** (not yet set)\n\n## Where things stand\nNot initialized — run /setup-project to complete setup.\n\n## Active slice\nnone\n\n## Next up\nrun /setup-project\n' > ai/progress.md
    touch ai/decisions/.gitkeep
    printf '[ai-product-builder] ai/ scaffolded — run /setup-project to complete initialization.\n'
fi

# 2. Print progress
if [ -f ai/progress.md ]; then
    printf '\n=== ai/progress.md ===\n'
    cat ai/progress.md
    printf '======================\n'
fi

# 3. Run baseline (30s timeout — informational only at session start)
if [ -f ai/init.sh ]; then
    printf '\n[baseline] Running ai/init.sh (30s timeout)...\n'
    if timeout 30 bash ai/init.sh 2>&1; then
        printf '[baseline] Passed.\n'
    else
        _ec=$?
        if [ "$_ec" -eq 124 ]; then
            printf '[baseline] Timed out (>30s) — run manually: bash ai/init.sh\n'
        else
            printf '[baseline] FAILED — fix before closing this session.\n'
        fi
    fi
fi

# 4. Surface active + next slice (requires jq; skips silently if unavailable)
if [ -f ai/feature_list.json ] && command -v jq &>/dev/null; then
    active_id=$(jq -r '[.slices[] | select(.status == "DOING")] | first | .id // ""' ai/feature_list.json 2>/dev/null)
    active_title=$(jq -r '[.slices[] | select(.status == "DOING")] | first | .title // ""' ai/feature_list.json 2>/dev/null)
    next_id=$(jq -r '[.slices[] | select(.status == "TO DO")] | first | .id // ""' ai/feature_list.json 2>/dev/null)
    next_title=$(jq -r '[.slices[] | select(.status == "TO DO")] | first | .title // ""' ai/feature_list.json 2>/dev/null)
    review_count=$(jq '[.slices[] | select(.status == "TO SPEC REVIEW")] | length' ai/feature_list.json 2>/dev/null)

    printf '\n── Slices ──────────────────────────────────────\n'
    if [ -n "$active_id" ] && [ "$active_id" != "null" ] && [ "$active_id" != "" ]; then
        printf 'Active  [%s] %s\n' "$active_id" "$active_title"
        printf 'Run     /build or /verify %s\n' "$active_id"
    elif [ -n "$next_id" ] && [ "$next_id" != "null" ] && [ "$next_id" != "" ]; then
        printf 'Active  none\n'
        printf 'Next    [%s] %s\n' "$next_id" "$next_title"
        printf 'Run     /plan %s\n' "$next_id"
    elif [ -n "$review_count" ] && [ "$review_count" -gt 0 ] 2>/dev/null; then
        printf 'Active  none  |  Next  %s ticket(s) awaiting spec review\n' "$review_count"
        printf 'Run     /spec-review\n'
    else
        printf 'Active  none  |  Next  none\n'
        printf 'Run     /brainstorm  or  /tickets\n'
    fi
    printf '────────────────────────────────────────────────\n'
fi

# 5. CLAUDE.md audit (existing script)
if [ -f "$SCRIPT_DIR/audit-claude-md.sh" ]; then
    bash "$SCRIPT_DIR/audit-claude-md.sh"
fi

exit 0
