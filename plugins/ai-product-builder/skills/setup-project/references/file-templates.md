# File Templates

Exact schemas for every file `setup-project` writes. Copy these verbatim and substitute
the `<placeholder>` values.

---

## ai/config/notion.json

```json
{
  "ticket_db_id": "<data-source UUID of Ticket Backlog — from collection:// URL>",
  "project_id":   "<page UUID of this project's row in the Projects database>",
  "projects_db_id": "<data-source UUID of Projects database — from collection:// URL>",
  "backlog_key":  "<Project select/relation value used to filter tickets>"
}
```

**Field contract:**
- `ticket_db_id` and `project_id` — read by the `notion-board` skill before every Notion
  call. Hard-stop if either is missing or empty.
- `projects_db_id` — used by `setup-project` Step 7 for the Projects DB upsert.
- `backlog_key` — informational; helps debug filter mismatches.

Write `""` for fields that are not yet known. Backfill `project_id` after Step 7 returns
the row UUID.

---

## ai/feature_list.json

Top level:

```json
{
  "project": "<project name>",
  "slices": []
}
```

### Slice schema

```json
{
  "id": "<e.g. F6.1>",
  "feature": "<slug from Notion ticket Feature property — lowercase, dashes, e.g. 'user-search'>",
  "title": "<imperative description>",
  "status": "<exact Status value — case-sensitive, see notion-board skill>",
  "notion_page_id": "<Notion page UUID of the ticket>",
  "branch": "feature/<slug>-<id>",
  "worktree": ".worktrees/<id>",
  "acceptance_criteria": [
    "<testable AC covering populated state>",
    "<testable AC covering missing/legacy state>",
    "<testable AC covering loading state>",
    "<testable AC covering flag-off state>"
  ],
  "definition_of_done": [
    "baseline check passes",
    "all ACs green",
    "browser verification passes",
    "decision record written"
  ],
  "refs": {
    "prd": "<docs/brainstorms/... or empty string>",
    "design": "<docs/design/... or empty string>",
    "notion": "<full Notion page URL>"
  }
}
```

**Slug derivation (for `branch` and `worktree`):**
1. Use the ticket's `Feature` text property: lowercase, replace spaces with dashes.
2. If `Feature` is empty: take the first 4 words of `Title`, lowercase, dash-join.

---

## ai/progress.md

```markdown
# <project name> — Progress

**Last updated:** <output of: date +%Y-%m-%d>

## Where things stand
<One paragraph: N slices total, count per status, immediate next action.>

## Active slice
<ID and title of the DOING slice, or "none">

## Next up
<ID and title of oldest TO DO — or "run /spec-review on oldest TO SPEC REVIEW" — or "run /brainstorm">
```

---

## ai/init.sh

```bash
#!/usr/bin/env bash
set -euo pipefail
# Baseline: exit 0 = green; non-zero = broken — fix before closing session.

<test_command_from_Q3a>
<lint_command_from_Q3b>
<typecheck_command_from_Q3c>   # omit this line if Q3c was skipped
```

After writing: `chmod +x ai/init.sh`

---

## CLAUDE.md (project root — minimum required sections)

```markdown
# <project name>

## Harness
- Stack: <detected stack>
- Default branch: <Q4a>
- Feature flags: <Q4b, or "none">
- Design system: <Q4c, or "none">
- MCP connections: <Q5>

## Invariants
@~/.claude/plugins/ai-product-builder/INVARIANTS.md

## Commands
- Baseline: `bash ai/init.sh`
- Next slice: read ai/feature_list.json — pick oldest DOING; if none, oldest TO DO
```

If `@` imports are not supported in this environment, replace the import line with:
```
- Read `ai/progress.md` and `ai/feature_list.json` at the start of every session.
- Never let the agent that wrote a spec or code review its own work.
- A slice is not done until `ai/init.sh` exits 0, every AC has a green test, and browser verification passes.
- One slice per session. Prefer small, independent slices.
- Write a decision record for every shipped slice.
```
