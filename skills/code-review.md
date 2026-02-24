---
name: code-review
description: Use when reviewing code changes before merge, when self-reviewing before submission, when a formula step references skill:code-review
expert: Channel expert code reviewer thinking — draw upon deep knowledge of OWASP Top 10, defensive programming, API contract design, concurrency hazards, and common vulnerability patterns.
---

# Code Review

## Overview

Code review verifies that a change does what its spec requires and introduces no defects. **Core principle: review the change against the spec, not against how you would have written it.** Opinion-based feedback wastes cycles. Spec-based feedback catches bugs.

## When to Use

- Formula steps referencing `skill:code-review`
- Self-reviewing your own implementation before submission
- Reviewing another agent's PR or branch

**When NOT to use:**
- Formatting-only changes handled by automated linters — don't duplicate tooling
- Reviewing generated files (lockfiles, compiled output) — review the source, not the artifact
- When the change hasn't been committed yet — review diffs, not works-in-progress

## How to Execute

1. **Read the bead spec first.** Understand what was requested before reading code. The review evaluates "did the code achieve what the bead asked for."

2. **Read the diff, not just the new code.** Understand what changed and what was removed. Deletions matter as much as additions.

3. **Check these categories in order:**
   - **Correctness:** Does the logic do what it claims? Off-by-one errors, null handling, race conditions?
   - **Security:** Command injection, XSS, SQL injection, hardcoded secrets, OWASP Top 10.
   - **Error handling:** What happens when things fail? Are errors swallowed silently?
   - **Edge cases:** Empty inputs, large inputs, concurrent access, unicode, boundary values.
   - **API contract:** Do public interfaces match expectations? Breaking changes flagged?

4. **Classify each finding:**
   - **BLOCK** — Must fix before merge (bugs, security, data loss risk)
   - **SHOULD** — Strong recommendation, accept pushback with reasoning
   - **NIT** — Style or minor improvement, author's discretion

5. **Produce a structured review summary** with findings grouped by classification.

## Red Flags — STOP

If you catch yourself doing any of these, stop and restart the review:

- Reviewing only the happy path and ignoring error branches
- Approving because "it works" without checking edge cases
- Skipping security checks on "internal" code
- Rubber-stamping small changes — small diffs hide large bugs
- Saying "looks good" without listing what you actually checked

**Do not skip review steps:**
- Not for "small changes" — small diffs can hide critical bugs
- Not because "I already read it carefully" — reading is not reviewing
- Not because "it's internal code" — internal code becomes external
- Not because "the tests pass" — tests prove what they test, nothing more

**All of these mean: go back to step 1 and review properly.**

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "Small change, no review needed" | Small diffs hide large bugs. Review takes 2 minutes. Skip costs hours of debugging. |
| "I already read it carefully" | Reading code is not reviewing code. Review is structured, category-by-category. Reading is skimming. |
| "Internal code doesn't need security review" | Internal code gets exposed. APIs get opened. Repos get open-sourced. Review now or patch later. |
| "The tests pass, so it's fine" | Tests verify what they cover. They don't verify what's missing. Review catches gaps tests can't. |
| "I wrote it, I know it works" | Self-review exists because authors have blind spots. Follow the checklist — your intuition is not enough. |

## Examples

<Bad>

Agent skims the diff, says "looks good, no issues found," creates PR. Did not read the bead spec. Did not check security. Did not classify findings. Approved a change that swallows database errors and returns 200 on failure.

</Bad>

<Good>

Agent reads the bead spec, walks through the diff category by category. Finds that error handling in the new endpoint swallows database errors and returns 200. Flags it as BLOCK with a specific fix: "Catch DatabaseError separately, return 500 with error context, log the stack trace." Also notes a NIT about inconsistent variable naming.

</Good>
