---
description: Gate 3 — simplify + PR + decision record. Use after /verify passes to clean up, open the PR, link the Notion ticket, and write the decision record.
---
Run the simplifier subagent (no behaviour change).

Check the simplifier's output before continuing:
- ATTESTATION: no behaviour change → proceed to PR
- HOLD: potential bugs found → STOP. Show the bug list to the user. Ask:
    (a) Return to /build to fix them first — status stays TO REVIEW
    (b) Proceed and open a follow-up ticket — note the bugs in the PR description
  Wait for an explicit choice. Do not move to TO DEPLOY until the user decides.

  If the user chooses (b): use the notion-board skill to create a Bug ticket with all
  seven required properties — Title, Type=Bug, Feature (same slug as current slice),
  Status=TO SPEC REVIEW, Project (relation to project_id from ai/config/notion.json),
  Acceptance Criteria (one testable AC per flagged bug), and Refs.
  The Project relation is mandatory — never omit it.
  Show the draft table and wait for explicit confirmation before creating in Notion.

On proceed: set status TO DEPLOY. Then commit on the slice branch, push, open a PR;
write the description from the plan (ai/plans/<id>.md) plus any simplifier warnings;
link the Notion ticket. Use the teacher subagent to write
ai/decisions/<feature>-<slice-id>-<slug>.md (hypothesis, alternatives, why, kill criteria)
and append a recap to ai/progress.md. After I approve the PR, set status DONE.
