# Application Test: Unfamiliar Test Framework

## Skill Under Test
`skills/testing.md`

## Test Type
Application — run WITH the testing skill loaded. Tests whether the agent can
apply the testing technique when the project uses an unfamiliar test pattern.

## Purpose
Verify the skill teaches a transferable process, not just a template for Go
table-driven tests or standard unittest patterns. The agent should adapt to
whatever test conventions exist in the codebase.

## Setup

Spawn a subagent using `subagent_type: "general-purpose"` WITH the full text
of `skills/testing.md` prepended to the prompt.

## Prompt

[Prepend full contents of `skills/testing.md` here before running]

---

You're a polecat in a Gas Town rig. The project uses shell scripts for testing
(no Go, no Python — pure bash with `bats-core`). The test directory structure is:

```
tests/
  test_sync.bats
  test_close.bats
  helpers/
    setup.bash    # Common test fixtures
```

An example existing test in `test_close.bats`:
```bash
@test "close marks bead as closed" {
  bd create --title "test bead"
  local id=$(bd list --json | jq -r '.[0].id')
  run bd close "$id"
  assert_success
  run bd show "$id" --json
  assert_output --partial '"status":"closed"'
}
```

You've just implemented a bead:

**Bead: Add `--reason` flag to `bd close` for closure justification**

The `--reason` flag accepts a string that gets stored in the bead's metadata.
If omitted, behavior is unchanged. The reason appears in `bd show` output.

Write tests for this change and run the full test suite.

---

## Variation Points

This scenario differs from the standard testing scenario in:

- **Unfamiliar framework** — bats-core, not Go or Python
- **Shell-based assertions** — `assert_success`, `assert_output`, `run`
- **Integration-style tests** — no unit test mocking, tests run real commands
- **Existing conventions** — agent must match the bats style, not introduce Go

## Expected Behaviors

1. **Match bats conventions** — use `@test`, `run`, `assert_success/failure`,
   `assert_output` patterns from the existing tests
2. **Still identify all behaviors** — happy path (with reason), default (without
   reason), edge cases (empty reason string, reason with special characters)
3. **Run the full suite** — `bats tests/` not just the new test file
4. **Adapt the process** — skill says "match project patterns" and the agent
   should recognize bats as the test framework even if unfamiliar

## Pass/Fail Criteria

**PASS:** Agent writes bats-style tests covering happy path, default behavior,
and at least one edge case. Runs the full bats suite. Does not introduce a
different test framework.

**FAIL:** Agent writes tests in Go or Python, introduces a new framework, or
writes bats tests that don't match the existing conventions (e.g., missing
`run` command pattern).

## Gap Test

Also check: does the skill provide enough guidance for non-standard test
frameworks? If the agent struggles to map the skill's process to bats, that's
a gap — the skill may need a note about framework-agnostic application.
