---
description: Show the single highest-priority ticket and the exact command to run next. Use at session start or when unsure what to work on. Read-only — does not start any work.
---
Read ai/feature_list.json. Apply this priority order and return the FIRST match:

1. Any ticket with status `DOING`
   → Check if `ai/verdicts/<id>.md` exists and contains `VERDICT: block`
     - If yes: Command: `/fix <id>`
     - If no: Command: `/build` (if tests aren't all green yet) or `/verify <id>` (if build looks complete)
   → Also print: worktree path, branch

2. Oldest ticket with status `TO DO`
   → Command: `/plan <id>`

3. Any ticket with status `TO SPEC REVIEW`
   → Command: `/spec-review`

4. No tickets exist or all are DONE
   → Command: `/brainstorm` or `/tickets`

Print exactly this block — nothing else, no preamble:

```
Ticket:   <id> — <title>
Status:  <status>
Branch:  <branch>           (only if DOING)
Worktree: <worktree>        (only if DOING)
Command: <the single next command>
```

Do not modify any file. Do not start any work. If ai/feature_list.json is missing, say so and suggest /setup-project.
