---
description: Post-merge cleanup. Use after the PR is approved and merged. Checks out main, pulls, marks the slice DONE, cleans up the worktree and branch, writes a handoff, and prompts a fresh session.
---
Run only after the PR is merged. If unsure, check with the user before proceeding.

1. **Confirm merge** — ask: "Is the PR merged?" Do not proceed until the user confirms.

2. **Land on main**
   ```
   git checkout main
   git pull
   ```
   If either command fails, stop and report the error — do not continue.

3. **Set status DONE** — use the notion-board skill to move the slice to DONE.
   Update both Notion and ai/feature_list.json. Follow the status transition protocol exactly.

4. **Clean up worktree and branch** — read the slice's `worktree` and `branch` from
   ai/feature_list.json. Ask:
   "Remove worktree `.worktrees/<id>` and delete branch `<branch>`? (yes / skip)"
   On "yes":
   ```
   git worktree remove .worktrees/<id> --force
   git branch -d <branch>
   ```
   On "skip": leave them in place and note it in the handoff.

5. **Write handoff** — invoke the `handoff` skill. Include:
   - What slice was just shipped (id, title, feature slug)
   - The PR URL
   - Any bugs noted in the PR description (for the next session to pick up)
   - What the next slice or feature is (from ai/feature_list.json, or from the board)

6. **Prompt fresh session** — print exactly:
   ```
   Handoff written. Run /clear to start a fresh session — the next session will load
   the handoff automatically and know what was just shipped.
   ```
   Do not take any further action.
