---
description: Gate 1 — independent spec review via spec-reviewer subagent. Use after /tickets to validate ACs and edge cases before any code is written.
---
For each ticket in TO SPEC REVIEW, Project=<project>:

Check `technical_shape` in `ai/feature_list.json`:

- **`trivial` tickets**: review inline in the main session (no spec-reviewer subagent). Verify:
  (1) the change is genuinely small and contained — no new files, no new logic, ~50 lines max;
  (2) at least one testable AC exists. On confirmation, update status to TO DO via the
  notion-board skill.

- **`ui` and `backend` tickets**: use the spec-reviewer subagent (you did NOT write these).
  Is scope truly shippable? Are ACs testable? What edge cases are missing
  (<legacy/empty, very long input, partial/malformed data, flag off, internal-data exposure>)?
  Over/under-specified? Apply edits to the ticket + docs/specs + ai/feature_list.json.
  Return a short go/no-go per ticket. Do NOT write code. On my approval, update status to
  TO DO via the notion-board skill.
