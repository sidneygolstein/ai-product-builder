# `/apb-debug` — Debugging front door for the AI Product Builder pipeline

**Date:** 2026-07-27
**Status:** Approved (design) — pending implementation plan
**Target:** `ai-product-builder` plugin, version `2.1.4 → 2.2.0`
**Author:** brainstormed with Sidney

---

## Problem

The APB pipeline (`brainstorm → tickets → spec-review → plan → build → verify → ship → land`)
has strong pre-merge gates but **no front door for a defect discovered by running the app**.

- `/apb-fix` only re-enters TDD for failures the *automated verifier* raised inside an active
  ticket. It has no root-cause step and files nothing.
- The only place a bug ticket gets created today is at `/apb-ship`, when the *simplifier* flags
  a potential bug. A runtime error a human hits (e.g. a 500 from `POST /brief/run`) is handled
  ad hoc: no systematic root cause, no guaranteed regression test, no ticket, no record.
- There is no `ai/diagnoses/` artifact — no home for "what was the root cause and how do we know."

**Goal:** a repeatable, *gated, non-automatic* capability that, for any discovered bug:
detects the root cause, logs it, and files a tracked ticket — **without silently fixing it** —
then hands off to the existing pipeline for the actual fix.

## Non-goals

- Automatic capture (hooks that detect tracebacks and auto-file bugs). Explicitly out of scope —
  the user wants "processed, not too automatic." May be a future optional phase.
- Fixing the bug inside `/apb-debug`. The command never writes the fix (except the trivial
  inline-fix path, which still produces a ticket + PR). The fix is the existing pipeline's job.
- Changing the morning-brief application code. This design changes only the plugin. Dogfooding
  updates to the morning-brief repo are a separate, optional follow-up.

---

## Design principle: `/apb-debug` = systematic-debugging Phases 1–3

`superpowers:systematic-debugging` is a four-phase process under one Iron Law —
*no fixes without root-cause investigation first*:

| Phase | Activity |
|---|---|
| 1. Root Cause | Read error, reproduce, check recent changes, instrument boundaries, trace data flow to source |
| 2. Pattern | Find working examples, compare, list every difference |
| 3. Hypothesis | State one hypothesis, test it *minimally* (probe, not committed fix), confirm |
| 4. Implementation | **Failing test first**, one fix, verify |

The harness already implements **Phase 4**: `/apb-build` is TDD (failing test first → fix →
`/apb-verify`). Phase 4 step 1 of the skill literally says "use the test-driven-development
skill." So the integration is:

- **`/apb-debug` runs Phases 1–3** → a confirmed, logged root cause. **Hard-stops before Phase 4.**
- **The existing pipeline runs Phase 4** → `plan → build (regression test first) → verify → ship → land`.

`/apb-debug` diagnoses, logs, and tickets. It never fixes.

---

## Command: `commands/debug.md`

File named `debug.md` (surfaces as `ai-product-builder:debug`; the marketplace maps it to
`/apb-debug`, consistent with all other commands). Invoked as `/apb-debug [optional pasted error]`.

### Behavior

1. **Context gate (required).** If the invocation includes a pasted error/description, use it.
   Otherwise, ask and **wait**:
   > "Paste the error log / stack trace, or describe the bug — what you did, what happened, what
   > you expected, and reproduction steps if you know them."

   No investigation begins without context.

2. **Root cause (systematic-debugging Phases 1–3).** Invoke `superpowers:systematic-debugging`,
   scoped to investigation only:
   - Read the error/stack trace completely; note file paths + line numbers.
   - Reproduce, or record "not reproducible — evidence gathered."
   - Check recent changes (`git diff`, recent commits).
   - In multi-component paths, instrument boundaries to locate the failing layer.
   - Trace the bad value back to its source.
   - Form **one** hypothesis and test it **minimally** with a throwaway probe.
   - **Hard stop before Phase 4.** Constraints: do **not** write the fix; any probe/instrumentation
     is reverted before the command ends; product code is left unchanged.

3. **Log** → write `ai/diagnoses/<bug-id>.md` (template below).

4. **Severity + shape.** Assign `severity` (critical · major · minor · trivial) and
   `technical_shape` (ui · backend · trivial), from the diagnosis.

5. **File the ticket** via the `notion-board` skill:
   - **Non-trivial:** `Type=Bug`, `Status=TO DO` (the diagnosis is the spec — spec-review is
     skipped), `severity` set. ACs: (a) "the bug no longer reproduces" and (b) "regression test
     `<name>` added." `refs.diagnosis` → the diagnosis file, `refs.file` → root-cause location,
     `refs.found_in` → `"/apb-debug <date>"`. Mandatory Project relation. Mirror into
     `ai/feature_list.json`.
   - **Trivial:** lightweight `Type=Bug`, `technical_shape=trivial`, `Status=TO DO`. Skips
     spec-review and the simplifier. Offer to fix inline under this ticket — but it is **always**
     PR'd, never a silent fix.
   - Show the draft ticket and wait for explicit confirmation before creating in Notion (matches
     the existing `/tickets` and `/ship` bug-filing convention).

6. **Hand off.** Print exactly:
   ```
   Diagnosis:  ai/diagnoses/<bug-id>.md
   Ticket:     <bug-id> — <title>   (filed · <severity> · status TO DO)
   Root cause: <one line> (<file:line>)
   Next: /apb-plan <bug-id>
   ```
   (`/apb-build <bug-id>` when the trivial inline path was taken and a plan is unnecessary.)

### Constraints (mirroring `/fix`)

- Do **not** apply a fix (except the explicit trivial inline path, which still tickets + PRs).
- Do **not** change any ticket status other than creating the new Bug ticket at `TO DO`.
- Scope is the single reported defect. Do not investigate or file unrelated issues found along
  the way — note them for a separate `/apb-debug` run.

### Bug-id convention

`BUG-<area>-<n>`, consistent with existing ids (`BUG-F7-1`, `BUG-F8-2`, `BUG-MA8-1`). `<area>` is
the related feature slug or a short kebab tag inferred from the root-cause file; `<n>` is the next
index for that area. The command proposes an id and confirms it with the user.

---

## Artifact: `ai/diagnoses/<bug-id>.md`

The durable record of *what was found* — separate from the fix.

```markdown
---
bug-id: <BUG-area-n>
date: <YYYY-MM-DD>
severity: critical | major | minor | trivial
status: diagnosed        # diagnosed → ticketed → fixed (updated by pipeline)
---

# <bug-id> — <short title>

## Symptom
The observed failure — the verbatim key error line / stack frame, or the described misbehaviour.

## Reproduction
Exact steps to trigger, or "not reproducible — evidence gathered:" followed by the evidence.

## Investigation
What was checked: recent changes (commits/diff), boundary instrumentation results, data-flow
trace. One or two lines per step — the trail, not a transcript.

## Root cause
The confirmed cause, in one or two sentences, with `file:line`. This is the tested hypothesis,
not a guess.

## Blast radius
What else is affected by the same root cause (other routes, callers, environments).

## Proposed fix (direction only)
The approach, 1–2 sentences. NOT the code. The pipeline writes the code.

## Regression test to add
Test name + what it must assert (fails now, passes after the fix). This becomes an AC on the ticket.

## Ruled out
Hypotheses considered and rejected, each with the reason. (Delete if none.)
```

---

## Schema additions (`ai/feature_list.json` tickets)

- `severity` — optional string: `critical | major | minor | trivial`. Present on Bug tickets;
  omitted elsewhere.
- `refs.diagnosis` — optional path to the `ai/diagnoses/<bug-id>.md` file.

Both are additive and optional; existing tickets and tooling are unaffected.

---

## `commands/next.md` change

Add a new **top** priority rule, above the current rule 1:

> **0. Any `Type=Bug` ticket with `severity: critical` and status in {`TO DO`, `DOING`}**
> → surface first.
> - `DOING` → `/apb-build` or `/apb-verify` per state (same logic as rule 1).
> - `TO DO` → `/apb-plan <id>`.

The existing rules 1–4 follow unchanged. Non-critical bugs queue via the normal
`DOING → TO SPEC REVIEW → TO DO` ordering (bugs sit in `TO DO`).

---

## `skills/setup-project` change

- Scaffold `ai/diagnoses/` (with a `.gitkeep`) alongside `ai/plans/`, `ai/verdicts/`,
  `ai/decisions/` when a project is bootstrapped or reconciled.
- Document the optional `severity` and `refs.diagnosis` fields in the ticket-schema section of
  the setup templates / file-templates reference.

---

## Documentation + packaging

| File | Change |
|---|---|
| `commands/debug.md` | **new** command (above) |
| `commands/next.md` | new rule 0 (critical bug priority) |
| `skills/setup-project/SKILL.md` + `references/file-templates.md` | scaffold `ai/diagnoses/`; document `severity` + `refs.diagnosis` |
| `README.md` | pipeline table + command list add `/apb-debug`; describe the debug loop |
| `.claude-plugin/plugin.json` | version `2.1.4 → 2.2.0` (new feature = minor bump) |

**Dogfood (separate, optional — morning-brief repo):** add `/apb-debug` to the pipeline table and
`ai/diagnoses/` to the folder structure in `CLAUDE.md`; the live `POST /brief/run` `NoneType`
error becomes the first real diagnosis (wrong uvicorn entrypoint — booted `pipeline.api.app:create_app`,
the test factory with `db=None`, instead of the production composition root `pipeline.api.main:create_app`).

---

## Validation plan

This is a prompt/skill change (markdown command + skill files), so validation is behavioural, run
against a scratch project or the morning-brief repo:

1. **Context gate:** run `/apb-debug` with no argument → it must ask for the error/description and
   take no other action. Run with a pasted trace → it proceeds.
2. **No-fix invariant** (standard, non-inline path): after a full `/apb-debug` run, `git status`
   shows **only** the new `ai/diagnoses/<id>.md` (and the `feature_list.json` ticket entry) — **no**
   changes to product/source files. Any probe was reverted. (The trivial inline-fix path is the one
   exception, and only when explicitly chosen; it still yields a ticket + PR.)
3. **Diagnosis artifact:** `ai/diagnoses/<id>.md` exists with every section populated (no
   placeholders), root cause carries a `file:line`, and it names a concrete regression test.
4. **Ticket:** a `Type=Bug` ticket is created in Notion (Project relation present) and mirrored in
   `feature_list.json` at `TO DO` with `severity`, ACs, and `refs.diagnosis`. Trivial path yields a
   `technical_shape=trivial` ticket.
5. **Priority:** with a `severity: critical` bug at `TO DO`, `/apb-next` returns that ticket first.
   Downgrade to `major` → normal ordering resumes.
6. **Hand-off:** the command prints the exact `Next: /apb-plan <id>` block.
7. **End-to-end:** take the printed ticket through `plan → build → verify → ship → land`; confirm
   `/apb-build` writes the named regression test first (red), then the fix (green) — i.e. Phase 4
   is executed by the existing pipeline.
8. **Regression:** `/apb-fix`, `/apb-verify`, `/apb-next` (non-critical) behave exactly as before
   for non-bug tickets.

---

## Out of scope / future

- Automatic traceback capture via hooks + a dedicated `debugger` subagent (the "not too automatic"
  layer). Revisit only if manual `/apb-debug` proves too easy to forget.
- A shared severity taxonomy across all ticket types (currently severity is Bug-only).
