#!/usr/bin/env bash
# SessionStart: scaffold ai/ if missing, display progress, run baseline (informational).

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# 1. Scaffold ai/ if it does not exist
if [ ! -d ai ]; then
    mkdir -p ai/config ai/decisions
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

# 3. Run baseline (never blocks — informational only at session start)
if [ -f ai/init.sh ]; then
    printf '\n[baseline] Running ai/init.sh...\n'
    if bash ai/init.sh 2>&1; then
        printf '[baseline] Passed.\n'
    else
        printf '[baseline] FAILED — fix before closing this session.\n'
    fi
fi

# 4. CLAUDE.md audit (existing script)
if [ -f "$SCRIPT_DIR/audit-claude-md.sh" ]; then
    bash "$SCRIPT_DIR/audit-claude-md.sh"
fi

exit 0
