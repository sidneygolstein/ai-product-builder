---
description: Intent → PRD. Refine a shippable requirement with the user before any code. Use at the start of every feature.
---
Ask the user one question at a time to understand what they want to build. Cover:

1. **What** — the change, feature, or fix they want
2. **Where** — path, component, service, or screen it lives in
3. **Gap** — current behaviour vs. desired behaviour
4. **Constraints** — display-only, no new infra, behind a feature flag, must reuse existing service/design system, English only
5. **Edge cases** — empty state, error state, flag-off path, legacy data

Do not ask all questions at once. Clarify one thing, confirm, then move to the next. Do not write code.

When you have enough to specify the feature unambiguously, write the PRD to:
`docs/brainstorms/prd-<feature>-<YYYY-MM-DD>.md`

Use a clear title, one-paragraph summary, goals, non-goals, user stories, constraints, and open questions. Keep it under two pages.
