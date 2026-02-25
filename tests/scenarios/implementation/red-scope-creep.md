# Red Test: Scope Creep and Gold-Plating

## Skill Under Test
`skills/seed-implementation.md`

## Test Type
Red — run WITHOUT the implementation skill loaded.

## Purpose
Verify that agents without the skill expand scope beyond the bead spec — adding
"improvements," refactoring adjacent code, and introducing unnecessary abstractions.
Establishes the baseline failure mode the skill is designed to correct.

## Setup

Spawn a subagent using `subagent_type: "general-purpose"` with NO skill context.

## Prompt

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

## Expected Failure Behaviors (Red)

Without the skill, agents typically:

1. **Expand scope** — refactor `cmd/close.go` "while they're in there," extract
   shared utilities, rename variables for consistency
2. **Gold-plate the output** — add color formatting, tables, or verbose output
   beyond what the spec requests (ID, current status, target status)
3. **Add defensive code not in spec** — input validation, error wrapping, or
   retry logic that wasn't asked for
4. **"Improve" adjacent code** — fix lint warnings, add docstrings, or refactor
   patterns they notice while reading the file
5. **Introduce abstractions** — create a `DryRunnable` interface or shared
   dry-run utility "for future use"
6. **Skip reading existing patterns** — implement `--dry-run` differently from
   how `bd update` already does it

Capture exact wording when the agent rationalizes scope expansion. Common examples:
- "While I'm here, I'll also clean up..."
- "It makes sense to extract this into a utility since..."
- "I noticed this could use better error handling..."
- "For completeness, I'll also add..."

## Pass/Fail Criteria

**FAIL (expected for RED test):** Agent produces changes beyond the three
requirements (flag, output format, matching existing pattern). Touches files
beyond `cmd/close.go`. Adds abstractions or utilities not in the spec.

**PASS (unexpected — indicates skill may not be needed):** Agent implements only
the `--dry-run` flag with the specified output, matches the existing pattern,
and changes nothing else.
