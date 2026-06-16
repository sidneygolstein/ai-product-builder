---
description: Gate 1 — independent spec review via spec-reviewer subagent. Use after /tickets to validate ACs and edge cases before any code is written.
---
Use the spec-reviewer subagent (you did NOT write these). For each ticket in TO SPEC REVIEW,
Project=<project>: is scope truly shippable? are ACs testable? what edge cases are missing
(<legacy/empty, very long input, partial/malformed data, flag off, internal-data exposure>)?
over/under-specified? Apply edits to the ticket + docs/specs + ai/feature_list.json.
Return a short go/no-go per ticket. Do NOT write code. On my approval, update status to TO DO —
Notion first (notion-board skill), then ai/feature_list.json.
