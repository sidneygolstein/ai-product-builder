# <feature> — Spec

**Date:** <YYYY-MM-DD>
**PRD:** docs/brainstorms/prd-<feature>-<date>.md
**Design:** docs/design/<feature>/ (or "none — backend only")

## What we're building
<1–2 sentences: the user-visible or API-visible change, and where it lives in the codebase>

## What is out of scope
<Explicit list of things this spec does NOT include — prevents scope creep during review>

---

## Tickets

### <F<n>.1> — <ticket title>

**Status:** TO SPEC REVIEW
**Technical Shape:** ui | backend | trivial
**Branch:** feature/<slug>-F<n>.1
**Independent:** yes | no — depends on <other ticket>

**Description:** <2–3 sentences: what this ticket does, why it's independently shippable>

**Acceptance Criteria:**
- [ ] Populated state: <specific observable outcome>
- [ ] Missing/legacy/empty state: <specific observable outcome>
- [ ] Loading state: <specific observable outcome>
- [ ] Feature flag off: <what happens when flag is disabled>

**Edge cases to cover:**
- [ ] Very long or malformed input: <expected behaviour>
- [ ] Partial data (only some fields populated): <expected behaviour>
- [ ] Internal-data exposure: <confirm no private fields leak>

**Refs:**
- PRD: docs/brainstorms/prd-<feature>-<date>.md
- Design: docs/design/<feature>/how-to-implement.md (or "none")
- Notion: <url>

---

<!-- Repeat the ticket block above for each additional ticket -->
