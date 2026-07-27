# `/apb-debug` Command — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a `/apb-debug` front-door command to the AI Product Builder plugin that root-causes a discovered bug (systematic-debugging Phases 1–3), logs it to `ai/diagnoses/`, and files a tracked Bug ticket — without fixing it.

**Architecture:** Pure prompt/skill change. New markdown command `commands/debug.md` invokes `superpowers:systematic-debugging` for investigation only and `ai-product-builder:notion-board` for ticket creation. Supporting edits to `commands/next.md` (critical-bug priority), `skills/setup-project` (scaffold `ai/diagnoses/` + document new schema fields), `README.md`, and a version bump. No application/runtime code.

**Tech Stack:** Claude Code plugin (markdown command files + skill markdown), git.

## Global Constraints

- Target repo: `ai-product-builder` at `/Users/sidneygolstein/.claude/plugins/marketplaces/sidneygolstein-ai-product-builder`. Git toplevel is the marketplace root; the plugin lives under `plugins/ai-product-builder/`.
- Command file is named `debug.md` (surfaces as `ai-product-builder:debug`); the marketplace maps it to `/apb-debug`. Refer to it as `/apb-debug` in user-facing text.
- Version bump: `.claude-plugin/plugin.json` `2.1.4 → 2.2.0` (new feature = minor bump). Do this once, in the final task.
- New artifact folder: `ai/diagnoses/` (peer of `ai/plans/`, `ai/verdicts/`, `ai/decisions/`).
- Bug-id convention: `BUG-<area>-<n>` (matches `BUG-F7-1`, `BUG-MA8-1`).
- Ticket entry point for bugs: `Status=TO DO` (skip spec-review). New optional ticket fields: `severity` (`critical|major|minor|trivial`) and `refs.diagnosis`.
- These are prompt files — there is no unit-test runner. "Tests" are structural checks (`grep`/read for required directives) plus one end-to-end behavioural validation in the final task.
- Match the existing command style: YAML frontmatter with a `description:` line, then terse imperative instructions to the agent (see `commands/fix.md`, `commands/next.md` for tone).
- The spec this implements: `docs/specs/2026-07-27-apb-debug-command-design.md`.

---

## File Structure

| File | Responsibility |
|---|---|
| `plugins/ai-product-builder/commands/debug.md` | **new** — the `/apb-debug` command: context gate → root cause → log → ticket → hand off |
| `plugins/ai-product-builder/commands/next.md` | add rule 0: critical Bug tickets surface first |
| `plugins/ai-product-builder/skills/setup-project/SKILL.md` | scaffold `ai/diagnoses/` |
| `plugins/ai-product-builder/skills/setup-project/references/file-templates.md` | document `severity` + `refs.diagnosis` in the ticket schema |
| `plugins/ai-product-builder/README.md` | add `/apb-debug` to pipeline/command docs |
| `plugins/ai-product-builder/.claude-plugin/plugin.json` | version → `2.2.0` |

Paths below are relative to the git toplevel (marketplace root).

---

### Task 1: The `/apb-debug` command

**Files:**
- Create: `plugins/ai-product-builder/commands/debug.md`

**Interfaces:**
- Consumes: `superpowers:systematic-debugging` (invoked via the Skill tool, scoped to Phases 1–3); `ai-product-builder:notion-board` (invoked via the Skill tool to create the Bug ticket).
- Produces: `ai/diagnoses/<bug-id>.md` in the consuming project; a `Type=Bug` ticket in Notion + `ai/feature_list.json`; a printed hand-off block ending in `Next: /apb-plan <bug-id>`.

- [ ] **Step 1: Define the acceptance check**

The command file, once created, must satisfy all of these (verified in Step 3):
1. Frontmatter `description:` mentions it is the front door for a discovered/runtime bug and that it does not fix.
2. Body contains a **context gate**: if no error/description was supplied, ask for it and wait; do not investigate without context.
3. Body instructs invoking `superpowers:systematic-debugging` **scoped to Phases 1–3**, with an explicit **hard stop before Phase 4 / no fix / revert probes** constraint.
4. Body specifies writing `ai/diagnoses/<bug-id>.md` with the full section list.
5. Body specifies filing a `Type=Bug` ticket via `ai-product-builder:notion-board` at `Status=TO DO`, with `severity`, ACs, `refs.diagnosis`/`refs.file`/`refs.found_in`, mandatory Project relation, mirrored to `ai/feature_list.json`; and the trivial path (`technical_shape=trivial`, offer inline fix, always PR).
6. Body ends with the exact hand-off block.

- [ ] **Step 2: Create `commands/debug.md` with this exact content**

```markdown
---
description: Front door for a bug found by running the app or manual observation. Root-causes it (systematic-debugging), logs it to ai/diagnoses/, and files a Bug ticket — WITHOUT fixing. The fix flows through the normal /plan → build → verify → ship → land pipeline.
---
`/apb-debug` diagnoses and tickets a defect. It NEVER writes the fix (except the explicit
trivial inline path, which still produces a ticket + PR).

**1. Context gate — required.**
If the user pasted an error / stack trace / description with the command, use it. Otherwise ASK
and WAIT — do not investigate without context:
  "Paste the error log / stack trace, or describe the bug — what you did, what happened, what you
   expected, and reproduction steps if you know them."

**2. Root cause — systematic-debugging Phases 1–3 only.**
Invoke the `superpowers:systematic-debugging` skill, scoped to investigation:
  - Phase 1: read the error/stack trace fully (note file:line); reproduce, or record
    "not reproducible — evidence gathered"; check recent changes (`git diff`, recent commits);
    in a multi-component path, instrument boundaries to find the failing layer; trace the bad
    value back to its source.
  - Phase 2: find a working example, compare, list every difference.
  - Phase 3: state ONE hypothesis and test it MINIMALLY with a throwaway probe.
HARD STOP before Phase 4. Constraints:
  - Do NOT write the fix. Do NOT modify product/source code.
  - Revert any probe or instrumentation before finishing — leave the tree clean except the
    diagnosis file.

**3. Log — write `ai/diagnoses/<bug-id>.md`.**
Choose `<bug-id>` as `BUG-<area>-<n>` (area = related feature slug or a short kebab tag from the
root-cause file; n = next index for that area). Propose it and confirm with the user. Write the
file with frontmatter (`bug-id`, `date` from `date -u +%Y-%m-%d`, `severity`, `status: diagnosed`)
and these sections, all populated (no placeholders):
  Symptom · Reproduction · Investigation · Root cause (+ file:line) · Blast radius ·
  Proposed fix (direction only, NOT code) · Regression test to add (name + assertion) · Ruled out.

**4. Severity + shape.**
Assign `severity` (critical · major · minor · trivial) and `technical_shape` (ui · backend ·
trivial) from the diagnosis.

**5. File the ticket — use the `ai-product-builder:notion-board` skill.**
Show the draft ticket and WAIT for explicit confirmation before creating in Notion.
  - Non-trivial: Type=Bug, Status=TO DO (the diagnosis is the spec — spec-review is skipped),
    severity set. Acceptance Criteria: (a) "the bug no longer reproduces"; (b) "regression test
    <name> added". refs.diagnosis → ai/diagnoses/<bug-id>.md, refs.file → root-cause file:line,
    refs.found_in → "/apb-debug <date>". Project relation is MANDATORY. Mirror into
    ai/feature_list.json (id, title, status, type="Bug", technical_shape, severity, branch,
    worktree, notion_page_id, acceptance_criteria, definition_of_done, refs).
  - Trivial: same, but technical_shape="trivial" (skips spec-review AND the simplifier). Offer to
    fix it inline under this ticket now — but it is ALWAYS PR'd, never a silent fix.

**6. Hand off — print exactly:**
```
Diagnosis:  ai/diagnoses/<bug-id>.md
Ticket:     <bug-id> — <title>   (filed · <severity> · status TO DO)
Root cause: <one line> (<file:line>)
Next: /apb-plan <bug-id>
```
(Use `/apb-build <bug-id>` instead when the trivial inline path was taken and no plan is needed.)

Constraints (mirroring /fix):
  - Do NOT apply a fix except the explicit trivial inline path.
  - Do NOT change any ticket status other than creating the new Bug ticket at TO DO.
  - Scope is the single reported defect. Note unrelated issues for a separate /apb-debug run;
    do not chase them here.
```

- [ ] **Step 3: Verify required elements are present**

Run:
```bash
cd /Users/sidneygolstein/.claude/plugins/marketplaces/sidneygolstein-ai-product-builder
F=plugins/ai-product-builder/commands/debug.md
grep -q "Context gate" "$F" && \
grep -q "superpowers:systematic-debugging" "$F" && \
grep -q "HARD STOP before Phase 4" "$F" && \
grep -q "ai/diagnoses/<bug-id>.md" "$F" && \
grep -q "ai-product-builder:notion-board" "$F" && \
grep -q "Status=TO DO" "$F" && \
grep -q "refs.diagnosis" "$F" && \
grep -q "Next: /apb-plan <bug-id>" "$F" && echo "ALL PRESENT" || echo "MISSING ELEMENT"
```
Expected: `ALL PRESENT`

- [ ] **Step 4: Commit**

```bash
git add plugins/ai-product-builder/commands/debug.md
git commit -m "feat(apb): add /apb-debug command — diagnose + log + ticket, no fix"
```

---

### Task 2: Critical-bug priority in `/apb-next`

**Files:**
- Modify: `plugins/ai-product-builder/commands/next.md`

**Interfaces:**
- Consumes: `ai/feature_list.json` ticket fields `type`, `severity`, `status`.
- Produces: `/apb-next` returns a `severity: critical` Bug ticket ahead of all other tickets.

- [ ] **Step 1: Define the acceptance check**

`next.md` must contain a new highest-priority rule (rule 0) that matches `Type=Bug` +
`severity: critical` in status `TO DO` or `DOING` and returns it first, routing `DOING` →
`/apb-build`/`/apb-verify` and `TO DO` → `/apb-plan <id>`. Existing rules 1–4 remain, renumbered
or left as-is but subordinate.

- [ ] **Step 2: Insert rule 0**

Open `plugins/ai-product-builder/commands/next.md`. Immediately after the line
`Read ai/feature_list.json. Apply this priority order and return the FIRST match:` and before
`1. Any ticket with status \`DOING\``, insert:

```markdown
0. Any ticket with `type` = `Bug` and `severity` = `critical` and status `TO DO` or `DOING`
   → If `DOING`: `/apb-build` (tests not yet green) or `/apb-verify <id>` (build looks complete),
     same as rule 1.
   → If `TO DO`: Command: `/apb-plan <id>`
   → Also print: worktree path + branch if `DOING`. Critical production bugs pre-empt all other work.

```

- [ ] **Step 3: Verify**

Run:
```bash
cd /Users/sidneygolstein/.claude/plugins/marketplaces/sidneygolstein-ai-product-builder
grep -q "severity\` = \`critical\`" plugins/ai-product-builder/commands/next.md && echo "RULE 0 PRESENT" || echo "MISSING"
```
Expected: `RULE 0 PRESENT`

- [ ] **Step 4: Commit**

```bash
git add plugins/ai-product-builder/commands/next.md
git commit -m "feat(apb): /apb-next surfaces critical bugs first"
```

---

### Task 3: setup-project scaffolds `ai/diagnoses/` and documents new schema fields

**Files:**
- Modify: `plugins/ai-product-builder/skills/setup-project/SKILL.md`
- Modify: `plugins/ai-product-builder/skills/setup-project/references/file-templates.md`

**Interfaces:**
- Consumes: nothing new.
- Produces: bootstrapped projects contain `ai/diagnoses/` (with `.gitkeep`); the ticket-schema
  reference documents optional `severity` and `refs.diagnosis`.

- [ ] **Step 1: Locate the folder-scaffolding section**

Run:
```bash
cd /Users/sidneygolstein/.claude/plugins/marketplaces/sidneygolstein-ai-product-builder
grep -n "ai/verdicts\|ai/decisions\|ai/plans\|mkdir\|diagnoses" plugins/ai-product-builder/skills/setup-project/SKILL.md plugins/ai-product-builder/skills/setup-project/references/file-templates.md
```
Expected: line numbers where `ai/plans`, `ai/verdicts`, `ai/decisions` are created/listed. Read the surrounding block before editing.

- [ ] **Step 2: Add `ai/diagnoses/` wherever the sibling `ai/` folders are created or listed**

In `SKILL.md` (and `file-templates.md` if it enumerates the folders), add `ai/diagnoses/` as a
peer of `ai/plans/`, `ai/verdicts/`, `ai/decisions/`. If the scaffold uses `mkdir -p`, extend it,
e.g.:
```bash
mkdir -p ai/plans ai/verdicts ai/decisions ai/diagnoses
```
Add a one-line description matching the style of the existing entries, e.g.:
`ai/diagnoses/  # per-bug root-cause records written by /apb-debug`
If the folders are created with `.gitkeep`, add `ai/diagnoses/.gitkeep` the same way.

- [ ] **Step 3: Document the new ticket fields**

In `references/file-templates.md`, in the ticket-schema section, add these optional fields with
one-line descriptions matching the existing entries:
```
severity          # Bug tickets only: critical | major | minor | trivial
refs.diagnosis    # path to ai/diagnoses/<bug-id>.md (set by /apb-debug)
```

- [ ] **Step 4: Verify**

Run:
```bash
cd /Users/sidneygolstein/.claude/plugins/marketplaces/sidneygolstein-ai-product-builder
grep -rq "ai/diagnoses" plugins/ai-product-builder/skills/setup-project/ && \
grep -rq "severity" plugins/ai-product-builder/skills/setup-project/references/file-templates.md && \
grep -rq "refs.diagnosis" plugins/ai-product-builder/skills/setup-project/references/file-templates.md && echo "SETUP UPDATED" || echo "MISSING"
```
Expected: `SETUP UPDATED`

- [ ] **Step 5: Commit**

```bash
git add plugins/ai-product-builder/skills/setup-project/
git commit -m "feat(apb): setup-project scaffolds ai/diagnoses/ + documents severity/refs.diagnosis"
```

---

### Task 4: Docs + version bump

**Files:**
- Modify: `plugins/ai-product-builder/README.md`
- Modify: `plugins/ai-product-builder/.claude-plugin/plugin.json`

**Interfaces:**
- Consumes: nothing.
- Produces: `/apb-debug` documented; plugin version `2.2.0`.

- [ ] **Step 1: Find where the pipeline/commands are documented in README**

Run:
```bash
cd /Users/sidneygolstein/.claude/plugins/marketplaces/sidneygolstein-ai-product-builder
grep -n "/apb-fix\|/apb-verify\|/apb-plan\|/apb-next\|Pipeline\|Commands" plugins/ai-product-builder/README.md | head -30
```
Read the command table / pipeline section that lists the other `/apb-*` commands.

- [ ] **Step 2: Add `/apb-debug` to the README**

In the command list / pipeline table, add a row/entry for `/apb-debug` in the same format as the
neighbours, described as: "Front door for a discovered bug — root-cause (systematic-debugging) +
log to `ai/diagnoses/` + file a Bug ticket, without fixing. Hands off to `/apb-plan`." If the
README has a pipeline diagram/flow, note `/apb-debug` as the entry point for runtime bugs that
feeds into `plan → build → verify → ship → land`.

- [ ] **Step 3: Bump the version**

Edit `plugins/ai-product-builder/.claude-plugin/plugin.json`: change `"version": "2.1.4"` to
`"version": "2.2.0"`.

- [ ] **Step 4: Verify**

Run:
```bash
cd /Users/sidneygolstein/.claude/plugins/marketplaces/sidneygolstein-ai-product-builder
grep -q "apb-debug" plugins/ai-product-builder/README.md && \
grep -q '"version": "2.2.0"' plugins/ai-product-builder/.claude-plugin/plugin.json && echo "DOCS+VERSION OK" || echo "MISSING"
```
Expected: `DOCS+VERSION OK`

- [ ] **Step 5: Commit**

```bash
git add plugins/ai-product-builder/README.md plugins/ai-product-builder/.claude-plugin/plugin.json
git commit -m "docs(apb): document /apb-debug; bump plugin to 2.2.0"
```

---

### Task 5: End-to-end behavioural validation (dogfood on the live bug)

This task validates the whole command against a real defect: the morning-brief
`POST /brief/run` → `AttributeError: 'NoneType' object has no attribute 'get_brief_by_date'`
(wrong uvicorn entrypoint — booted the test factory `pipeline.api.app:create_app` with `db=None`
instead of the production composition root `pipeline.api.main:create_app`).

**Files:**
- Uses (does not modify) the newly installed command.
- Produces (in the morning-brief repo): `ai/diagnoses/BUG-brief-1.md` + a Bug ticket entry.

- [ ] **Step 1: Reinstall/refresh the plugin so `/apb-debug` is available**

Follow the local plugin-update flow (the marketplace source is now ahead of the installed cache).
Confirm `/apb-debug` (or `ai-product-builder:debug`) appears in the skills/commands list.

- [ ] **Step 2: Run `/apb-debug` against the live bug, in the morning-brief repo**

Provide the pasted traceback as context. Expected observable outcomes:
- The command asks for context only if none was pasted.
- It invokes systematic-debugging and identifies the root cause as the wrong uvicorn entrypoint
  (`app:create_app` test factory → `db=None`), with `services/pipeline/src/pipeline/api/routes/brief.py:28`
  as the surfacing site and `services/pipeline/src/pipeline/api/app.py:5` as the source.
- It writes `ai/diagnoses/BUG-brief-1.md` with every section populated.
- It drafts a `Type=Bug` ticket, waits for confirmation, then (on confirm) creates it and mirrors
  into `ai/feature_list.json` at `TO DO`.
- It prints the hand-off block ending `Next: /apb-plan BUG-brief-1`.

- [ ] **Step 3: Assert the no-fix invariant**

Run in the morning-brief repo:
```bash
cd /Users/sidneygolstein/Documents/CODE/claude-code-projects/morning-brief
git status --short
```
Expected: only `ai/diagnoses/BUG-brief-1.md` (untracked) and the `ai/feature_list.json`
modification. **No** changes under `services/pipeline/src/`.

- [ ] **Step 4: Assert priority + hand-off**

Run:
```bash
# In a session: /apb-next  → should return BUG-brief-1 if its severity is critical,
# otherwise it queues normally in TO DO. Confirm the printed Command is /apb-plan BUG-brief-1.
```
Confirm `ai/diagnoses/BUG-brief-1.md` has a `file:line` root cause and names a concrete regression
test (e.g. a test asserting the production app wires a non-None `app.state.db`, or a route-level
guard returning 503 when `db is None`).

- [ ] **Step 5: (Optional) Dogfood docs in morning-brief**

If desired, add `/apb-debug` to the pipeline table and `ai/diagnoses/` to the folder structure in
`morning-brief/CLAUDE.md`. This is a separate commit in the morning-brief repo, not the plugin repo.

---

## Notes for the executor

- Commits land in the **plugin repo** (marketplace root). Task 5 touches the **morning-brief repo**.
- Per the repo owner's convention, do not `git push` or open PRs without explicit approval.
- If any `grep` verification prints `MISSING`, fix the file before committing that task.
