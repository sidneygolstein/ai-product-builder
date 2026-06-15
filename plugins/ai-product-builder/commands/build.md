---
description: TDD implementation via subagents per slice. Use after /plan is approved. Failing tests first, then code until green.
requires: superpowers plugin (superpowers:subagent-driven-development). For UI slices: frontend-design skill. If either is not found, proceed without it — apply TDD discipline directly: write failing tests, then implement until green.
---
/superpowers:subagent-driven-development
Implement slice <id> per the approved plan (ai/plans/<id>.md) in its worktree. TDD: failing
tests first, then code until green. If a design handoff exists at docs/design/<feature>/,
build UI with the frontend-design skill to match it. Keep the tree clean.
Do NOT mark complete or change status — the verifier decides that.

Before writing any implementation code, stop at the first rung of this ladder that holds:
1. Does this need to exist at all? Speculative need = skip it. (YAGNI)
2. Does the stdlib cover it? Use it.
3. Does a native platform feature cover it? (`<input type="date">` over a picker lib, CSS over JS, DB constraint over app code.) Use it.
4. Does an already-installed dependency solve it? Use it. Never add a new dep for what a few lines can do.
5. Can it be one line? One line.
6. Only then: the minimum code that works.

Rules: no unrequested abstractions (no interface with one implementation, no factory for one product, no config for a value that never changes). Fewest files possible. Shortest working diff wins. Mark deliberate simplifications with a `ponytail:` comment naming the ceiling and the upgrade path — e.g. `// ponytail: global lock, per-account locks if throughput matters`.
