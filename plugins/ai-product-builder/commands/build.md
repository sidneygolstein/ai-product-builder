---
description: TDD implementation via context-preloaded subagents per slice. Use after /plan is approved. Main session gathers context first, then dispatches subagents with a full brief — parallel for independent tasks, sequential for dependent ones.
requires: superpowers plugin (superpowers:dispatching-parallel-agents). For UI slices: frontend-design skill. If not found, apply TDD discipline directly: write failing tests, then implement until green.
---
/superpowers:dispatching-parallel-agents

**Step 1 — Gather context (main session, before any dispatch)**
Read: `ai/plans/<id>.md`, every file listed under "files to add/change", existing test files for
the slice, `docs/design/<feature>/` if a UI handoff exists. Do this now, in the main session,
before dispatching anything.

**Step 2 — Classify tasks**
From the plan, list every task or AC. Label each:
- **INDEPENDENT** — touches files no other task touches; introduces no types, interfaces, or
  modules that another task depends on.
- **DEPENDENT** — task B uses code task A creates, or both modify the same file.

When in doubt, mark DEPENDENT. Never dispatch two DEPENDENT tasks in parallel.

**Step 3 — Dispatch**
For each **INDEPENDENT** group: dispatch subagents in parallel. Each agent gets a self-contained
brief with: (a) the relevant plan section, (b) the exact files to touch (paste content),
(c) the failing tests to write first, (d) constraint: "do NOT touch files outside your scope,
do NOT change status."

For each **DEPENDENT** chain: dispatch subagents strictly sequentially. Wait for one to return
before dispatching the next. Pass the previous agent's output as additional context to the next.

Each subagent follows TDD: write the failing test first, run it to confirm it fails, implement
until green, run the full suite to confirm no regression. If a design handoff exists at
`docs/design/<feature>/`, build UI with the frontend-design skill to match it.

**Step 4 — Integrate**
When all agents return: run the full test suite once across the entire worktree. If anything
is red, investigate conflicts between agents before re-dispatching.

**Simplicity ladder** — before writing any implementation code, stop at the first rung that holds:
1. Does this need to exist at all? Speculative need = skip it. (YAGNI)
2. Does the stdlib cover it? Use it.
3. Does a native platform feature cover it? (`<input type="date">` over a picker lib, CSS over JS, DB constraint over app code.) Use it.
4. Does an already-installed dependency solve it? Use it. Never add a new dep for what a few lines can do.
5. Can it be one line? One line.
6. Only then: the minimum code that works.

Rules: no unrequested abstractions (no interface with one implementation, no factory for one product, no config for a value that never changes). Fewest files possible. Shortest working diff wins. Mark deliberate simplifications with a `ponytail:` comment naming the ceiling and the upgrade path — e.g. `// ponytail: global lock, per-account locks if throughput matters`.

Do NOT mark complete or change status — the verifier decides that.
