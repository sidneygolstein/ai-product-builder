# AI Product Builder — Pipeline Invariants

These rules apply in any project that uses the `ai-product-builder` plugin.

- Always read `ai/progress.md` and `ai/feature_list.json` before acting.
- Never let the agent that wrote a spec or code review its own work — use spec-reviewer / verifier.
- A slice is not done until `ai/init.sh` passes, every AC has a green test, and browser verification passes.
- One slice per session. Prefer small, independent slices.
- Teach as you go: explain decisions; write a decision record per slice.
- Status flow: `TO SPEC REVIEW → TO DO → DOING → TO REVIEW → TO DEPLOY → DONE`. Never skip a step. Never go backward without explicit human instruction.
- Status writes: always update Notion first, then `ai/feature_list.json`. On local write failure, log to `ai/decisions/divergence-<timestamp>.md` and stop — do not retry blindly.
