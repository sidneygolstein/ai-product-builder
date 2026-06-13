#!/usr/bin/env bash
# PreToolUse guard: blocks known-dangerous Bash commands before they run.
# Claude Code passes tool input via stdin as JSON: {"tool_name":"...","tool_input":{...}}
# Exit 0 = allow. Exit 2 = block with message.
#
# Threat model: anti-footgun, not anti-malicious. Catches accidental destructive commands
# that would be hard to recover from. Does not attempt to be exhaustive.

input=$(cat)

cmd=$(printf '%s' "$input" | python3 - <<'PYEOF' 2>/dev/null
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('tool_input', {}).get('command', ''))
except Exception:
    print('')
PYEOF
)

if [ -z "$cmd" ]; then
    exit 0
fi

# Block recursive deletes (rm -rf, rm -fr, rm -rRf, etc.)
if printf '%s' "$cmd" | grep -qE '\brm\s+-[a-zA-Z]*[rR][a-zA-Z]*f|\brm\s+-[a-zA-Z]*f[a-zA-Z]*[rR]'; then
    printf 'BLOCKED: recursive delete — confirm with user before running:\n  %s\n' "$cmd"
    exit 2
fi

# Block force-push
if printf '%s' "$cmd" | grep -qE 'git\s+push\s+(-[^[:space:]]*f|--force)\b'; then
    printf 'BLOCKED: force-push — confirm with user before running:\n  %s\n' "$cmd"
    exit 2
fi

# Block reading known secrets files (cat .env, cat *.env)
if printf '%s' "$cmd" | grep -qE '(^|[|&;`[:space:]])(cat|head|tail|less)\s+[^|&;]*\.env(\s|$)'; then
    printf 'BLOCKED: reading secrets file — confirm with user before running:\n  %s\n' "$cmd"
    exit 2
fi

exit 0
