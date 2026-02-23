# Skill: Implementation

## When to Use

Activated by formula steps referencing `skill:implementation`. Typically the implement step in `standard-feature`, `trivial`, and similar workflows. Governs how an agent goes from bead spec to committed code.

## What Good Looks Like

A good implementation:
- Does exactly what the bead spec asks — no more, no less
- Fits the existing codebase patterns (naming, structure, error handling style)
- Is the simplest solution that meets the requirements
- Leaves the codebase no worse than it found it

## How to Execute

1. **Read the bead spec completely.** Understand the full scope before writing any code. If the spec is ambiguous, escalate — don't guess.

2. **Read existing code in the area you'll modify.** Understand the patterns already in use. Match them. Don't introduce a new pattern when an established one exists.

3. **Plan before coding.** Identify which files need changes. Estimate the scope. If scope exceeds what the bead describes, escalate — the bead may need decomposition.

4. **Implement incrementally.** Make one logical change at a time. Verify each change works before moving to the next. Don't write 500 lines and hope they all work together.

5. **Stay in scope.** Do not:
   - Refactor adjacent code that isn't part of the bead
   - Add features not requested
   - "Improve" things you notice along the way (file a separate bead)
   - Add defensive code for scenarios that can't happen

6. **Verify before committing.** Run the build. Run existing tests. Check that your change doesn't break anything obvious.

## Red Flags

- Starting to code before reading the full spec
- Introducing a new dependency without justification
- Changing files not mentioned in the spec without escalating
- Writing more code than the task requires ("while I'm here...")
- Guessing at ambiguous requirements instead of escalating

## Examples

**Without skill:** Agent reads the title of the bead, writes an implementation that matches the title but misses constraints in the description, adds a utility function "for future use," refactors the file it touched.

**With skill:** Agent reads the full spec, identifies the three files that need changes, matches existing patterns, implements only what's asked, verifies the build passes.
