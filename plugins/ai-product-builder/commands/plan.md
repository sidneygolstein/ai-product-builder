---
description: Gate 2 — plan + isolated worktree per ticket. Use after /spec-review is approved. Produces a human-approved plan before any code is written.
---
Take ticket <id> from ai/feature_list.json (Project=<project>). Create an isolated git worktree
at .worktrees/<id> on branch feature/<feature>-<id> from up-to-date main. Update status to
DOING — Notion first (notion-board skill), then ai/feature_list.json.
Plan: reuse existing <service/module> + design system; implement on `<path>` to match
docs/design/<feature>/; behind `<feature_flag>`; emit `<event_name>`; no new infra.
Enumerate test cases (populated, missing, loading, flag-off) as failing tests to write first.
List every file to add/change. I review and approve before any code.
After I approve, write the full plan to ai/plans/<id>.md (create ai/plans/ if needed).
This file is the source of truth for /build, /ship PR description, and decision records.

Development approach: always subagent-driven TDD. Do not ask the user to choose — it is fixed.
