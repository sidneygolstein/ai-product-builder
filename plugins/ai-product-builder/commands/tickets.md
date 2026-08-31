---
description: PRD + design → Notion tickets + ai/feature_list.json. Use after /brainstorm (and /design) to break the feature into independently shippable tickets.
---
Read docs/brainstorms/prd-<feature>-*.md and docs/design/<feature>/. Create one ticket per
INDEPENDENTLY shippable ticket (aim 2–4; note which are independent so they can run in parallel
worktrees). For each: Title; Type (one of Feature · Bug · Tech · Discovery); Status=TO SPEC REVIEW;
Project=<project>; 2–3 sentence description; testable Acceptance Criteria (populated,
missing/legacy, loading, flag-off); Refs.

Technical shape (`ui` · `backend` · `trivial`) is set by the human, never inferred:
- Notion enabled (per `ai/config/notion.json` → `notion_enabled`): read it from the
  Notion ticket's `Technical Shape` property.
- Notion disabled: include a `technical_shape` column in the draft table and ask me to
  fill or confirm it per ticket before writing.

Show me the full draft first; write only after I confirm.
- Notion enabled: create in Notion first (notion-board skill); capture each returned page
  UUID as `notion_page_id` — required by every downstream status update.
- Notion disabled: skip Notion entirely; set `notion_page_id` to `""`.
Also populate `feature` (slug). Mirror every ticket into ai/feature_list.json with
feature + technical_shape + branch + worktree + notion_page_id + definition_of_done. Save docs/specs/<feature>.md using the template at
${CLAUDE_PLUGIN_ROOT}/templates/spec.md as the structure.
