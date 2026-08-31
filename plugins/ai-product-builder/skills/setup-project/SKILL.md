---
name: setup-project
description: >-
  Interactive bootstrapper that wires any repo to the AI Product Builder v2 harness. Run
  once per project — or re-run to reconcile. Interviews the user one question at a time,
  resolves Notion IDs, imports non-DONE tickets, writes ai/feature_list.json +
  ai/init.sh + CLAUDE.md + hooks, and registers the project in the Projects database.
  Triggers on: "set up this project", "bootstrap this repo", "migrate to v2",
  "initialize harness", "get this repo ready for the pipeline", or any request to
  configure a new or existing project with the ai-product-builder workflow.
---

# setup-project

Bootstrap or migrate any repo to the AI Product Builder v2 harness in one guided session.

End state: every session opens with full context from `ai/progress.md`, every ticket is
tracked in `ai/feature_list.json`, quality gates are enforced by hooks, and the project is
registered in the Projects database.

> File schemas are in `references/file-templates.md`.
> MCP ID extraction with a worked example is in `references/notion-id-lookup.md`.

---

## Step 0 — Preflight

Run these checks silently before asking any questions. Stop and report if any fail.

1. **Right directory** — confirm the working path is the target project repo, not the
   `ai-product-builder` plugin folder. If the path contains `plugins/ai-product-builder`,
   stop: "Wrong directory. Please `cd` to your project repo and re-run /setup-project."

2. **Git repo** — run `git rev-parse --is-inside-work-tree 2>/dev/null`. If it fails,
   warn: "No git repo detected — setup can continue but hooks won't take effect."

3. **Clean tree** — run `git status --porcelain`. If dirty, say: "Working tree has
   uncommitted changes. Commit or stash them first (or type 'continue anyway')." Wait.

4. **MCP available** — verify `mcp__notion__notion-fetch` is in scope. If not, note:
   "Notion MCP not available — Notion steps will be skipped."

5. **Re-run detection** — if `ai/feature_list.json` already exists, switch to
   **reconcile mode** (Step 4b) instead of a fresh import. Tell the user upfront:
   "Found existing ai/feature_list.json — I'll reconcile rather than overwrite."

---

## Step 1 — Interview (one question at a time, never assume, never batch)

Confirm each answer before moving to the next question.

**Q1. Project name?**
Used as the display name and as the Projects database lookup key. If a Notion backlog
exists, this must match the `Project` value used there exactly.

**Q2. Does this project have a Notion Ticket Backlog? (Y/n)**
If yes → ask Q2a. If no → skip to Q3a.

**Q2a. Which `Project` value identifies this project's tickets?**
Use `mcp__notion__notion-search` with `query="Ticket Backlog"` and show the user the
results so they can confirm the right database. Then show the existing `Project` select
options from that database so they can confirm a value or type a new one.
Record as `<backlog_key>`.

**Q2b. Create or update this project's row in the Projects database? (Y/n)**
If yes → Step 7 will upsert. If no → Step 7 is skipped.

**Q3a. Full test command? (optional)**
Auto-detect: look for `"test"` in `package.json` scripts, `pytest`, `go test ./...`,
`cargo test`, `bundle exec rspec`, etc. Show: "I detected: `<cmd>`. Correct?" Wait.
Stored in the Projects database row only — NOT written to `ai/init.sh`. The full test suite
belongs in `/verify`, not in the baseline. Press Enter to skip.

**Q3b. Lint command?**
Auto-detect: `eslint`, `ruff check .`, `golangci-lint run`, `cargo clippy`, etc.
Same confirm pattern. Press Enter to skip.

**Q3c. Typecheck command? (optional)**
Auto-detect: `tsc --noEmit`, `mypy .`, `pyright`, etc. Press Enter to skip.

Q3b and Q3c compose `ai/init.sh` (see template in `references/file-templates.md`).
Keep it fast (< 10s) — lint + typecheck only.

**Q4a. Default branch?**
Auto-detect: `git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||'`.
Show result and confirm.

**Q4b. Feature-flag pattern? (optional)**
Example: `FEATURE_<SLUG>`, `flags.<slug>`, `isFeatureEnabled("<slug>")`. Type or Enter.

**Q4c. Design-system location? (optional)**
Example: `src/components/ui`, `packages/design-system`. Type or Enter.

**Q5. Which MCP connections does this project use?**
Options: Notion / GitHub / Playwright / Figma / Other.
Default (press Enter): Notion + GitHub.

---

## Step 2 — Detect repo state

Run: `find . -not -path './.git/*' -not -name '.*' -type f | head -20`

**Repo has code** (source files found beyond dotfiles/config): proceed to Step 3.

**Repo is empty / greenfield** (no source files):
1. Continue through Steps 3 and 5–7 (IDs, CLAUDE.md, hooks, Projects DB row).
2. Write `ai/feature_list.json` with an empty `tickets` array.
3. Skip Step 4 (no tickets yet).
4. After Step 8, print:
   ```
   Greenfield setup complete.

   Next commands:
     /brainstorm   draft the first PRD
     /tickets      create Notion tickets from the PRD
   ```
   Do not attempt to invoke `/brainstorm` or `/tickets` programmatically.

---

## Step 3 — Look up Notion IDs

Runs whenever Q2 = Y, including greenfield projects — `ai/config/notion.json` must be
complete before `/tickets` runs later.

Read `references/notion-id-lookup.md` for the exact MCP call sequence and how to extract
the data-source UUIDs from the response.

At minimum, extract:
- `ticket_db_id` — data-source UUID of the Ticket Backlog
- `projects_db_id` — data-source UUID of the Projects database

If a URL is unknown, ask the user to paste it. Never guess.

---

## Step 4a — Import tickets (has code + Q2 = Y)

Query non-DONE tickets:
```
mcp__notion__notion-query-database-view
  database: ticket_db_id
  filter:   Project = <backlog_key> AND Status != DONE
```

For each ticket, build a ticket entry. See `references/file-templates.md → Ticket schema` for
the full shape.

When importing each ticket:
- **Capture the Notion page UUID** from the query result and write it as `notion_page_id`. This UUID is required by every downstream status update — if it is missing, status transitions will fail.
- **Read `Technical Shape`** from the Notion ticket and write it as `"technical_shape"`. If `Technical Shape` is not set on the Notion ticket (older tickets), default to `"backend"`.

**Branch slug formula:**
1. Use the ticket's `Feature` text property: lowercase, spaces → dashes.
2. If `Feature` is empty: take the first 4 words of `Title`, lowercase, dash-joined.

Branch: `feature/<slug>-<id>` · Worktree: `.worktrees/<id>`

Show a summary table before proceeding:

| id | title | status | branch |
|----|-------|--------|--------|

Ask: "Import these N tickets? (yes / skip <ids>)"

---

## Step 4b — Reconcile mode (re-run, existing ai/feature_list.json)

Read `ai/feature_list.json`. Query Notion with the same filter as Step 4a.

Build a conflict table:

| id | title | local status | Notion status | action |
|----|-------|-------------|---------------|--------|

Resolution:
- **Same status**: no action.
- **Status conflict**: default = Notion wins. Ask per row if the user wants to override.
- **In Notion only** (new ticket): import automatically.
- **Local only** (not in Notion): keep but flag with `[!] not in Notion`; ask whether to
  remove.

Write the reconciled `tickets` array back into `ai/feature_list.json`.

---

## Step 5 — Write project files

Show every file's full content as a group — one fenced code block per file with a leading
`# path/to/file` comment. Wait for a single "yes / go / ok". Then write all files at once.

| File | Notes |
|------|-------|
| `ai/config/notion.json` | Schema in `references/file-templates.md`. Use `""` for unknown fields — never omit. |
| `ai/feature_list.json` | Tickets from Step 4a/4b; empty `[]` for greenfield. |
| `ai/progress.md` | Use `$(date +%Y-%m-%d)` for the date — not the model's clock. |
| `ai/decisions/.gitkeep` | Keeps the ADR directory tracked in git. |
| `ai/plans/.gitkeep` | Keeps the plans directory tracked in git. Written to by `/plan` after approval. |
| `ai/verdicts/.gitkeep` | Keeps the verdicts directory tracked in git. Written to by `verifier` on block. |
| `ai/diagnoses/.gitkeep` | Keeps the diagnoses directory tracked in git. Written to by `/debug`. |
| `ai/init.sh` | Q3b–Q3c composed under `set -euo pipefail` (lint + typecheck only — Q3a is not included; `/verify` owns the full test suite). Then `chmod +x ai/init.sh`. |

Exact templates: `references/file-templates.md`.

---

## Step 6 — Write / merge CLAUDE.md

**Read the file first.** Show a diff (not the full file) before writing. Merge — never
discard existing content. Wait for "yes / go / ok".

### CLAUDE.md (project root)

Required sections: see `references/file-templates.md → CLAUDE.md template`.

Copy the plugin's invariants into the project so the import never depends on the plugin
install location (plugin cache paths change on every update):
```
cp "${CLAUDE_PLUGIN_ROOT}/INVARIANTS.md" ai/INVARIANTS.md
```
Then use a project-local `@` import in CLAUDE.md:
```
@ai/INVARIANTS.md
```
Re-running /setup-project refreshes the copy. If `@` imports are not supported in this
environment, paste the invariants inline instead.

### Note on hooks

Do NOT write anything to `.claude/settings.json` for hooks. The plugin ships its own
`hooks.json` which Claude Code loads automatically via `CLAUDE_PLUGIN_ROOT`. Writing
duplicate hook entries into a project-level settings.json would use stale paths that
break on plugin updates.

If `.claude/settings.json` already exists and contains an `ai-product-builder` hooks
block from a previous setup run, show a diff and ask the user to remove those entries.

---

## Step 7 — Upsert the Projects database row

Runs only if Q2b = Y.

**Every Notion write requires explicit user confirmation. Show properties as a table.
Wait for "yes / go / ok" before calling any MCP create/update tool.**

1. Search the Projects database for a row whose name matches `<project name>`.
2. **Multiple matches or zero matches**: show all candidates with URLs. Ask the user to
   pick (or confirm creation). Never auto-select on ambiguity.

Properties to set:

| Property | Value |
|----------|-------|
| Name | `<project name>` |
| Harness status | `v2 full` |
| Baseline command | Q3a (test) + Q3b (lint) + Q3c (typecheck) joined with ` && ` — full suite for the record |
| Tech stack | detected stack |
| Default branch | Q4a |
| Feature flag pattern | Q4b |
| Design system location | Q4c |
| MCP connections | Q5 |
| Repository | `git remote get-url origin` |
| Local path | current working directory |
| Project (on each ticket) | set the `Project` relation on each ticket page to this row's UUID |

Write the `Project` relation **on each ticket** (not `Tickets` on the Projects row) —
the Notion bidirectional relation syncs automatically.

After a successful write:
- Take the returned page UUID and write it to `project_id` in `ai/config/notion.json`.
- If Step 5 already wrote `ai/config/notion.json` with `""` for `project_id`, update
  that field in-place now.

---

## Step 8 — Verify baseline

Run `bash ai/init.sh` and capture output.

- **Exit 0**: print "Baseline passed."
- **Non-zero**: print the output and say: "Baseline failed. This is expected for a new
  repo with no tests yet. Fix the command in `ai/init.sh` if it is wrong, then run
  `bash ai/init.sh` to confirm." Do not block setup completion.

---

## Step 9 — Summary

```
Setup complete — <project name>

Files written:
  ai/config/notion.json    Notion IDs for notion-board skill
  ai/feature_list.json     <N> tickets
  ai/progress.md           project state snapshot
  ai/init.sh               baseline: <test> && <lint> [&& <typecheck>]
  ai/decisions/.gitkeep    ADR directory (git-tracked)
  ai/plans/.gitkeep        plans directory (git-tracked)
  ai/verdicts/.gitkeep     verifier verdicts directory (git-tracked)
  ai/diagnoses/.gitkeep    diagnoses directory (git-tracked)
  CLAUDE.md                project rules (created / merged)

Notion:
  Projects DB row          Harness status = v2 full
  Tickets linked           <N>

Next:
  /spec-review   tickets in TO SPEC REVIEW
  /plan          tickets in TO DO
  /brainstorm    no tickets yet
```

---

## Invariants

- **One question at a time.** Never batch Q1–Q5 or sub-questions. Confirm each answer.
- **Notion writes are gated.** Reads (fetch, search, query) need no confirmation. Every
  create/update call requires its own explicit "yes / go / ok."
- **notion-board hard-stops** without `ai/config/notion.json` with `ticket_db_id` and
  `project_id` populated. Write the file in Step 5; backfill `project_id` after Step 7.
- **Merge, never overwrite.** Read CLAUDE.md before writing. Show a diff. Preserve all existing content.
- **Never write hooks to project settings.json.** The plugin's `hooks.json` handles all hooks via `CLAUDE_PLUGIN_ROOT`. Writing duplicate paths into a project-level file breaks on plugin updates. Remove existing ai-product-builder hook blocks if found.
- **One confirmation round for local files.** Show Step 5 files as a group; one "yes".
- **Reconcile on re-run.** If `ai/feature_list.json` exists, diff first — never blindly
  overwrite ticket statuses.
- **Bidirectional sync is Notion → local by default.** Pushing local → Notion requires
  showing a diff and a separate explicit confirmation.
- **Abort at any step.** If the user says "stop", "cancel", or "abort": stop immediately,
  list what was already written, and exit without further changes.
