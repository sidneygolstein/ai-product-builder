#!/usr/bin/env bash
# PostToolUse: auto-format the file just written, using the project's available formatters.
# Claude Code passes tool info via stdin as JSON.
# Silently exits if no formatter is available — never blocks.

input=$(cat)

tool_name=$(printf '%s' "$input" | python3 - <<'PYEOF' 2>/dev/null
import sys, json
try:
    print(json.load(sys.stdin).get('tool_name', ''))
except Exception:
    print('')
PYEOF
)

case "$tool_name" in
    Edit|Write|NotebookEdit) ;;
    *) exit 0 ;;
esac

file_path=$(printf '%s' "$input" | python3 - <<'PYEOF' 2>/dev/null
import sys, json
try:
    d = json.load(sys.stdin)
    ti = d.get('tool_input', {})
    # NotebookEdit uses notebook_path; Edit/Write use file_path; fallback to path
    print(ti.get('file_path', ti.get('notebook_path', ti.get('path', ''))))
except Exception:
    print('')
PYEOF
)

if [ -z "$file_path" ] || [ ! -f "$file_path" ]; then
    exit 0
fi

ext="${file_path##*.}"

case "$ext" in
    ts|tsx|js|jsx|mjs|cjs)
        command -v npx &>/dev/null && {
            npx --no-install prettier --write "$file_path" 2>/dev/null || true
        }
        ;;
    py)
        command -v ruff &>/dev/null && {
            ruff format "$file_path" 2>/dev/null || true
        }
        ;;
    go)
        command -v gofmt &>/dev/null && gofmt -w "$file_path" 2>/dev/null || true
        ;;
    rs)
        command -v rustfmt &>/dev/null && rustfmt "$file_path" 2>/dev/null || true
        ;;
esac

exit 0
