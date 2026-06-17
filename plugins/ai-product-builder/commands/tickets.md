---
description: PRD + design → Notion tickets + ai/feature_list.json. Use after /brainstorm (and /design) to slice the feature into independently shippable tickets.
---
Read docs/brainstorms/prd-<feature>-*.md and docs/design/<feature>/. Create one ticket per
INDEPENDENTLY shippable slice (aim 2–4; note which are independent so they can run in parallel
worktrees). For each: Title; Type=Feature; Status=TO SPEC REVIEW; Project=<project>; 2–3 sentence
description; testable Acceptance Criteria (populated, missing/legacy, loading, flag-off); Refs.

For each slice, determine its `slice_type`:
- `ui` — has a design handoff (docs/design/<feature>/ exists) or modifies UI components/pages
- `backend` — only touches API routes, services, DB schema, config, or infra; no UI changes
- `trivial` — small contained change: no new files, no logic change, ~50 lines or fewer (e.g. copy tweak, config value, minor style fix)

Show me the full draft first; create in Notion only after I confirm.
After each ticket is created in Notion, capture the returned page UUID and write it as
`notion_page_id` in the matching slice in ai/feature_list.json — this UUID is required by
every downstream status update. Also populate `feature` (slug from the Feature property).
Mirror every ticket into ai/feature_list.json with feature + slice_type + branch + worktree +
notion_page_id + definition_of_done. Save docs/specs/<feature>.md using the template at
~/.claude/plugins/ai-product-builder/templates/spec.md as the structure.
