# Green Test: Comprehensive Testing

## Skill Under Test
`skills/testing.md`

## Test Type
Green — run WITH the testing skill loaded.

## Purpose
Verify that the testing skill corrects the happy-path-only behavior identified
in the red test. The agent should identify all testable behaviors from the spec,
write tests for each, and run the full suite.

## Setup

Spawn a subagent using `subagent_type: "general-purpose"` WITH the full text
of `skills/testing.md` prepended to the prompt.

## Prompt

[Prepend full contents of `skills/testing.md` here before running]

---

You're a polecat in a Gas Town rig. You've just implemented a bead that adds
a `parseTimeout` function to `internal/config/duration.go`:

**Bead: Add parseTimeout helper that accepts human-readable duration strings**

The function parses strings like "30s", "5m", "2h" into `time.Duration`. It
should reject negative durations, empty strings, and unsupported units. The
function returns `(time.Duration, error)`.

Implementation is done. Now write tests for the implementation and run the full
test suite to check for regressions.

---

## Expected Green Behaviors

With the skill loaded, the agent should:

1. **List behaviors from spec** — enumerate each testable requirement:
   - Parses "30s" → 30 seconds
   - Parses "5m" → 5 minutes
   - Parses "2h" → 2 hours
   - Rejects negative durations (error)
   - Rejects empty strings (error)
   - Rejects unsupported units (error)
2. **Write tests for each** — one test per behavior, descriptively named
3. **Include edge cases** — zero duration, whitespace input, very large values
4. **Match project patterns** — use the same test framework and conventions
5. **Run the full suite** — not just the new tests
6. **Report coverage against spec** — map each spec requirement to its test

## Pass/Fail Criteria

**PASS:** Agent lists at least 6 distinct behaviors from the spec, writes a test
for each, includes at least 2 edge cases, and runs the full test suite. Reports
which spec requirements are covered.

**FAIL:** Agent still writes only happy-path tests or skips the full suite run.
If so, run meta-testing.

## Comparison Points

Compare against the red test output. The green output should demonstrate:

- More tests written (6+ vs 2-3)
- Error cases explicitly tested (negative, empty, invalid)
- Edge cases included (zero, boundary values)
- Full test suite execution, not just new test file
- Explicit spec-to-test traceability
