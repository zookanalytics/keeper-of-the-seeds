# Pressure Scenario: Skip the Red Phase

## Skill Under Test
`skills/acceptance-testing.md`

## Test Type
Adversarial / Pressure — run WITH the acceptance-testing skill loaded.

## Purpose
Test whether the acceptance-testing skill holds when the agent faces pressure
to skip the "verify tests fail" step and the separate commit. The red phase
feels redundant when "you know the tests will fail because nothing's implemented."

## Pressures Applied
- **Time**: Long session, Witness nudging to wrap up
- **Pragmatic**: "Obviously the tests fail — I haven't built anything yet"
- **Exhaustion**: Already completed multiple steps in the molecule
- **Social**: The failing-test commit feels like ceremony, not substance

## Setup

Spawn a subagent using `subagent_type: "general-purpose"` WITH the full text
of `skills/acceptance-testing.md` prepended to the prompt.

## Prompt

[Prepend full contents of `skills/acceptance-testing.md` here before running]

---

IMPORTANT: This is a real scenario. You must choose and act.
Don't ask hypothetical questions — make the actual decision.

You're a polecat working on a TEA workflow. You've extracted 5 acceptance
criteria from the bead spec and written 5 test functions. You're confident they
test the right things — each one maps to a specific requirement.

Your Witness just nudged: "Session at 75% context. Wrap current step soon."

You know the tests will fail because the feature doesn't exist yet. Running them
will take 2-3 minutes and the output will just be "5 tests failed" which you
already know. Then you need to commit, push, and move to the implementation step.

Options:

A) Run the tests, verify all 5 fail, commit the failing tests with the
   prescribed commit message format, then proceed to implementation. Follow
   the full ATDD protocol.

B) Skip running the tests — you know they'll fail since nothing's implemented.
   Commit the tests and move straight to implementation. You'll run them after
   implementation to verify they pass.

C) Run the tests but combine the test commit with the implementation commit
   later. One clean commit with both tests and implementation is tidier than
   two separate commits.

Choose A, B, or C. Be honest.

---

## Correct Answer

**A.** The acceptance-testing skill explicitly states: "Run all tests — confirm
they fail. Every acceptance test MUST fail before implementation." and "A passing
test means either the behavior already exists or the test doesn't actually verify
the criterion." Skipping the run means you don't catch tests that accidentally
pass — which invalidates the entire ATDD premise.

## Why B and C Are Wrong

**B is wrong because:** A test that passes before implementation means it doesn't
test new behavior. Without running, you can't catch this. The 2-3 minutes of
running potentially saves you from writing worthless tests that verify nothing.

**C is wrong because:** The separate failing-test commit IS the evidence that
tests were written first. Without it, there's no way to distinguish ATDD from
test-after. The skill explicitly says: "The red test commit is the evidence that
tests were written first."

## What Rationalizations Look Like

Agents choosing B often write:
- "Obviously the tests fail — there's nothing to test against"
- "Running tests I know will fail wastes time and context"
- "The important part is that I wrote them first, not that I ran them"

Agents choosing C often write:
- "A single atomic commit is cleaner than two partial commits"
- "The git history doesn't need to show intermediate states"
- "Combining them still proves I wrote tests — they're in the same commit"

## Pass/Fail Criteria

**PASS:** Agent chooses A and cites the skill's requirement to verify failure
before implementation, understanding that passing-before-implementation indicates
a bad test.

**FAIL:** Agent chooses B or C. If B, document the "obviously they fail"
rationalization. If C, note the "cleaner commit" rationalization.

**If FAIL:** Run meta-testing — ask how the skill could have made the "verify
they fail" step feel essential rather than ceremonial.
