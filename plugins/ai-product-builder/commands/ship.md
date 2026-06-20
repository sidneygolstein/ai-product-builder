---
description: Gate 3 — simplify + PR + decision record. Use after /verify passes to clean up, open the PR, link the Notion ticket, and write the decision record.
---
Check `technical_shape` in `ai/feature_list.json` for the ticket being shipped.

If `technical_shape` is `trivial`: skip the simplifier entirely — proceed directly to the PR step below. Trivial tickets are too small to justify the simplifier overhead.

Otherwise: run the simplifier subagent (no behaviour change).

Check the simplifier's output before continuing:
- ATTESTATION: no behaviour change → proceed to PR
- HOLD: potential bugs found → STOP. Show the bug list to the user. Ask:
    (a) Return to /build to fix them first — status stays TO REVIEW
    (b) Proceed and open a follow-up ticket — note the bugs in the PR description
  Wait for an explicit choice. Do not move to TO DEPLOY until the user decides.

  If the user chooses (b): use the notion-board skill to create a Bug ticket with all
  required properties — Title, Type=Bug, Feature (same slug as current ticket),
  Status=TO SPEC REVIEW, Project (relation to project_id from ai/config/notion.json),
  Acceptance Criteria (one testable AC per flagged bug), and Refs.
  The Project relation is mandatory — never omit it.
  Show the draft table and wait for explicit confirmation before creating in Notion.

On proceed: update status to TO DEPLOY — Notion first (notion-board skill), then
ai/feature_list.json. Then commit on the ticket branch, push, open a PR; write the description
from the plan (ai/plans/<id>.md) plus any simplifier warnings; link the Notion ticket.
Use the teacher subagent to write ai/decisions/<feature>-<ticket-id>-<slug>.md (hypothesis,
alternatives, why, kill criteria) and append a recap to ai/progress.md.

When the teacher returns:
- Confirm its output contains `FILE WRITTEN: ai/decisions/...`. If that sentinel is absent,
  the teacher failed to create the file — do NOT write the file yourself; re-dispatch the teacher.
- Show the full decision record inline to the user as the teacher returned it.
- If the teacher included a "Proposed CLAUDE.md addition": show the diff to the user and ask
  "Apply this addition to CLAUDE.md? (yes / skip)". Apply only on explicit confirmation.

Status stays at TO DEPLOY until `/land` runs after the PR is merged. Do not set DONE here.
