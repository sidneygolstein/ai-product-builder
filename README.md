# ai-product-builder

A Claude Code plugin that encodes the full AI product development pipeline — from intent to shipped PR — as installable commands, subagents, skills, and hooks.

**Philosophy:** the human owns product and design decisions; the AI executes and documents. Three human gates enforce this. Independent subagents prevent self-review.

## Pipeline

```
/brainstorm → /design (optional) → /tickets → /spec-review → /plan → /build → /verify → /ship
                                                   ↑ Gate 1          ↑ Gate 2         ↑ Gate 3
```

Each stage is a slash command. Each gate requires explicit human approval before the next stage starts.

| Stage | Command | Agent involved | Output |
|---|---|---|---|
| 1 | `/brainstorm` | — | PRD in `docs/brainstorms/` |
| 2 | `/design` | — | Brief + handoff in `docs/design/` (optional — skip for backend-only) |
| 3 | `/tickets` | — | Notion tickets + `ai/feature_list.json` |
| Gate 1 | `/spec-review` | `spec-reviewer` | GO/NO-GO per ticket; applies edits |
| Gate 2 | `/plan` | — | Human-approved plan; worktree created |
| 5 | `/build` | — | TDD: failing tests first, then green |
| Gate 3-prep | `/verify` | `verifier` | pass / warn / block with evidence |
| Gate 3 | `/ship` | `simplifier`, `teacher` | PR + decision record |

## Install

```bash
claude plugin marketplace add sidneygolstein/ai-product-builder
claude plugin install ai-product-builder@sidneygolstein --scope user
```

## Commands

### `/brainstorm`
Refines a shippable requirement one question at a time. Writes a PRD to `docs/brainstorms/prd-<feature>-<date>.md`. No code. Uses `superpowers:brainstorming` to ensure intent is clear before any spec work.

### `/design` (optional)
Three-part process — skip for backend-only slices:
- **(a) In Claude Code:** reads the PRD and writes `docs/design/<feature>/prompt.md` — a brief for Claude Design requesting screenshots, two design options, all four states (populated, missing, loading, flag-off), and a developer handoff.
- **(b) Manual:** open Claude Design, paste the brief, iterate, choose one option, save exports and `how-to-implement.md` to `docs/design/<feature>/`.
- **(c) In Claude Code:** ingests the handoff, flags ambiguities, and records the path in `refs` so `/tickets` and `/plan` reference it.

### `/tickets`
Reads the PRD and design handoff; creates one independently shippable Notion ticket per slice (aim 2–4). Each ticket has: Title, Type, Status=TO SPEC REVIEW, 2–3 sentence description, testable ACs covering all four states, and Refs. Mirrors every ticket into `ai/feature_list.json`. Shows a draft first — creates in Notion only after confirmation. Saves `docs/specs/<feature>.md`.

### `/spec-review` — Gate 1
Dispatches the `spec-reviewer` subagent (did not author the tickets). Checks shippability, AC testability, edge-case coverage (null/empty, long input, partial data, flag-off, internal-data exposure), and scope. Returns GO/NO-GO per ticket and applies required edits. On human approval, moves passing tickets to TO DO.

### `/plan` — Gate 2
Creates an isolated git worktree at `.worktrees/<id>` on a feature branch. Enumerates failing tests to write first and every file to change. Sets status to DOING. Human approves the plan before any code is written. Uses `superpowers:writing-plans`.

### `/build`
TDD implementation via subagents per slice. Failing tests first, then code until green. Builds UI with the `frontend-design` skill when a design handoff exists. Does not mark the slice complete — the verifier decides.

### `/verify` — Gate 3 prep
Dispatches the `verifier` subagent (did not write the code). Runs `ai/init.sh` (baseline), then the test suite, then Playwright browser verification for each AC state, then checks every `definition_of_done` item. Outputs `VERDICT: pass | warn | block` with evidence. Only `pass` allows status to move to TO REVIEW.

### `/ship` — Gate 3
Runs `simplifier` subagent (no behaviour change) → moves to TO DEPLOY. Commits, pushes, opens a PR sourced from `ai/plans/<id>.md` with a link to the Notion ticket. Runs `teacher` subagent to write `ai/decisions/<feature>-<slice-id>-<slug>.md` and append a recap to `ai/progress.md`. After human PR approval, sets status DONE.

## Subagents

| Agent | When | Independence guarantee | Tools |
|---|---|---|---|
| `spec-reviewer` | Gate 1 — after `/tickets` | Did not author the tickets or specs | `Read`, `mcp__notion` |
| `verifier` | Gate 3-prep — after `/build` | Did not write the code | `Read`, `Bash`, `mcp__playwright` |
| `simplifier` | Inside `/ship` — before PR | Cannot fix bugs or change scope | `Read`, `Edit` |
| `teacher` | Inside `/ship` — after merge | Writes history, not code | `Read`, `Edit`, `mcp__notion` |

The Stop hook blocks session close if `ai/init.sh` fails. Verifier pass is enforced by convention at Gate 3 — `/ship` will not proceed without one. Subagents run in isolated contexts — an agent that touched code in this session cannot verify it.

## Skills

| Skill | Purpose |
|---|---|
| `setup-project` | Bootstraps or migrates any repo to the harness in one guided session: interviews one question at a time, resolves Notion IDs, imports non-DONE tickets, writes all files, merges CLAUDE.md and hooks, registers the project in the Projects database. |
| `notion-board` | Exact property names, status values, MCP call sequence, and write-order rules for the Ticket Backlog. Required by `/tickets`, `/spec-review`, `/plan`, `/verify`, `/ship`. |
| `decision-record` | ADR template and writing discipline: context, decision, alternatives, kill criteria, gotchas. Written by the `teacher` agent at every `/ship`; can also be invoked manually for mid-session decisions. |

## Hooks

Five hooks fire automatically — no configuration needed after install.

| Event | Script | What it does |
|---|---|---|
| `SessionStart` | `session-start.sh` | Scaffolds `ai/` if missing; prints `ai/progress.md`; runs `ai/init.sh` (informational — never blocks); audits CLAUDE.md coverage. |
| `PreToolUse(Bash)` | `destructive-guard.sh` | Blocks `rm -rf`, force-push, and reads of `.env` files before they run. Anti-footgun, not anti-malicious. |
| `PostToolUse(Edit/Write)` | `post-tool-format.sh` | Auto-formats the file just written using the project's available formatters (Prettier/ESLint for TS/JS, Ruff for Python, gofmt for Go, rustfmt for Rust). Silently skips if no formatter is available. |
| `Stop` | `baseline-stop.sh` | Refuses to close the session if `ai/init.sh` exits non-zero. Keeps the baseline green before context is lost. |
| `SubagentStop` | `baseline-stop.sh` | Same check applied to subagent sessions. |

## Invariants

These rules are injected into every project's CLAUDE.md via `@~/.claude/plugins/ai-product-builder/INVARIANTS.md`:

- Always read `ai/progress.md` and `ai/feature_list.json` before acting.
- Never let the agent that wrote a spec or code review its own work — use spec-reviewer / verifier.
- A slice is not done until `ai/init.sh` passes, every AC has a green test, and browser verification passes.
- One slice per session. Prefer small, independent slices.
- Teach as you go: explain decisions; write a decision record per slice.

## Per-project setup

Each repo that uses this plugin needs an `ai/` folder:

```
ai/
├── config/
│   └── notion.json         # Notion database UUIDs (ticket_db_id, project_id, ...)
├── feature_list.json       # backlog + slices + ACs + definition_of_done (machine-readable)
├── progress.md             # session handoff log + teacher recaps
├── plans/                  # approved plan per slice — written by /plan, read by /build + /ship
├── decisions/              # per-slice decision records (ADRs)
└── init.sh                 # baseline check: test && lint [&& typecheck]
```

Run `/setup-project` — it interviews you one question at a time, resolves Notion IDs automatically, imports existing tickets, writes all files, and merges CLAUDE.md and hook config. Or bootstrap manually:

```bash
mkdir -p ai/config ai/decisions
cp ~/.claude/plugins/cache/sidneygolstein-ai-product-builder/ai-product-builder/templates/feature_list.json ai/
cp ~/.claude/plugins/cache/sidneygolstein-ai-product-builder/ai-product-builder/templates/progress.md ai/
cp ~/.claude/plugins/cache/sidneygolstein-ai-product-builder/ai-product-builder/templates/init.sh ai/ && chmod +x ai/init.sh
```

Then edit `ai/init.sh` with this repo's real test/lint/build command, and create `ai/config/notion.json` with your Ticket Backlog and Projects database UUIDs.

## Required MCPs

| MCP | Used by |
|---|---|
| **Notion** | `/tickets`, `/spec-review`, `/plan`, `/verify`, `/ship`, `notion-board` skill |
| **Playwright** | `verifier` subagent (browser verification in `/verify`) |
| **GitHub** | `/ship` (PR creation) |

## Status flow

```
TO SPEC REVIEW → TO DO → DOING → TO REVIEW → TO DEPLOY → DONE
```

Status values are case-sensitive. Both the Notion ticket and `ai/feature_list.json` must always reflect the same value — the `notion-board` skill enforces write order to prevent divergence.

| Status | Set by | When |
|---|---|---|
| `TO SPEC REVIEW` | `/tickets` | Ticket created |
| `TO DO` | `/spec-review` | Gate 1 passed, human approved |
| `DOING` | `/plan` | Gate 2 passed, worktree created |
| `TO REVIEW` | `/verify` | Verifier returned `pass` |
| `TO DEPLOY` | `/ship` | Simplifier attested no behaviour change |
| `DONE` | `/ship` | PR merged, human approved |
