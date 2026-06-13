---
description: Show the single highest-priority slice and the exact command to run next. Use at session start or when unsure what to work on. Read-only — does not start any work.
---
Read ai/feature_list.json. Apply this priority order and return the FIRST match:

1. Any slice with status `DOING`
   → Command: `/build` (if tests aren't all green yet) or `/verify <id>` (if build looks complete)
   → Also print: worktree path, branch

2. Oldest slice with status `TO DO`
   → Command: `/plan <id>`

3. Any slice with status `TO SPEC REVIEW`
   → Command: `/spec-review`

4. No slices exist or all are DONE
   → Command: `/brainstorm` or `/tickets`

Print exactly this block — nothing else, no preamble:

```
Slice:   <id> — <title>
Status:  <status>
Branch:  <branch>           (only if DOING)
Worktree: <worktree>        (only if DOING)
Command: <the single next command>
```

Do not modify any file. Do not start any work. If ai/feature_list.json is missing, say so and suggest /setup-project.
