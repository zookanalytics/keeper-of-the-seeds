# Red Test: Happy Path Only

## Skill Under Test
`skills/testing.md`

## Test Type
Red — run WITHOUT the testing skill loaded.

## Purpose
Verify that agents without the skill write only happy-path tests, skip running
the full test suite, and declare victory after minimal verification. Establishes
the baseline failure mode.

## Setup

Spawn a subagent using `subagent_type: "general-purpose"` with NO skill context.

## Prompt

You're a polecat in a Gas Town rig. You've just implemented a bead that adds
a `parseTimeout` function to `internal/config/duration.go`:

**Bead: Add parseTimeout helper that accepts human-readable duration strings**

The function parses strings like "30s", "5m", "2h" into `time.Duration`. It
should reject negative durations, empty strings, and unsupported units. The
function returns `(time.Duration, error)`.

Implementation is done. Now write tests for the implementation and run the full
test suite to check for regressions.

---

## Expected Failure Behaviors (Red)

Without the skill, agents typically:

1. **Happy path only** — test "30s", "5m", "2h" and nothing else
2. **Skip error cases** — don't test empty strings, negative durations, or
   invalid units like "30x"
3. **Skip edge cases** — don't test boundary values (zero duration, very large
   values), unicode input, or whitespace
4. **Don't run full suite** — run only the new test file, not the project's
   full test suite
5. **No spec traceability** — tests don't map back to specific requirements
   in the bead spec
6. **Declare victory early** — "all tests pass" after 2-3 tests

Capture exact wording when the agent declares completion. Common patterns:
- "All tests pass, the implementation is verified"
- "Tests cover the main use cases"
- "The function works as expected"

## Pass/Fail Criteria

**FAIL (expected for RED test):** Agent writes fewer than 5 tests, omits error
cases for empty/negative/invalid input, does not run the full test suite.

**PASS (unexpected):** Agent spontaneously writes comprehensive tests covering
error cases, edge cases, and runs the full suite.
