# Green Test: Test-First Workflow

## Skill Under Test
`skills/acceptance-testing.md`

## Test Type
Green — run WITH the acceptance-testing skill loaded.

## Purpose
Verify that the acceptance-testing skill produces genuine test-first behavior:
tests written from acceptance criteria, verified to fail, committed separately
before any implementation.

## Setup

Spawn a subagent using `subagent_type: "general-purpose"` WITH the full text
of `skills/acceptance-testing.md` prepended to the prompt.

## Prompt

[Prepend full contents of `skills/acceptance-testing.md` here before running]

---

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

## Expected Green Behaviors

With the skill loaded, the agent should:

1. **Extract 4 acceptance criteria** — one per numbered requirement in the spec
2. **Write one test per criterion** — descriptively named to mirror the criterion:
   - `test_archive_moves_closed_bead_to_archive_table`
   - `test_archived_bead_not_in_list_output`
   - `test_archive_open_bead_returns_error`
   - `test_show_works_for_archived_beads`
3. **Choose the right test level** — CLI tool → test command output and exit codes
4. **Run tests and confirm all fail** — every test must fail because the feature
   doesn't exist yet
5. **Commit failing tests separately** — commit message format:
   `test: add failing acceptance tests for bd archive (bead-id)`
6. **NOT write any implementation code** — stop after the red commit

## Pass/Fail Criteria

**PASS:** Agent writes exactly 4 tests matching the criteria, runs them to
confirm all fail, and commits them separately. No implementation code written.

**FAIL:** Agent writes implementation, writes passing tests, skips the failure
verification step, or writes tests that don't map 1:1 to acceptance criteria.
If so, run meta-testing.

## Comparison Points

Compare against the red test output. The green output should demonstrate:

- Tests written before any implementation code
- Each test maps to a specific acceptance criterion
- Tests verified to fail (red state)
- Separate commit for failing tests
- No implementation code in the commit
