---
description: Independent verification via verifier subagent. Use after /build. Runs baseline, tests, and browser verification against the slice definition_of_done.
---
Use the verifier subagent (did not write this code). Run ai/init.sh baseline check; run all
tests; run browser verification (Playwright MCP) for each AC state. Grade against the slice's
definition_of_done.

Verdicts:
- pass  → status moves to TO REVIEW; proceed to /ship
- warn  → status moves to TO REVIEW; warnings are carried into the PR description by /ship
           for human review before or after merge; do NOT block on warn
- block → status stays DOING; verifier writes ai/verdicts/<id>.md with concrete failures;
           run /fix <id> to return to /build with those failures

On pass or warn: update status to TO REVIEW (Notion + ai/feature_list.json).
On block: do not change status; tell the user to run /fix <id>.
