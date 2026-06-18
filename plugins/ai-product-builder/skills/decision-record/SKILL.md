---
name: decision-record
description: Write an Architecture Decision Record in ai/decisions/ or docs/decisions/. Use when explicitly asked to write an ADR or decision record, when a meaningful alternative was debated and rejected, or at the close of every /ship. Trigger on "write an ADR", "log this decision", "create a decision record", or /ship close-out. Do NOT fire on retrospective summaries, general "why did we…" questions, or post-mortems.
---

# Decision Record

How to write a decision record in the ai-product-builder pipeline.

Do not skip. Undocumented decisions become archaeology problems for the next developer.

## Inputs required before writing

Gather these before starting. If any are missing, ask — do not invent context.

- `<feature>` slug (from `ai/feature_list.json` → `feature`)
- `<ticket-id>` (format `F<n>.<m>`, from the ticket being shipped)
- The PR diff or merge commit (reference only; do not restate in the record)
- The plan file at `ai/plans/<ticket-id>.md` if one exists (for Alternatives considered)

## Which kind of record

| Situation | Location | Naming |
|---|---|---|
| Decision scoped to one ticket | `ai/decisions/` | `<feature>-<ticket-id>-<slug>.md` |
| Decision that constrains future tickets or the whole project | `docs/decisions/` | `ADR-NNN-<slug>.md` |

When unsure, use `docs/decisions/` — ticket records are easy to migrate down; project decisions buried in `ai/` are lost.

**Finding the next ADR number:**
```bash
ls docs/decisions/ADR-*.md 2>/dev/null | sort | tail -1
```
Parse `NNN`, increment by 1, zero-pad to 3 digits. If `docs/decisions/` does not exist, create it and start at `ADR-001`.

The `<slug>` is always required, even for ticket records. Use kebab-case, 3–5 words (e.g., `zustand-brief-store-shape`, `rss-polling-interval`).

## When to write one

- **Every shipped ticket** — mandatory, written by the `teacher` agent at `/ship` close (teacher uses this exact template and filename convention)
- Any mid-session decision where an alternative was meaningfully considered (stack, schema, provider, major refactor)
- When a future developer would otherwise have to reverse-engineer the reasoning from the code

**Do not write one for:** dependency bumps, lint config tweaks, single-line bug fixes, or reverts.

## Template

```markdown
# <feature> / <ticket-id> — <Short title>

**Date:** <run: date -u +%Y-%m-%d>
**Status:** Shipped | Proposed | Deprecated

## Context
Why this decision was needed. What problem were we solving, what constraints were in play,
and what would have happened without this change.

## Decision
What was decided and how it works. Hard limit: 80 words. If you cannot fit it in 80 words,
split into two separate decision records.

## Alternatives considered
<!-- Delete this section entirely if no alternatives were genuinely considered.
     Do not leave placeholder rows. Each row needs a concrete reason. -->

| Option | Why ruled out |
|--------|---------------|
| ...    | Concrete reason ("higher latency", "no batch API", "team unfamiliar") |

## Why this approach
The actual reasoning — constraints honoured, trade-offs accepted, existing patterns reused.
Explain *why*, not *what* — the diff already shows what changed.

## Consequences
What becomes easier, what becomes harder, what new constraints this introduces.

## Kill criteria
Each criterion must specify: metric · threshold · measurement source · revisit trigger.
Example: "If p95 latency on `briefs.fetch` exceeds 200ms (source: Langfuse →
`brief_pipeline.p95_ms`) for 3 consecutive days → revisit the polling strategy."

## Gotchas
Non-obvious invariants, constraints, or surprises baked into this implementation that a
competent reader of the code would not see. Omit anything self-evident from the code.
```

## Status lifecycle

| Status | When | How |
|---|---|---|
| `Proposed` | Written before implementation | Default for pre-ship ADRs |
| `Shipped` | Set by teacher agent at `/ship` close | Edit frontmatter in place |
| `Deprecated` | When a later ADR supersedes this one | Edit status + add `**Superseded by:** ADR-NNN` at top; do not delete the file. Also edit the superseding ADR to add `**Supersedes:** ADR-MMM`. |

## Writing discipline

- Explain *why*, never *what* — the diff already shows what changed.
- Kill criteria must be measurable, owned, and have a revisit trigger. Vague formulations are rejected.
- "Gotchas" must surprise a competent reader — not restate the implementation.
- "Alternatives considered": if no alternatives were genuinely considered, delete the section entirely. Never leave `...` placeholders.

## Done when

The file is written at the correct path, the file path is returned to the caller, and — if this supersedes an existing ADR — the older file has been updated with `**Superseded by:**`.
