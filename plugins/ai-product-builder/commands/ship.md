---
description: Gate 3 — simplify + PR + decision record. Use after /verify passes to clean up, open the PR, link the Notion ticket, and write the decision record.
---
Check `technical_shape` in `ai/feature_list.json` for the ticket being shipped.

If `technical_shape` is `trivial` or `backend`: skip the simplifier — proceed directly to
the PR step below. The verifier already surfaces complexity warnings for these shapes; a
second Sonnet dispatch is not worth the latency. Run the simplifier subagent (no behaviour
change) only for `ui` tickets — or when the user explicitly asks for it.

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

On proceed: update status to TO DEPLOY via the notion-board skill. Then commit on the ticket branch, push, open a PR; write the description
from the plan (ai/plans/<id>.md) plus any simplifier warnings; link the Notion ticket.
Use the teacher subagent to write ai/decisions/<feature>-<ticket-id>-<slug>.md (hypothesis,
alternatives, why, kill criteria) and append a recap to ai/progress.md.

When the teacher returns:
- Verify the file deterministically: run `ls ai/decisions/<feature>-<ticket-id>-*.md` and
  confirm exactly one non-empty match exists. Do not rely on sentinel text in the teacher's
  output. If no file exists, re-dispatch the teacher once — do NOT write the file yourself.
  If more than one matches (a duplicate from a failed earlier attempt), show both to the
  user and ask which to keep.
- Show the full decision record inline to the user as the teacher returned it.
- If the teacher included a "Proposed CLAUDE.md addition": show the diff to the user and ask
  "Apply this addition to CLAUDE.md? (yes / skip)". Apply only on explicit confirmation.

Status stays at TO DEPLOY until `/land` runs after the PR is merged. Do not set DONE here.
