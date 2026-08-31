# AI Product Builder — Pipeline Invariants

These rules apply in any project that uses the `ai-product-builder` plugin.

- Always read `ai/progress.md` and `ai/feature_list.json` before acting.
- Never let the agent that wrote a spec or code review its own work — use spec-reviewer / verifier.
- A ticket is not done until `ai/init.sh` passes and every AC has a green test.
- One ticket per session. Prefer small, independent tickets.
- Teach as you go: explain decisions; write a decision record per ticket.
- Status flow: `TO SPEC REVIEW → TO DO → DOING → TO REVIEW → TO DEPLOY → DONE`. Never skip a step. Never go backward without explicit human instruction.
- Ticket `Type` (Notion property) is one of: `Feature` · `Bug` · `Tech` · `Discovery`.
- `technical_shape` — set by the human at ticket creation (Notion `Technical Shape` property when Notion is enabled, otherwise directly in `ai/feature_list.json`); determines which gates run:
  - `ui`: full pipeline including spec-reviewer subagent and simplifier.
  - `backend`: full pipeline with spec-reviewer subagent; skip simplifier (verifier flags complexity as warnings) and design handoff.
  - `trivial`: review inline (no spec-reviewer subagent), skip simplifier and librarian.
- Auto-chain: after the human approves the plan at Gate 2, `/build → verify → ship` runs without further prompts, ending at an open PR. It stops for a human only on: verifier `block`, simplifier `HOLD`, a CLAUDE.md proposal, or a third consecutive block in the fix loop.
- Status writes: read `notion_enabled` from `ai/config/notion.json`. Enabled → update Notion first, then `ai/feature_list.json`; on local write failure, log to `ai/decisions/divergence-<timestamp>.md` and stop — do not retry blindly. Disabled → `ai/feature_list.json` is the sole source of truth; never call Notion.
