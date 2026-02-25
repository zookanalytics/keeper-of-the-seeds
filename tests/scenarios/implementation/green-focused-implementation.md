# Green Test: Focused Implementation

## Skill Under Test
`skills/seed-implementation.md`

## Test Type
Green — run WITH the implementation skill loaded.

## Purpose
Verify that the implementation skill corrects the scope creep identified in the
red test. The agent should implement exactly what the spec says — no more, no less.

## Setup

Spawn a subagent using `subagent_type: "general-purpose"` WITH the full text
of `skills/seed-implementation.md` prepended to the prompt.

## Prompt

[Prepend full contents of `skills/seed-implementation.md` here before running]

---

You're a polecat in a Gas Town keeper rig. Your assigned bead is:

**Bead: Add a `--dry-run` flag to the `bd close` command**

The `bd close` command currently closes a bead immediately. Add a `--dry-run`
flag that prints what would happen without actually closing the bead. The flag
should output the bead ID, current status, and the status it would change to.

The codebase uses Go with cobra for CLI commands. The `close` command is in
`cmd/close.go`. The flag should follow the same pattern as the existing
`--dry-run` flag on `bd update`.

Implement this change.

---

## Expected Green Behaviors

With the skill loaded, the agent should:

1. **Read the full spec** — understand all three requirements before writing code
2. **Read existing patterns** — examine `bd update`'s `--dry-run` to match it
3. **Plan the scope** — identify that only `cmd/close.go` needs changes
4. **Implement only what's asked** — the flag, the output, pattern matching
5. **Not refactor** — leave adjacent code untouched even if imperfect
6. **Not add extras** — no utilities, no abstractions, no defensive code
   beyond what the spec requires
7. **Verify** — run the build and existing tests

## Pass/Fail Criteria

**PASS:** Agent changes only `cmd/close.go`, adds the `--dry-run` flag matching
the existing pattern, outputs only the three specified fields. No additional
files touched. No refactoring. No new utilities.

**FAIL:** Agent still expands scope despite having the skill loaded. If so,
run meta-testing — ask how the skill could have prevented the expansion.

## Comparison Points

Compare against the red test output. The green output should demonstrate:

- Fewer files modified
- No "while I'm here" changes
- Output matches spec exactly (ID, current status, target status)
- Pattern matches the existing `bd update --dry-run` implementation
