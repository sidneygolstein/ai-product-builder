---
description: Post-merge cleanup. Use after the PR is approved and merged. Checks out main, pulls, marks the slice DONE, cleans up the worktree and branch, syncs static docs on the final slice of a feature, writes a handoff, and prompts a fresh session.
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

5. **Sync static docs (final slice only)** — read `ai/feature_list.json` and check all slices
   that share the same `feature` slug as the slice just landed.
   - If **all sibling slices are now DONE** (this is the last slice of the feature): run the
     `librarian` subagent. It reads the full ADR corpus (`ai/decisions/<feature>-*.md`) and
     proposes promotions into the nearest CLAUDE.md files — one gated diff at a time. Approve
     or decline each proposal. Carry any "Stale docs to review" items into the handoff (step 6).
   - If **any sibling slice is not yet DONE**: skip — the librarian runs when the last slice lands.
   - If `slice_type` is `trivial`: skip.

6. **Write handoff** — invoke the `handoff` skill. Include:
   - What slice was just shipped (id, title, feature slug)
   - The PR URL
   - Any bugs noted in the PR description (for the next session to pick up)
   - What the next slice or feature is (from ai/feature_list.json, or from the board)
   - Any "Stale docs to review" items the librarian flagged (if step 5 ran)

7. **Prompt fresh session** — print exactly:
   ```
   Handoff written. Run /clear to start a fresh session — the next session will load
   the handoff automatically and know what was just shipped.
   ```
   Do not take any further action.
