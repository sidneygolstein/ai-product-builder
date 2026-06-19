# ai-product-builder — v2.1.3

A Claude Code plugin that encodes the full AI product development pipeline — from intent to shipped PR — as installable commands, subagents, skills, and hooks.

**Philosophy:** the human owns product and design decisions; the AI executes and documents. Three human gates enforce this. Independent subagents prevent self-review.

## Pipeline

```
/brainstorm → /design (optional) → /tickets → /spec-review → /plan → /build → /verify → /ship → /land
                                                   ↑ Gate 1          ↑ Gate 2         ↑ Gate 3
```

Each stage is a slash command. Each gate requires explicit human approval before the next stage starts.

| Stage | Command | Agent involved | Output |
|---|---|---|---|
| anytime | `/next` | — | Highest-priority ticket + exact command to run |
| 1 | `/brainstorm` | — | PRD in `docs/brainstorms/` |
| 2 | `/design` | — | Brief + handoff in `docs/design/` (optional — skip for backend-only) |
| 3 | `/tickets` | — | Notion tickets + `ai/feature_list.json` with `technical_shape` |
| Gate 1 | `/spec-review` | `spec-reviewer` (ui/backend) or inline (trivial) | pass/block per ticket; applies edits |
| Gate 2 | `/plan` | — | Human-approved plan written to `ai/plans/<id>.md`; worktree created |
| 5 | `/build` | — | TDD: failing tests first, then green; saves suite output to `ai/verdicts/<id>-tests.txt` |
| Gate 3-prep | `/verify` | `verifier` | pass / warn / block with evidence; writes `ai/verdicts/<id>.md` on block |
| on block | `/fix <id>` | — | Re-enter TDD from verifier failures in `ai/verdicts/<id>.md` |
| Gate 3 | `/ship` | `simplifier` (ui/backend only), `teacher` | PR + decision record shown inline to user; status → TO DEPLOY |
| post-merge | `/land` | `librarian` (final ticket of feature only) | Checkout main, mark DONE, clean up, sync CLAUDE.md, write handoff |

## Ticket types and technical shape

Each ticket carries a Notion `Type` (`Feature` · `Bug` · `Tech` · `Discovery`) and a `Technical Shape` (`ui` · `backend` · `trivial`). The human sets `Technical Shape` in Notion at ticket creation; `/tickets` mirrors it into `ai/feature_list.json` as `technical_shape`. The technical shape determines which pipeline gates run:

| Technical Shape | Description | Gates skipped |
|---|---|---|
| `ui` | Has a design handoff or modifies UI components/pages | None — full pipeline |
| `backend` | Only touches API, service, DB, config, or infra layers | None — full pipeline (no design handoff required) |
| `trivial` | Small contained change: no new files, no logic change, ~50 lines max | `spec-reviewer` subagent, simplifier subagent |

## Install

```bash
claude plugin marketplace add sidneygolstein/ai-product-builder
claude plugin install ai-product-builder@sidneygolstein --scope user
```

## Commands

### `/brainstorm`
Refines a shippable requirement one question at a time. Writes a PRD to `docs/brainstorms/prd-<feature>-<date>.md`. No code.

### `/design` (optional)
Three-part process — skip for backend-only tickets:
- **(a) In Claude Code:** reads the PRD and writes `docs/design/<feature>/prompt.md` — a brief for Claude Design requesting screenshots, two design options, all four states (populated, missing, loading, flag-off), and a developer handoff.
- **(b) Manual:** open Claude Design, paste the brief, iterate, choose one option, save exports and `how-to-implement.md` to `docs/design/<feature>/`.
- **(c) In Claude Code:** ingests the handoff, flags ambiguities, and records the path in `refs` so `/tickets` and `/plan` reference it.

### `/tickets`
Reads the PRD and design handoff; creates one independently shippable Notion ticket per unit of work (aim 2–4). Reads each ticket's `Technical Shape` (`ui`, `backend`, or `trivial`) directly from Notion — set by the human at creation, not inferred — and mirrors it as `technical_shape` in `ai/feature_list.json`. Each ticket has: Title, Type (`Feature` · `Bug` · `Tech` · `Discovery`), Status=TO SPEC REVIEW, 2–3 sentence description, testable ACs covering all four states, and Refs. Shows a draft first — creates in Notion only after confirmation. Saves `docs/specs/<feature>.md`.

### `/spec-review` — Gate 1
Route depends on `technical_shape`:
- **`ui` / `backend`:** dispatches the `spec-reviewer` subagent (did not author the tickets). Checks shippability, AC testability, edge-case coverage (null/empty, long input, partial data, flag-off, internal-data exposure), and scope. Returns pass/block per ticket and applies required edits.
- **`trivial`:** reviewed inline by the main session (no subagent). Verifies the change is genuinely small and that at least one testable AC exists.

On human approval, updates status to TO DO in Notion then `ai/feature_list.json`.

### `/plan` — Gate 2
Creates an isolated git worktree at `.worktrees/<id>` on a feature branch. Enumerates failing tests to write first and every file to change. Updates status to DOING in Notion then `ai/feature_list.json`. Human approves the plan before any code is written. Development approach is always subagent-driven TDD.

### `/build`
TDD implementation via context-preloaded subagents. Main session gathers all context first (plan, source file paths, test files, design handoff), then classifies tasks as INDEPENDENT or DEPENDENT — defaulting to INDEPENDENT; only marking DEPENDENT when task B concretely uses code or types that task A must produce first. Independent tasks are dispatched in parallel (multiple agents in one response); dependent chains run strictly sequentially. Each subagent receives file paths (not pasted content) and runs TDD: failing test first, implement until green, then scope-only tests to confirm local correctness. Full suite runs once at integrate, and output is saved to `ai/verdicts/<id>-tests.txt` for the verifier to read. Does not mark the ticket complete — the verifier decides.

### `/next`
Read-only. Reads `ai/feature_list.json`, applies priority order (DOING → TO SPEC REVIEW → TO DO → none), and prints the single highest-priority ticket with the exact command to run. Use at session start when unsure what to work on.

### `/verify` — Gate 3 prep
Dispatches the `verifier` subagent (did not write the code). Runs `ai/init.sh` (baseline), reads cached test results from `ai/verdicts/<id>-tests.txt` if available (re-runs the suite only if the file is missing), then checks browser verification and every `definition_of_done` item. Browser verification is skipped (`N/A`) for `backend` and `trivial` tickets. Outputs `VERDICT: pass | warn | block` with evidence.
- `pass` — status moves to TO REVIEW; proceed to `/ship`
- `warn` — status moves to TO REVIEW; warnings are carried into the PR description for human review
- `block` — status stays DOING; verifier writes `ai/verdicts/<id>.md`; run `/fix <id>`

### `/fix <id>`
Re-enters TDD from a verifier block. Reads `ai/verdicts/<id>.md`, addresses each listed failure with a targeted failing test then implementation, runs scope-only tests to confirm local correctness, then runs the full suite once to confirm no cross-ticket regression. Saves the output to `ai/verdicts/<id>-tests.txt`. Does not change status — run `/verify` again when done.

### `/ship` — Gate 3
Route depends on `technical_shape`:
- **`ui` / `backend`:** runs `simplifier` subagent (no behaviour change) before opening the PR.
- **`trivial`:** skips the simplifier — proceeds directly to PR.

Updates status to TO DEPLOY in Notion then `ai/feature_list.json`. Commits, pushes, opens a PR sourced from `ai/plans/<id>.md` with a link to the Notion ticket. If the simplifier flags potential bugs, prompts the user to return to `/build` or open a follow-up Bug ticket (with all required properties including the `Project` relation). Runs `teacher` subagent which **returns the full decision record inline** — the user reads, validates, and corrects the captured reasoning before the session closes. The teacher writes `ai/decisions/<feature>-<ticket-id>-<slug>.md`, appends a recap to `ai/progress.md`, and conditionally proposes CLAUDE.md additions for the user to approve. On PR approval, updates status to DONE in Notion then `ai/feature_list.json`.

### `/land` — post-merge
Run after the PR is approved and merged. Checks out main, pulls, sets status DONE in both Notion and `ai/feature_list.json`, removes the ticket worktree and branch (with confirmation).

**Final-ticket sync (static docs):** if all sibling tickets for the feature are now DONE, runs the `librarian` subagent. The librarian reads the full ADR corpus (`ai/decisions/<feature>-*.md`) for the feature, identifies conventions that emerged across multiple tickets, and proposes promotions into the nearest CLAUDE.md files — one gated diff at a time. Architecture/API docs that look stale are flagged in the handoff but never auto-edited. Skipped for trivial tickets and for any `/land` that is not the final one for its feature.

Writes a handoff via the `handoff` skill (including any stale-doc flags from the librarian) and prompts `/clear` for a clean next session.

## Subagents

| Agent | When | Independence guarantee | Tools |
|---|---|---|---|
| `spec-reviewer` | Gate 1 — after `/tickets` (ui/backend only) | Did not author the tickets or specs | `Read`, `mcp__notion` |
| `verifier` | Gate 3-prep — after `/build` | Did not write the code | `Read`, `Bash` |
| `simplifier` | Inside `/ship` — before PR (ui/backend only) | Cannot fix bugs or change scope | `Read`, `Edit` |
| `teacher` | Inside `/ship` — after merge | Writes history, not code; **returns full decision record inline to the user** | `Read`, `Edit`, `Write` |
| `librarian` | Inside `/land` — final ticket of a feature only | Reads ADR corpus, not code | `Read`, `Edit`, `Bash` |

Verifier pass is enforced by convention at Gate 3 — `/ship` will not proceed without one. Subagents run in isolated contexts — an agent that touched code in this session cannot verify it.

## Skills

| Skill | Purpose |
|---|---|
| `setup-project` | Bootstraps or migrates any repo to the harness in one guided session: interviews one question at a time, resolves Notion IDs, imports non-DONE tickets, writes all files, merges CLAUDE.md and hooks, registers the project in the Projects database. |
| `notion-board` | Exact property names, status values, MCP call sequence, and write-order rules for the Ticket Backlog. Required by `/tickets`, `/spec-review`, `/plan`, `/verify`, `/ship`. Caches `ai/config/notion.json` within the session to avoid redundant reads. |
| `decision-record` | ADR template and writing discipline: context, decision, alternatives, kill criteria, gotchas. Written by the `teacher` agent at every `/ship`; can also be invoked manually for mid-session decisions. |

## Hooks

Three hooks fire automatically — no configuration needed after install.

| Event | Script | What it does |
|---|---|---|
| `SessionStart` | `session-start.sh` | Scaffolds `ai/` if missing; prints `ai/progress.md`; runs `ai/init.sh` with a 30s timeout (informational — never blocks); audits CLAUDE.md coverage (cached daily in `/tmp`). |
| `PreToolUse(Bash)` | `destructive-guard.sh` | Blocks `rm -rf`, force-push, and reads of `.env` files before they run. Anti-footgun, not anti-malicious. |
| `PostToolUse(Edit/Write)` | `post-tool-format.sh` | Auto-formats the file just written using the project's available formatters (Prettier/ESLint for TS/JS, Ruff for Python, gofmt for Go, rustfmt for Rust). Silently skips if no formatter is available. |

## Invariants

These rules are injected into every project's CLAUDE.md via `@~/.claude/plugins/ai-product-builder/INVARIANTS.md`:

- Always read `ai/progress.md` and `ai/feature_list.json` before acting.
- Never let the agent that wrote a spec or code review its own work — use spec-reviewer / verifier.
- A ticket is not done until `ai/init.sh` passes, every AC has a green test, and browser verification passes (UI tickets only — skip for `backend` and `trivial` technical shapes).
- One ticket per session. Prefer small, independent tickets.
- Teach as you go: explain decisions; write a decision record per ticket.
- Ticket `Type` (Notion) is one of `Feature` · `Bug` · `Tech` · `Discovery`. `technical_shape` (`ui` / `backend` / `trivial`) is set in Notion as the `Technical Shape` property and determines which gates run — see the Ticket types and technical shape table above.

## Per-project setup

Each repo that uses this plugin needs an `ai/` folder:

```
ai/
├── config/
│   └── notion.json         # Notion database UUIDs (ticket_db_id, project_id, ...)
├── feature_list.json       # backlog + tickets + ACs + definition_of_done (machine-readable)
├── progress.md             # session handoff log + teacher recaps
├── plans/                  # approved plan per ticket — written by /plan, read by /build + /ship
├── verdicts/               # verifier output per ticket — written on block, read by /fix
│                           # also: <id>-tests.txt — full suite output from /build, read by /verify
├── decisions/              # per-ticket decision records (ADRs)
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
| `TO DEPLOY` | `/ship` | Simplifier attested no behaviour change (or trivial ticket bypassed simplifier) |
| `DONE` | `/land` | PR merged, main pulled, worktree cleaned |
