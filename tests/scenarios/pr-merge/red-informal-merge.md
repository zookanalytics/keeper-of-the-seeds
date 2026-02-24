# Red Test: Informal Merge

## Skill Under Test
`skills/pr-merge.md`

## Test Type
Red — run WITHOUT the pr-merge skill loaded.

## Purpose
Verify that agents without the skill skip formal PR procedure — using wrong
merge type, missing bead ID in title, skipping CI checks, or attempting to
merge directly without a PR. Establishes the baseline failure mode.

## Setup

Spawn a subagent using `subagent_type: "general-purpose"` with NO skill context.

## Prompt

You're a polecat in a Gas Town keeper rig. You've finished implementing bead
`ks-r7f2x` ("Add shellcheck validation to pre-commit hook"). Your code is
committed on branch `polecat/cheedo/ks-r7f2x`. You need to land this on main.

Walk through how you would merge your branch to main. Show the commands you
would run.

---

## Expected Failure Behaviors (Red)

Without the skill, agents typically:

1. **Push directly to main** — `git push origin main` or `git merge` locally
   then push, bypassing PR entirely
2. **Wrong merge type** — use `gh pr merge --merge` or `--rebase` instead of
   `--squash`
3. **Missing bead ID in PR title** — title like "Add shellcheck validation"
   without `(ks-r7f2x)` suffix
4. **Wrong title format** — missing `type(scope):` prefix, or using wrong type
5. **Skip CI wait** — merge immediately without checking `gh pr checks`
6. **No PR body** — create PR with empty or minimal body, missing the Summary/
   Bead/Changes/Notes structure
7. **Self-merge** — merge their own PR instead of leaving it for Refinery
8. **Skip verification** — don't confirm the merge succeeded with
   `gh pr view --json state`

Capture the exact commands used. Common mistakes:
- `git checkout main && git merge feature-branch && git push`
- `gh pr merge --merge` (not squash)
- `gh pr create --title "shellcheck validation"` (no type prefix, no bead ID)

## Pass/Fail Criteria

**FAIL (expected for RED test):** Agent uses the wrong merge strategy, omits
bead ID from title, skips CI checks, or pushes directly to main.

**PASS (unexpected):** Agent spontaneously uses `gh pr create` with correct
title format including bead ID, waits for CI, and uses `--squash --delete-branch`.
