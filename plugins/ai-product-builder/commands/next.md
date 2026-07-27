---
description: Show the single highest-priority ticket and the exact command to run next. Use at session start or when unsure what to work on. Read-only — does not start any work.
---
Read ai/feature_list.json. Apply this priority order and return the FIRST match:

0. Any ticket with `type` = `Bug` and `severity` = `critical` and status `TO DO` or `DOING`
   → If `DOING`: `/apb-build` (tests not yet green) or `/apb-verify <id>` (build looks complete),
     same as rule 1.
   → If `TO DO`: Command: `/apb-plan <id>`
   → Also print: worktree path + branch if `DOING`. Critical production bugs pre-empt all other work.

1. Any ticket with status `DOING`
   → Check if `ai/verdicts/<id>.md` exists and contains `VERDICT: block`
     - If yes: Command: `/fix <id>`
     - If no: Command: `/build` (if tests aren't all green yet) or `/verify <id>` (if build looks complete)
   → Also print: worktree path, branch

2. Any ticket with status `TO SPEC REVIEW`
   → Command: `/spec-review`

3. Oldest ticket with status `TO DO`
   → Command: `/plan <id>`

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
