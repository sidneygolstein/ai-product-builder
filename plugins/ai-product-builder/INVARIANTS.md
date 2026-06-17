# AI Product Builder — Pipeline Invariants

These rules apply in any project that uses the `ai-product-builder` plugin.

- Always read `ai/progress.md` and `ai/feature_list.json` before acting.
- Never let the agent that wrote a spec or code review its own work — use spec-reviewer / verifier.
- A slice is not done until `ai/init.sh` passes, every AC has a green test, and browser verification passes (UI slices only — skip if `refs.design` is empty or `"none"` and no `docs/design/<feature>/` directory exists).
- One slice per session. Prefer small, independent slices.
- Teach as you go: explain decisions; write a decision record per slice.
- Status flow: `TO SPEC REVIEW → TO DO → DOING → TO REVIEW → TO DEPLOY → DONE`. Never skip a step. Never go backward without explicit human instruction.
- Slice types — set in `ai/feature_list.json` at ticket creation, determine which gates run:
  - `ui`: full pipeline including spec-reviewer subagent, simplifier, and browser verification.
  - `backend`: full pipeline except browser verification (skip it — mark N/A).
  - `trivial`: review inline (no spec-reviewer subagent), skip simplifier and browser verification.
- Status writes: always update Notion first, then `ai/feature_list.json`. On local write failure, log to `ai/decisions/divergence-<timestamp>.md` and stop — do not retry blindly.
