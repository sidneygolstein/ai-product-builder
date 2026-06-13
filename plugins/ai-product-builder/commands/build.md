---
description: TDD implementation via subagents per slice. Use after /plan is approved. Failing tests first, then code until green.
requires: superpowers plugin (superpowers:subagent-driven-development). For UI slices: frontend-design skill. If either is not found, proceed without it — apply TDD discipline directly: write failing tests, then implement until green.
---
/superpowers:subagent-driven-development
Implement slice <id> per the approved plan (ai/plans/<id>.md) in its worktree. TDD: failing
tests first, then code until green. If a design handoff exists at docs/design/<feature>/,
build UI with the frontend-design skill to match it. Keep the tree clean.
Do NOT mark complete or change status — the verifier decides that.
