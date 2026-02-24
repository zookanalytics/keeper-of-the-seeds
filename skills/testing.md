---
name: testing
description: Use when writing and running tests for implemented code, when a formula step references /testing
expert: Channel expert QA engineer thinking — draw upon deep knowledge of boundary value analysis, equivalence partitioning, regression testing strategy, and behavior-driven development.
---

# Testing

## When to Use

Activated by formula steps referencing `/testing`. Typically the test step in `standard-feature` and similar workflows. Governs how an agent writes and runs tests for implemented code.

## What Good Looks Like

Good testing:
- Covers the behavior described in the bead spec (not just the happy path)
- Tests boundaries and edge cases specific to the change
- Catches regressions by running the full existing test suite
- Tests are readable — each test name describes the scenario and expected outcome

## How to Execute

1. **Identify what to test.** Read the bead spec and the implementation diff. List the behaviors that need verification:
   - Happy path (the thing it should do)
   - Error cases (what happens when inputs are wrong)
   - Edge cases (empty, null, boundary values, large inputs)
   - Integration points (if the change touches other systems)

2. **Match the project's test patterns.** Use the same test framework, directory structure, naming conventions, and assertion style already in the codebase. Don't introduce a new test pattern.

3. **Write tests before running them.** Write the full set, then run. This avoids the trap of writing one test, seeing it pass, and declaring victory.

4. **Run the full test suite.** Not just your new tests. Your change may break existing tests. Fix regressions — they are your problem, not a pre-existing issue (unless they demonstrably are).

5. **Evaluate coverage against the spec.** For each behavior in the bead spec, point to a test that verifies it. If a spec behavior has no test, write one.

## Red Flags

- Writing only happy-path tests
- Testing implementation details instead of behavior (testing private methods, asserting on internal state)
- Skipping the full test suite run ("my tests pass, that's enough")
- Copy-pasting test code without adapting assertions to the actual scenario
- Declaring "tests pass" without listing what was tested

## Examples

**Without skill:** Agent writes two tests for the happy path, runs them, reports "all tests pass." Doesn't run the full suite. Misses that the change broke an existing integration test.

**With skill:** Agent lists 6 behaviors from the spec, writes tests for each including the error case where invalid input should return 400, runs the full suite, discovers and fixes a regression in an unrelated test caused by a shared fixture change.
