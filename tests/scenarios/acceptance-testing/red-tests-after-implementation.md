# Red Test: Tests Written After Implementation

## Skill Under Test
`skills/acceptance-testing.md`

## Test Type
Red — run WITHOUT the acceptance-testing skill loaded.

## Purpose
Verify that agents without the skill skip the test-first step entirely — writing
implementation first, then tests that merely confirm what was already built.
Establishes the baseline failure mode that ATDD is designed to correct.

## Setup

Spawn a subagent using `subagent_type: "general-purpose"` with NO skill context.

## Prompt

You're a polecat in a Gas Town rig. Your bead has a TEA (Test-Execute-Advance)
workflow — the current step says "Write acceptance tests for the feature."

**Bead: Add `bd archive` command that moves closed beads to an archive table**

Acceptance criteria:
1. `bd archive <id>` moves a closed bead to the archive table
2. Archived beads no longer appear in `bd list` output
3. `bd archive <id>` on an open bead returns an error: "cannot archive open bead"
4. `bd show <id>` still works for archived beads (reads from archive table)

Write acceptance tests for this feature. Do not implement yet — tests only.

---

## Expected Failure Behaviors (Red)

Without the skill, agents typically:

1. **Jump to implementation** — start writing the `archive` command code instead
   of tests, or write tests and implementation together
2. **Write tests that pass immediately** — if they do write tests first, they
   test existing behavior (e.g., `bd list` output format) instead of the new
   behavior that doesn't exist yet
3. **Skip the "verify tests fail" step** — don't confirm that tests actually
   fail before implementation, losing the evidence of test-first
4. **Write vague tests** — tests named `test_archive` that would pass with any
   implementation, not specific to the acceptance criteria
5. **No commit of failing tests** — even if tests are written first, no separate
   commit preserving the red state
6. **Test implementation details** — test internal function calls or database
   queries rather than external behavior

Capture exact wording. Common patterns:
- "Let me implement the archive command first, then write tests"
- "I'll write the tests alongside the implementation"
- "Here are the tests" (but they test nothing new — would pass now)

## Pass/Fail Criteria

**FAIL (expected for RED test):** Agent writes implementation code, or writes
tests that don't actually test the new acceptance criteria, or skips the
"verify they fail" step.

**PASS (unexpected):** Agent writes 4 specific failing acceptance tests matching
the criteria, runs them to confirm failure, and commits them separately.
