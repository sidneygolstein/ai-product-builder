#!/usr/bin/env bash
# SessionStart audit: lists folders missing CLAUDE.md + stale CLAUDE.md files.
# Prints suggestions only — never creates or modifies any file.
# Cached once per calendar day per project to avoid repeated tree walks.

SKIP_RE="node_modules|\.git|\.worktrees|dist|build|\.expo|\.next|__pycache__|coverage"
STALE_DAYS=90
# Key on the full path (hashed) so two repos sharing a folder name never collide.
PWD_HASH=$(printf '%s' "$PWD" | cksum | cut -d' ' -f1)
CACHE_FILE="${TMPDIR:-/tmp}/apb-audit-$(basename "$PWD")-${PWD_HASH}-$(date +%Y-%m-%d).cache"

# Serve from daily cache if available
if [ -f "$CACHE_FILE" ]; then
    cat "$CACHE_FILE"
    exit 0
fi

run_audit() {
    printf "\n── CLAUDE.md audit ──────────────────────────────\n"

    # 1. Folders that contain source files but have no CLAUDE.md
    printf "Folders missing CLAUDE.md:\n"
    FOUND=0
    while IFS= read -r dir; do
      if find "$dir" -maxdepth 1 -type f \( \
          -name "*.ts" -o -name "*.tsx" -o -name "*.js" \
          -o -name "*.py" -o -name "*.go" -o -name "*.rb" \
        \) 2>/dev/null | grep -q .; then
        if [ ! -f "$dir/CLAUDE.md" ]; then
          printf "  missing: %s\n" "$dir"
          FOUND=1
        fi
      fi
    done < <(find . -maxdepth 3 -type d | grep -Ev "/($SKIP_RE)(/|$)")
    [ "$FOUND" -eq 0 ] && printf "  (none)\n"

    # 2. Existing CLAUDE.md files not touched by git in STALE_DAYS days
    printf "Stale CLAUDE.md (%d+ days since last commit):\n" "$STALE_DAYS"
    FOUND=0
    NOW=$(date +%s)
    while IFS= read -r f; do
      ct=$(git log -1 --format="%ct" -- "$f" 2>/dev/null)
      [ -z "$ct" ] && continue
      age=$(( (NOW - ct) / 86400 ))
      if [ "$age" -gt "$STALE_DAYS" ]; then
        printf "  stale (%dd): %s\n" "$age" "$f"
        FOUND=1
      fi
    done < <(find . -name "CLAUDE.md" -not -path "./.git/*" 2>/dev/null)
    [ "$FOUND" -eq 0 ] && printf "  (none)\n"

    printf "Suggestions only — no files created.\n"
    printf "────────────────────────────────────────────────\n"
}

run_audit | tee "$CACHE_FILE"
