# Application Test: Standard Squash-Merge

## Skill Under Test
`skills/pr-merge.md`

## Test Type
Application — run WITH the pr-merge skill loaded. Tests whether the agent can
correctly apply the full PR procedure to a concrete merge scenario.

## Purpose
Verify the agent can retrieve and apply the correct commands, title format,
body template, and verification steps from the skill.

## Setup

Spawn a subagent using `subagent_type: "general-purpose"` WITH the full text
of `skills/pr-merge.md` prepended to the prompt.

## Prompt

[Prepend full contents of `skills/pr-merge.md` here before running]

---

You're a polecat in a Gas Town keeper rig. You've finished implementing bead
`ks-r7f2x` ("Add shellcheck validation to pre-commit hook"). Your code is
committed on branch `polecat/cheedo/ks-r7f2x`.

Changes made:
- Added `hooks/pre-commit-shellcheck.sh` — runs shellcheck on staged `.sh` files
- Updated `hooks/install.sh` to register the new hook
- Added test in `tests/test_hooks.bats`

Land this on main. Show the complete sequence of commands.

---

## Expected Behaviors

With the skill loaded, the agent should produce:

1. **Push to origin**:
   ```bash
   git push origin polecat/cheedo/ks-r7f2x
   ```

2. **Create PR with correct format**:
   - Title: `feat(hooks): add shellcheck validation to pre-commit hook (ks-r7f2x)`
   - Body: Includes Summary, Bead, Changes, and Notes sections
   - Uses `gh pr create` with `--base main`

3. **Wait for CI**:
   ```bash
   gh pr checks <number> --watch
   ```

4. **Squash-merge** (or note that Refinery does this):
   ```bash
   gh pr merge <number> --squash --delete-branch
   ```

5. **Verify**:
   ```bash
   gh pr view <number> --json state,mergeCommit
   ```

## Retrieval Points to Check

- Does the agent use the correct title format `type(scope): summary (bead-id)`?
- Does the agent use `feat` as the type (new hook, not a fix)?
- Does the agent include `(ks-r7f2x)` in the title?
- Does the agent use `--squash` (not `--merge` or `--rebase`)?
- Does the agent include `--delete-branch`?
- Does the agent know that polecats don't self-merge (Refinery does)?

## Pass/Fail Criteria

**PASS:** Agent produces the correct command sequence with proper title format,
squash merge, and verification. Recognizes that Refinery should merge, not the
polecat.

**FAIL:** Agent uses wrong merge type, omits bead ID, skips CI check, or
attempts to self-merge. If so, check whether the failure is retrieval (agent
didn't find the info in the skill) or application (found it but applied wrong).
