# ai-product-builder

A Claude Code plugin that encodes the full AI product development pipeline — from intent to shipped PR — as installable commands, subagents, skills, and hooks.

**Philosophy:** the human owns product and design decisions; the AI executes and documents. Three human gates enforce this. Independent subagents prevent self-review.

## Pipeline

```
/brainstorm → /design (optional) → /tickets → /spec-review → /plan → /build → /verify → /ship
                                                    ↑ Gate 1          ↑ Gate 2          ↑ Gate 3
```

Each stage is a slash command. Each gate requires explicit human approval before the next stage starts.

## Install

```bash
claude plugin marketplace add sidneygolstein/ai-product-builder
claude plugin install ai-product-builder@sidneygolstein --scope user
```

## Commands

| Command | Stage | What it does |
|---|---|---|
| `/brainstorm` | 1 | Intent → PRD. Refines a shippable requirement one question at a time. |
| `/design` | 2 | PRD → Claude Design brief + handoff ingestion. Optional; skip for backend-only slices. |
| `/tickets` | 3 | PRD + design → Notion tickets + `ai/feature_list.json`. |
| `/spec-review` | Gate 1 | Independent spec-reviewer subagent: GO/NO-GO per ticket. |
| `/plan` | Gate 2 | Plan + isolated git worktree per slice. Human approves before any code. |
| `/build` | 5 | TDD via subagents. Failing tests first, code until green. |
| `/verify` | Gate 3-prep | Independent verifier: baseline + tests + browser. pass/warn/block. |
| `/ship` | Gate 3 | Simplify + PR + decision record. Human approves PR. |

## Subagents

| Agent | Role | Tools |
|---|---|---|
| `spec-reviewer` | Skeptical GO/NO-GO on specs — did not author them | `Read`, `mcp__notion` |
| `verifier` | Runs `ai/init.sh` + tests + Playwright — did not write the code | `Read`, `Bash`, `mcp__playwright` |
| `simplifier` | Cleans structure without changing behaviour | `Read`, `Edit` |
| `teacher` | Writes decision record + progress recap after every shipped slice | `Read`, `Edit`, `mcp__notion` |

## Skills

- **`notion-board`** — exact property names, status flow, and MCP tools for the Ticket Backlog
- **`decision-record`** — ADR template with context, decision, alternatives, kill criteria
- **`setup-project`** — bootstraps `ai/` memory folder in a new repo

## Per-project setup

Each repo that uses this plugin needs an `ai/` folder:

```
ai/
├── feature_list.json   # backlog + slices + ACs + definition_of_done (machine-readable)
├── progress.md         # session handoff log + teacher recaps
├── decisions/          # per-slice decision records
└── init.sh             # baseline check: npm test && npm run lint (or equivalent)
```

Bootstrap it with `/setup-project`, or manually:

```bash
mkdir -p ai/decisions
cp ~/.claude/plugins/cache/sidneygolstein-ai-product-builder/ai-product-builder/templates/feature_list.json ai/
cp ~/.claude/plugins/cache/sidneygolstein-ai-product-builder/ai-product-builder/templates/progress.md ai/
cp ~/.claude/plugins/cache/sidneygolstein-ai-product-builder/ai-product-builder/templates/init.sh ai/ && chmod +x ai/init.sh
```

Then edit `ai/init.sh` with this repo's real test/lint/build command.

## Invariants

These rules are encoded in `~/.claude/CLAUDE.md` when you follow the setup guide:

- Read `ai/progress.md` + `ai/feature_list.json` before any planning or coding
- Never let the agent that wrote a spec or code review its own work
- A slice is not done until `ai/init.sh` exits 0 + all ACs green + browser verification passes
- One slice per session
- Write a decision record for every shipped slice

## Required MCPs

- **Notion** — ticket board reads/writes
- **Playwright** — browser verification in `/verify`
- **GitHub** — PR creation in `/ship`

## Status flow

```
TO SPEC REVIEW → TO DO → DOING → TO REVIEW → TO DEPLOY → DONE
```

Transitions are hook-driven. See `plugins/ai-product-builder/hooks/hooks.json` for the scaffold.
