# Skill: Code Review

## When to Use

Activated by formula steps referencing `skill:code-review`. Typically the review step in `standard-feature` and similar workflows. Also applicable when self-reviewing before submission.

## What Good Looks Like

A good code review:
- Catches bugs, not just style nitpicks
- Evaluates whether the change matches its stated intent (the bead spec)
- Identifies security issues, error handling gaps, and edge cases
- Provides actionable feedback — "change X to Y because Z", not "this could be better"
- Distinguishes blocking issues from suggestions

## How to Execute

1. **Read the bead spec first.** Understand what was requested before reading code. The review evaluates "did the code achieve what the bead asked for," not "is this code I would have written."

2. **Read the diff, not just the new code.** Understand what changed and what was removed. Deletions matter as much as additions.

3. **Check these categories in order:**
   - **Correctness:** Does the logic do what it claims? Are there off-by-one errors, null handling gaps, race conditions?
   - **Security:** Command injection, XSS, SQL injection, hardcoded secrets, OWASP Top 10.
   - **Error handling:** What happens when things fail? Are errors swallowed silently?
   - **Edge cases:** Empty inputs, large inputs, concurrent access, unicode, boundary values.
   - **API contract:** Do public interfaces match expectations? Breaking changes flagged?

4. **Classify each finding:**
   - **BLOCK** — Must fix before merge (bugs, security issues, data loss risk)
   - **SHOULD** — Strong recommendation, would accept if author pushes back with reasoning
   - **NIT** — Style or minor improvement, author's discretion

5. **Create the PR** with a structured review summary.

## Red Flags

- Reviewing only the happy path and ignoring error branches
- Approving because "it works" without checking edge cases
- Skipping security checks on "internal" code (internal code becomes external)
- Rubber-stamping small changes — small diffs can hide large bugs

## Examples

**Without skill:** Agent skims the diff, says "looks good, no issues found," creates PR.

**With skill:** Agent reads the bead spec, walks through the diff category by category, finds that error handling in the new endpoint swallows database errors and returns 200, flags it as BLOCK with a specific fix suggestion.
