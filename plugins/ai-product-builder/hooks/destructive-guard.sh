#!/usr/bin/env bash
# PreToolUse guard: blocks known-dangerous Bash commands before they run.
# Claude Code passes tool input via stdin as JSON: {"tool_name":"...","tool_input":{...}}
# Exit 0 = allow. Exit 2 = block with message.
#
# Threat model: anti-footgun, not anti-malicious. Catches accidental destructive commands
# that would be hard to recover from. Does not attempt to be exhaustive.

input=$(cat)

# Extract tool_input.command. Try jq, then python3. If neither is available, fall back to
# scanning the raw JSON with the same patterns below — a conservative fail-closed default
# (never silently allow because a parser is missing).
if command -v jq >/dev/null 2>&1; then
    cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // ""' 2>/dev/null)
elif command -v python3 >/dev/null 2>&1; then
    cmd=$(printf '%s' "$input" | python3 - <<'PYEOF' 2>/dev/null
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('tool_input', {}).get('command', ''))
except Exception:
    print('')
PYEOF
)
else
    cmd="$input"
fi

if [ -z "$cmd" ]; then
    exit 0
fi

# Block recursive deletes (rm -rf, rm -fr, rm -rRf, etc.)
if printf '%s' "$cmd" | grep -qE '\brm\s+-[a-zA-Z]*[rR][a-zA-Z]*f|\brm\s+-[a-zA-Z]*f[a-zA-Z]*[rR]'; then
    printf 'BLOCKED: recursive delete — confirm with user before running:\n  %s\n' "$cmd"
    exit 2
fi

# Block non-force recursive deletes (rm -r without -f — still irreversible)
if printf '%s' "$cmd" | grep -qE '\brm\s+-[a-zA-Z]*[rR]\b'; then
    printf 'BLOCKED: recursive delete — confirm with user before running:\n  %s\n' "$cmd"
    exit 2
fi

# Block force-push
if printf '%s' "$cmd" | grep -qE 'git\s+push\s+(-[^[:space:]]*f|--force)\b'; then
    printf 'BLOCKED: force-push — confirm with user before running:\n  %s\n' "$cmd"
    exit 2
fi

# Block dangerous git history rewrites
if printf '%s' "$cmd" | grep -qE 'git\s+reset\s+--hard\b'; then
    printf 'BLOCKED: git reset --hard — confirm with user before running:\n  %s\n' "$cmd"
    exit 2
fi

# Block git clean (wipes untracked and/or ignored files)
if printf '%s' "$cmd" | grep -qE 'git\s+clean\s+-[a-zA-Z]*[fdx]'; then
    printf 'BLOCKED: git clean — confirm with user before running:\n  %s\n' "$cmd"
    exit 2
fi

# Block reading secrets files: .env, .env.local, .env.production, .env.* variants
if printf '%s' "$cmd" | grep -qE '(^|[|&;`[:space:]])(cat|head|tail|less|more|bat)\s+[^|&;]*\.env(\.[a-zA-Z0-9_-]+)?(\s|$|;|&|\|)'; then
    printf 'BLOCKED: reading secrets file — confirm with user before running:\n  %s\n' "$cmd"
    exit 2
fi

# Block exfiltrating secrets files via curl/wget POST body
if printf '%s' "$cmd" | grep -qE '(curl|wget).*(-d|--data|--data-binary|--data-raw)\s+@[^[:space:]]*\.env'; then
    printf 'BLOCKED: sending secrets file over network — confirm with user before running:\n  %s\n' "$cmd"
    exit 2
fi

# Block piping shell scripts from the network (supply-chain risk)
if printf '%s' "$cmd" | grep -qE '(curl|wget)[^|]*\|\s*(ba)?sh\b'; then
    printf 'BLOCKED: curl|sh pattern — confirm with user before running:\n  %s\n' "$cmd"
    exit 2
fi

exit 0
