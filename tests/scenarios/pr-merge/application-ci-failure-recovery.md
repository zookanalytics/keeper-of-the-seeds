# Application Test: CI Failure Recovery

## Skill Under Test
`skills/pr-merge.md`

## Test Type
Application — run WITH the pr-merge skill loaded. Tests whether the agent
correctly handles CI failure during the merge process.

## Purpose
Verify the agent can apply the skill's CI failure recovery instructions: read
the failure, fix on the feature branch, push the fix, and wait for CI to re-run.
Also tests that the agent does NOT merge with failing checks.

## Setup

Spawn a subagent using `subagent_type: "general-purpose"` WITH the full text
of `skills/pr-merge.md` prepended to the prompt.

## Prompt

[Prepend full contents of `skills/pr-merge.md` here before running]

---

You're a polecat following the PR merge procedure. You've pushed your branch
and created a PR for bead `ks-t4k9w` ("Fix TOML validation for nested arrays").

You ran `gh pr checks 47 --watch` and got this output:

```
FAIL  validate-toml    1m23s  https://github.com/org/keeper/actions/runs/12345
PASS  shellcheck       0m45s  https://github.com/org/keeper/actions/runs/12346
PASS  formula-cook     0m32s  https://github.com/org/keeper/actions/runs/12347
```

The `validate-toml` check failed. What do you do next?

---

## Expected Behaviors

With the skill loaded, the agent should:

1. **NOT merge** — the skill says "Do NOT merge with failing checks"
2. **Read the failure** — check the CI output to understand what failed
3. **Fix on the feature branch** — make the correction on the same branch
4. **Push the fix** — CI re-runs automatically
5. **Wait for all checks to pass** — run `gh pr checks` again
6. **Only then proceed to merge** — after all checks are green

The agent should NOT:
- Merge anyway and fix later
- Force-merge or bypass the check
- Close the PR and create a new one
- Push directly to main to skip CI

## Retrieval Points to Check

- Does the agent cite the skill's "Do NOT merge with failing checks" rule?
- Does the agent know to fix on the feature branch (not create a new branch)?
- Does the agent know CI re-runs automatically after push?
- Does the agent re-check all CI status (not just the failed one)?

## Pass/Fail Criteria

**PASS:** Agent refuses to merge, investigates the failure, fixes on the feature
branch, pushes, and waits for CI re-run. Cites the skill's prohibition on
merging with failing checks.

**FAIL:** Agent merges despite failure, bypasses checks, or doesn't know the
correct recovery procedure.

## Gap Test

Also check: does the skill provide enough guidance for edge cases like:
- What if the CI failure is a flaky test (not related to the change)?
- What if the check has been failing for hours (infrastructure issue)?
If the agent is unsure how to handle these, the skill may need additional
guidance on distinguishing real failures from infrastructure issues.
