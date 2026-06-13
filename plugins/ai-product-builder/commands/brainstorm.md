---
description: Intent → PRD. Refine a shippable requirement with the user before any code. Use at the start of every feature.
requires: superpowers plugin (superpowers:brainstorming). If the skill is not found, proceed without it and apply the same discipline manually — one question at a time, no code, write the PRD to docs/brainstorms/.
---
/superpowers:brainstorming
I want to <change> on `<path>` in <project>: <what should appear/happen>. Today <current
behaviour>, but <gap>. Constraint: <e.g. display-only, no new LLM call>, behind `<feature_flag>`,
emits `<event_name>`, reuses existing <service/module> + design system, English only, no new infra.
Refine into a shippable requirement — one question at a time, no code. Cover <key unknowns/edge cases>.
Write to docs/brainstorms/prd-<feature>-<date>.md.
