# ai-product-builder — Plugin Source

This repo is the source for the `ai-product-builder` Claude Code plugin, published to the `sidneygolstein` marketplace. It contains the full pipeline for building AI-powered products from brainstorm to shipped PR.

## Repo structure

```
plugins/ai-product-builder/   ← plugin source (edit here)
  .claude-plugin/plugin.json  ← version, name, author
  agents/                     ← subagents dispatched by commands
  commands/                   ← slash commands (/build, /plan, etc.)
  hooks/                      ← shell scripts for SessionStart / PreToolUse / PostToolUse
  skills/                     ← skills loaded on demand (notion-board, setup-project, etc.)
  templates/                  ← scaffolding files copied into consumer projects
  INVARIANTS.md               ← always-on rules injected into every consumer CLAUDE.md
ai/                           ← APB pipeline state for this repo itself (meta)
```

## Versioning convention

| Change type | Version bump |
|---|---|
| New agent, new command, new behavior | Minor (1.12.x → 1.13.0) |
| Bug fix, prompt tweak, wording | Patch (1.13.0 → 1.13.1) |
| Breaking change to data schema or status flow | Major (1.x → 2.0.0) |

Always update `plugins/ai-product-builder/.claude-plugin/plugin.json` and `README.md` together.

## Releasing a new version

After committing and pushing to `main`:

```bash
claude plugin marketplace update sidneygolstein-ai-product-builder
claude plugin update ai-product-builder   # user scope; restart Claude Code to apply
```

## Key design rules

- **One ticket per session.** Each pipeline run handles exactly one ticket end-to-end.
- **Independent subagents at every quality gate.** The agent that wrote the code never verifies it.
- **Notion is optional** (`ai/config/notion.json` → `notion_enabled`). When enabled it is the system of record: always write Notion first, then `ai/feature_list.json`, never reverse. When disabled, `ai/feature_list.json` is the sole source of truth and no MCP call is made.
- **Auto-chain after Gate 2.** Once the plan is approved, `/build → verify → ship` runs to an open PR without prompts; humans intervene only on verifier `block`, simplifier `HOLD`, a CLAUDE.md proposal, or a third consecutive fix-loop block.
- **technical_shape drives gate selection.** Set by the human at ticket creation, mirrored into `ai/feature_list.json`. `ui` = full pipeline. `backend` = skip simplifier (verifier flags complexity) and design handoff. `trivial` = skip spec-reviewer, simplifier, and librarian; build inline. Canonical definition: `plugins/ai-product-builder/INVARIANTS.md` — keep the two in sync.
- **Teacher returns full output.** Never summarize — paste the full decision record inline so the user can validate before the session closes.
- **Librarian runs once per feature** (final `/land` only, when all sibling tickets are DONE). It synthesizes cross-ticket ADRs into CLAUDE.md. Never runs mid-feature.

## Agent responsibilities (at a glance)

| Agent | Trigger | Reads | Writes |
|---|---|---|---|
| `spec-reviewer` | `/spec-review` (ui/backend only) | Tickets, specs | Edits to tickets + specs |
| `verifier` | `/verify` | Diff, tests, init.sh | `ai/verdicts/<id>.md` |
| `simplifier` | `/ship` (ui only, or on request) | Diff | ATTESTATION or HOLD |
| `teacher` | `/ship` | Diff, PRD, spec | ADR, progress recap — **returned inline to user** |
| `librarian` | `/land` (final ticket only) | All ADRs for feature | CLAUDE.md promotions |

## Working on the plugin itself

The `ai/` folder in this repo tracks improvements to the plugin as a product. Use `/next` to see what's queued, `/plan` to start a ticket, etc. — the plugin dogfoods itself.
