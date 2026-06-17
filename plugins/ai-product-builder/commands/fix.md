---
description: Re-enter TDD with verifier failures. Use when /verify returns VERDICT: block. Reads ai/verdicts/<id>.md and restarts implementation focused on the listed failures.
---
Read `ai/verdicts/<id>.md`. If it does not exist or is empty, ask the user to paste the
VERDICT: block output before continuing.

Confirm the worktree for slice `<id>` is at `.worktrees/<id>` and the branch is checked out.

For each failure listed under "Failures to fix":
  1. Write or extend a failing test that exactly captures the failure. Run it — confirm it fails.
  2. Fix the implementation until the test is green.
  3. Run the tests for the files you changed to confirm no regression within your scope.

After all listed failures are addressed, run the full test suite once to confirm no cross-slice
regression. Save the output to `ai/verdicts/<id>-tests.txt` (overwrite if it exists). If anything
is red, fix it before proceeding.

Constraints:
  - Do NOT fix anything outside the listed failures. Scope is the verifier's list, not the diff.
  - Do NOT change status — only /verify may do that.
  - Do NOT mark the slice complete. Run /verify <id> again when all listed failures are addressed.

After all fixes are green, print:
  Fixed: <N> failures
  Next: /verify <id>
