# AI Product Builder — Pipeline Invariants

These rules apply in any project that uses the `ai-product-builder` plugin.

- Always read `ai/progress.md` and `ai/feature_list.json` before acting.
- Never let the agent that wrote a spec or code review its own work — use spec-reviewer / verifier.
- A ticket is not done until `ai/init.sh` passes and every AC has a green test.
- One ticket per session. Prefer small, independent tickets.
- Teach as you go: explain decisions; write a decision record per ticket.
- Status flow: `TO SPEC REVIEW → TO DO → DOING → TO REVIEW → TO DEPLOY → DONE`. Never skip a step. Never go backward without explicit human instruction.
- Ticket `Type` (Notion property) is one of: `Feature` · `Bug` · `Tech` · `Discovery`.
- `technical_shape` — set in Notion as the `Technical Shape` property at ticket creation, mirrored into `ai/feature_list.json`; determines which gates run:
  - `ui`: full pipeline including spec-reviewer subagent and simplifier.
  - `backend`: full pipeline including spec-reviewer subagent and simplifier (no design handoff required).
  - `trivial`: review inline (no spec-reviewer subagent), skip simplifier and librarian.
- Status writes: always update Notion first, then `ai/feature_list.json`. On local write failure, log to `ai/decisions/divergence-<timestamp>.md` and stop — do not retry blindly.
