---
description: Gate 3 — simplify + PR + decision record. Use after /verify passes to clean up, open the PR, link the Notion ticket, and write the decision record.
---
Run the simplifier subagent (no behaviour change) → status TO DEPLOY. Then commit on the slice
branch, push, open a PR; write the description from the plan (ai/plans/<id>.md); link the
Notion ticket. Use the teacher subagent to write
ai/decisions/<feature>-<slice-id>-<slug>.md (hypothesis, alternatives, why, kill criteria)
and append a recap to ai/progress.md. After I approve the PR, set status DONE.
