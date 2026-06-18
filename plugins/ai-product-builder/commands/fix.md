---
description: Re-enter TDD with verifier failures. Use when /verify returns VERDICT: block. Reads ai/verdicts/<id>.md and restarts implementation focused on the listed failures.
---
Read `ai/verdicts/<id>.md`. If it does not exist or is empty, ask the user to paste the
VERDICT: block output before continuing.

Confirm the worktree for ticket `<id>` is at `.worktrees/<id>` and the branch is checked out.

**Classify failures**
From the "Failures to fix" list, label each failure:
- **INDEPENDENT** — touches files no other failure touches; no shared types or modules.
- **DEPENDENT** — failure B requires the fix from failure A to be in place first, or both touch the same file.

**Dispatch**
For **INDEPENDENT** failures: dispatch in parallel as subagents (multiple Agent calls in the same
response). Each subagent gets: (a) the single failure description, (b) the paths of files to touch,
(c) instruction to write/extend the failing test first, confirm it fails, then fix until green,
then run only that specific test file. Use `claude-haiku-4-5-20251001` as the model.

For **DEPENDENT** failures: fix sequentially in the main session or as sequential subagents.

**Integrate**
After all fixes return: run the full test suite once. Save the output to
`ai/verdicts/<id>-tests.txt` (overwrite if it exists). If anything is red, fix it before
proceeding.

Constraints:
  - Do NOT fix anything outside the listed failures. Scope is the verifier's list, not the diff.
  - Do NOT change status — only /verify may do that.
  - Do NOT mark the ticket complete. Run /verify <id> again when all listed failures are addressed.

After all fixes are green, print:
  Fixed: <N> failures
  Next: /verify <id>
