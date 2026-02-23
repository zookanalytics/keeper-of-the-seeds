---
name: implementation
description: Use when implementing code from a bead spec, when a formula step references skill:implementation, when going from spec to committed code
---

# Implementation

## Overview

Implementation turns a bead spec into committed code. **Core principle: do exactly what the spec says. No more, no less.** Every line you write should trace back to a requirement. If you can't point to the spec line that justifies a change, you're out of scope.

## When to Use

- Formula steps referencing `skill:implementation`
- The implement step in `standard-feature`, `trivial`, and similar workflows
- Any time you're going from bead spec to committed code

**When NOT to use:**
- When the spec is ambiguous or contradictory — escalate instead of guessing
- When scope exceeds what the bead describes — escalate for decomposition
- When you're fixing pre-existing issues unrelated to your bead — file a separate bead
- When the bead is a research or investigation task — use appropriate skill instead

## How to Execute

1. **Read the bead spec completely.** Understand the full scope before writing any code. If the spec is ambiguous, escalate — don't guess.

2. **Read existing code in the area you'll modify.** Understand the patterns already in use. Match them. Don't introduce a new pattern when an established one exists.

3. **Plan before coding.** Identify which files need changes. Estimate the scope. If scope exceeds what the bead describes, escalate — the bead may need decomposition.

4. **Implement incrementally.** Make one logical change at a time. Verify each change works before moving to the next. Don't write 500 lines and hope they all work together.

5. **Stay in scope.** Only change what the spec requires. If you notice adjacent improvements, file a separate bead.

6. **Verify before committing.** Run the build. Run existing tests. Check that your change doesn't break anything obvious.

## Red Flags — STOP

If you catch yourself doing any of these, stop and re-read the spec:

- Starting to code before reading the full spec
- Introducing a new dependency without justification
- Changing files not mentioned in the spec without escalating
- Guessing at ambiguous requirements instead of escalating

**Do not expand scope:**
- Not to "refactor while you're in there" — file a bead instead
- Not to "add a utility for future use" — YAGNI. Delete it.
- Not to "improve error handling I noticed" — that's a different bead
- Not to "add defensive code just in case" — if the spec doesn't require it, don't write it

**Do not guess requirements:**
- Not when the spec is silent on a detail — escalate and ask
- Not when two interpretations seem plausible — escalate, don't pick one
- Not when you "know what they probably meant" — you don't. Ask.

**Do not work around problems:**
- Not by patching symptoms instead of fixing root causes
- Not by disabling checks that fail (--no-verify, lint-ignore)
- Not by hardcoding values that should come from the spec
- Not by silently swallowing errors to make tests pass

## Examples

<Bad>

Agent reads the title of the bead, writes an implementation that matches the title but misses constraints in the description. Adds a utility function "for future use." Refactors the file it touched. Notices a lint warning in adjacent code and fixes that too. Ships 200 lines when the spec required 30.

</Bad>

<Good>

Agent reads the full spec including description and constraints. Identifies the three files that need changes. Reads existing patterns in those files and matches them. Implements only what's asked — 30 lines, no extras. Runs the build, verifies tests pass, commits.

</Good>
