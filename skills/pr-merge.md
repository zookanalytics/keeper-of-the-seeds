---
name: pr-merge
description: Use when merging a polecat's feature branch to main via GitHub PR, when a formula merge/submit step needs to land code
---

# PR-Based Squash-Merge

## Overview

All merges to `main` go through GitHub PRs with squash-merge. This produces one commit per bead on main, preserves CI gates and review artifacts, and keeps `git log --oneline` a readable changelog.

## When to Use

- Formula merge/submit steps that land code on `main`
- Refinery processing a merge request from the queue
- Any time a feature branch needs to become a commit on `main`

**When NOT to use:**
- Branches with `--no-merge` flag (consult, architecture — branch persists for review)
- Direct pushes to main (emergency hotfix only, requires explicit authorization)

## How to Execute

### 1. Push branch to origin

```bash
git push origin <branch-name>
```

Ensure the branch is up to date with the latest commits.

### 2. Open PR via gh CLI

```bash
gh pr create \
  --base main \
  --title "type(scope): summary (bead-id)" \
  --body "$(cat <<'EOF'
## Summary

<1-3 sentence description of what this change does and why>

## Bead

`<bead-id>`: <bead title>

## Changes

<bullet list of key changes>

## Notes

<implementation notes, decisions made, anything reviewers should know>
EOF
)"
```

**PR title format:** `type(scope): summary (bead-id)`

This becomes the squash commit message on main. Types: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`.

Examples:
- `feat(formulas): add architecture-decision workflow (ks-abc12)`
- `fix(skills): strengthen code-review rationalization counters (ks-def34)`
- `chore(hooks): update pre-dispatch validator (ks-ghi56)`

### 3. Wait for CI status checks

```bash
gh pr checks <pr-number> --watch
```

If CI fails:
- Read the failure output
- Fix the issue on the feature branch
- Push the fix — CI re-runs automatically
- Do NOT merge with failing checks

### 4. Squash-merge via gh CLI

```bash
gh pr merge <pr-number> --squash --delete-branch
```

The `--squash` flag combines all branch commits into one. The `--delete-branch` flag cleans up the remote branch after merge.

### 5. Verify

```bash
gh pr view <pr-number> --json state,mergeCommit
```

Confirm state is `MERGED` and the merge commit exists.

## Red Flags

- Merging without CI passing — never bypass status checks
- Using regular merge or rebase merge — squash only
- PR title missing bead ID — every main commit must trace to a bead
- Merging your own PR as a polecat — Refinery or maintainer merges
- Force-pushing after PR is open — rewrite history carefully
