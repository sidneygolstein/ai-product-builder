---
description: Optional — PRD → Claude Design handoff. Use between /brainstorm and /tickets for UI features. Skip for backend-only tickets.
---
# /design — PRD → design handoff
#
# OPTIONAL — skip for backend-only tickets.
# If the feature has no UI component, skip this command entirely and go straight to /tickets.
#
# This stage has three parts. Run (a) first, do (b) manually on the Claude Design surface,
# then return here and run (c) before opening /tickets.

---

## Part (a) — Write the brief (run in Claude Code)

Read docs/brainstorms/prd-<feature>-*.md. If the feature has no UI, tell me to skip design.
Otherwise write docs/design/<feature>/prompt.md: a brief for Claude Design that asks it to
(1) first request screenshots of the current <path> + our design system for consistency;
(2) propose 2 distinct design options to choose from; (3) design ALL states — populated,
missing/legacy, loading, flag-off (hidden); (4) on approval, output a developer handoff
(components, layout, spacing, tokens, copy, states) + exported images + a how-to-implement.md
listing exactly which files to add/modify. English only, reuse the design system, no new infra.

---

## Part (b) — Claude Design (manual human step — NOT in Claude Code)

Open Claude Design. Paste the contents of docs/design/<feature>/prompt.md.
Iterate, choose one of the two options, then save the exported visuals and how-to-implement.md
back into docs/design/<feature>/ before running part (c).

---

## Part (c) — Ingest the handoff (run in Claude Code, after part (b))

Read docs/design/<feature>/how-to-implement.md and the exported visuals. Summarize the chosen
design, list every component/file it says to add or change, and confirm all four states are
specified. Flag anything ambiguous BEFORE we ticket it.

Append a refs block to the PRD at `docs/brainstorms/prd-<feature>-*.md` (after the last line):

```
---
design_handoff: docs/design/<feature>/how-to-implement.md
```

This allows `/tickets` to find the handoff path when building `feature_list.json` entries.
