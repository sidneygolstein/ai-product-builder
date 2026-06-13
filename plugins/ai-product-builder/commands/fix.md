---
description: Re-enter TDD with verifier failures. Use when /verify returns VERDICT: block. Reads ai/verdicts/<id>.md and restarts implementation focused on the listed failures.
---
/superpowers:subagent-driven-development

Read ai/verdicts/<id>.md. If it does not exist or is empty, ask the user to paste the
VERDICT: block output before continuing.

Confirm the worktree for slice <id> is at .worktrees/<id> and the branch is checked out.

For each failure listed under "Failures to fix":
  1. Write or extend a failing test that exactly captures the failure. Run it — confirm it fails.
  2. Fix the implementation until the test is green.
  3. Re-run the full test suite to confirm no regression.

Constraints:
  - Do NOT fix anything outside the listed failures. Scope is the verifier's list, not the diff.
  - Do NOT change status — only /verify may do that.
  - Do NOT mark the slice complete. Run /verify <id> again when all listed failures are addressed.

After all fixes are green, print:
  Fixed: <N> failures
  Next: /verify <id>
