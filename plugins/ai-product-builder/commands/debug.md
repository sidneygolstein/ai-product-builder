---
description: Front door for a bug found by running the app or manual observation. Root-causes it (systematic-debugging), logs it to ai/diagnoses/, and files a Bug ticket — WITHOUT fixing. The fix flows through the normal /plan → build → verify → ship → land pipeline.
---
`/apb-debug` diagnoses and tickets a defect. It NEVER writes the fix (except the explicit
trivial inline path, which still produces a ticket + PR).

**1. Context gate — required.**
If the user pasted an error / stack trace / description with the command, use it. Otherwise ASK
and WAIT — do not investigate without context:
  "Paste the error log / stack trace, or describe the bug — what you did, what happened, what you
   expected, and reproduction steps if you know them."

**2. Root cause — systematic-debugging Phases 1–3 only.**
Invoke the `superpowers:systematic-debugging` skill, scoped to investigation:
  - Phase 1: read the error/stack trace fully (note file:line); reproduce, or record
    "not reproducible — evidence gathered"; check recent changes (`git diff`, recent commits);
    in a multi-component path, instrument boundaries to find the failing layer; trace the bad
    value back to its source.
  - Phase 2: find a working example, compare, list every difference.
  - Phase 3: state ONE hypothesis and test it MINIMALLY with a throwaway probe.
HARD STOP before Phase 4. Constraints:
  - Do NOT write the fix. Do NOT modify product/source code.
  - Revert any probe or instrumentation before finishing — leave the tree clean except the
    diagnosis file.

**3. Log — write `ai/diagnoses/<bug-id>.md`.**
Choose `<bug-id>` as `BUG-<area>-<n>` (area = related feature slug or a short kebab tag from the
root-cause file; n = next index for that area). Propose it and confirm with the user. Write the
file with frontmatter (`bug-id`, `date` from `date -u +%Y-%m-%d`, `severity`, `status: diagnosed`)
and these sections, all populated (no placeholders):
  Symptom · Reproduction · Investigation · Root cause (+ file:line) · Blast radius ·
  Proposed fix (direction only, NOT code) · Regression test to add (name + assertion) · Ruled out.

**4. Severity + shape.**
Assign `severity` (critical · major · minor · trivial) and `technical_shape` (ui · backend ·
trivial) from the diagnosis.

**5. File the ticket — use the `ai-product-builder:notion-board` skill.**
Show the draft ticket and WAIT for explicit confirmation before creating in Notion.
  - Non-trivial: Type=Bug, Status=TO DO (the diagnosis is the spec — spec-review is skipped),
    severity set. Acceptance Criteria: (a) "the bug no longer reproduces"; (b) "regression test
    <name> added". refs.diagnosis → ai/diagnoses/<bug-id>.md, refs.file → root-cause file:line,
    refs.found_in → "/apb-debug <date>". Project relation is MANDATORY. Mirror into
    ai/feature_list.json (id, title, status, type="Bug", technical_shape, severity, branch,
    worktree, notion_page_id, acceptance_criteria, definition_of_done, refs).
  - Trivial: same, but technical_shape="trivial" (skips spec-review AND the simplifier). Offer to
    fix it inline under this ticket now — but it is ALWAYS PR'd, never a silent fix.

**6. Hand off — print exactly:**
```
Diagnosis:  ai/diagnoses/<bug-id>.md
Ticket:     <bug-id> — <title>   (filed · <severity> · status TO DO)
Root cause: <one line> (<file:line>)
Next: /apb-plan <bug-id>
```
(Use `/apb-build <bug-id>` instead when the trivial inline path was taken and no plan is needed.)

Constraints (mirroring /fix):
  - Do NOT apply a fix except the explicit trivial inline path.
  - Do NOT change any ticket status other than creating the new Bug ticket at TO DO.
  - Scope is the single reported defect. Note unrelated issues for a separate /apb-debug run;
    do not chase them here.
