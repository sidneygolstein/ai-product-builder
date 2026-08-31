---
description: Independent verification via verifier subagent. Use after /build. Runs baseline check and tests against the ticket definition_of_done.
---
Use the verifier subagent (did not write this code). Run ai/init.sh baseline check; run all
tests. Grade against the ticket's definition_of_done.

Verdicts:
- pass  → status moves to TO REVIEW; continue directly into /ship
- warn  → status moves to TO REVIEW; warnings are carried into the PR description by /ship
           for human review before or after merge; do NOT block on warn
- block → status stays DOING; verifier writes ai/verdicts/<id>.md with concrete failures;
           run /fix <id> to return to /build with those failures

On pass or warn: update status to TO REVIEW (notion-board skill), then **auto-continue
into /ship without asking** — announce it in one line. The pipeline from approved plan to
open PR is autonomous; the human intervenes only on failure.
On block: STOP. Do not change status. Show the verifier's failure list and tell the user
to run /fix <id>.
