# Skill Validation Methodology

Adapted from obra/superpowers' writing-skills framework. TDD principles applied to institutional knowledge. See `docs/superpowers-study.md` for the full analysis of the source methodology.

## Core Principle

**If you didn't watch an agent fail without the skill, you don't know if the skill teaches the right thing.**

Skill validation IS test-driven development applied to documentation. Same cycle, same discipline, same benefits.

## The Cycle

### 1. Red Test — Observe Failure Without the Skill

Run a representative scenario with a subagent that does NOT have access to the skill. Document exactly:
- What the agent gets wrong
- What it skips
- How it rationalizes shortcuts (capture **exact wording**)

This is the baseline. You must see the failure before writing the fix. If you can't produce a failure, the skill isn't needed.

**For discipline-enforcing skills**, use pressure scenarios (see format below). Academic questions ("what does TDD say?") reveal nothing — agents recite the rule perfectly and violate it under pressure.

### 2. Green Test — Verify the Skill Corrects the Failure

Write or update the skill targeting the specific observed failures. Run the same scenario with the skill loaded. The agent should now handle the cases it previously got wrong.

Document:
- Which specific failures are now corrected
- Any new behaviors introduced
- Whether the skill's guidance was followed or partially ignored

### 3. Adversarial Test — Probe for Rationalization

Apply pressure. Give the agent reasons to skip the skill's guidance. Use pressure scenarios that combine 3+ pressure types:

| Pressure Type | Example |
|---------------|---------|
| Time | Emergency, deadline, deploy window closing |
| Sunk cost | Hours of work already done, "waste" to redo |
| Authority | Senior says skip it, manager overrides |
| Exhaustion | End of day, tired, want to finish |
| Social | Looking dogmatic, seeming inflexible |
| Pragmatic | "Being pragmatic vs dogmatic" |

The skill should include explicit counters to observed rationalizations. If the agent finds a new way to wriggle out, add a counter and re-test. Continue the refactor cycle until no new rationalizations appear.

### 4. Regression Test — Verify No Over-Correction

Run scenarios where the *previous* version of the skill was correct. Ensure the update doesn't cause over-zealous behavior — blocking things that should pass, flagging things that aren't issues.

## Pressure Scenario Format

For discipline-enforcing skills, write scenarios that force explicit choices under realistic pressure:

```markdown
IMPORTANT: This is a real scenario. You must choose and act.
Don't ask hypothetical questions — make the actual decision.

[Concrete situation with specific details: file paths, times, consequences]
[Multiple pressure types combined: sunk cost + time + exhaustion]

Options:
A) [Correct action per skill — usually hardest/most costly]
B) [Common violation — tempting shortcut]
C) [Subtle violation — seems reasonable but breaks the rule]

Choose A, B, or C. Be honest.
```

Key elements:
- Force A/B/C choice, not open-ended discussion
- Use concrete details (real file paths, specific times)
- Make agent act ("What do you do?" not "What should you do?")
- Combine 3+ pressure types for realistic testing
- No easy outs — agent must commit to a choice

### Gas Town Adaptation

Run pressure scenarios using subagent spawning:

```
Task tool → subagent_type: "general-purpose"
Prompt: [scenario text]
         [Include skill text for GREEN test, omit for RED test]
```

Compare RED (without skill) vs GREEN (with skill) outputs. Document rationalizations verbatim.

## Meta-Testing Technique

When an agent fails a pressure test even WITH the skill loaded, ask:

```markdown
You read the skill and chose Option [wrong answer] anyway.
How could that skill have been written differently to make
it crystal clear that Option [correct answer] was the only acceptable answer?
```

Three diagnostic responses and their fixes:

1. **"The skill WAS clear, I chose to ignore it"** → Need stronger foundational principle. Add "Violating the letter of the rules is violating the spirit of the rules."
2. **"The skill should have said X"** → Documentation gap. Add their suggestion verbatim to the skill.
3. **"I didn't see section Y"** → Organization problem. Make key points more prominent, add to overview.

## Skill Type → Test Approach

Different skill types require different testing strategies:

### Discipline Skills (rules/requirements)

Examples: `testing.md` when it enforces test-writing rules.

Test with:
- Pressure scenarios with 3+ combined pressures
- Multiple iterations until no new rationalizations appear
- Meta-testing to diagnose clarity gaps

Success: Agent follows rule under maximum pressure and cites skill sections.

### Technique Skills (how-to guides)

Examples: `implementation.md`, `code-review.md`

Test with:
- Application scenarios: Can the agent apply the technique to a new case?
- Variation scenarios: Does it handle edge cases the skill covers?
- Gap testing: Are there missing instructions that cause the agent to guess?

Success: Agent successfully applies technique to an unfamiliar scenario.

### Reference Skills (lookup/documentation)

Examples: API documentation skills, syntax guides.

Test with:
- Retrieval scenarios: Can the agent find the right information?
- Application scenarios: Can it use what it found correctly?
- Coverage testing: Are common use cases documented?

Success: Agent finds and correctly applies reference information.

## Anti-Rationalization Patterns

When building discipline-enforcing skills, use these patterns (from superpowers, backed by research — Meincke et al. 2025, N=28,000):

### Iron Law Statement

State the non-negotiable rule prominently and early:

```markdown
## The Iron Law

NO [VIOLATION] WITHOUT [PREREQUISITE] FIRST
```

### Spirit vs Letter Blocker

Add early in any discipline skill:

> **Violating the letter of the rules is violating the spirit of the rules.**

Cuts off an entire class of "I'm following the spirit" rationalizations.

### Explicit Negation

Don't just state the rule — forbid specific workarounds:

```markdown
# BAD
Don't skip review.

# GOOD
Don't skip review.
- Not for "small changes" (small diffs hide large bugs)
- Not because "I already checked manually" (ad-hoc != systematic)
- Not because "this case is different" (it isn't)
```

### Rationalization Table

Build incrementally from observed rationalizations during testing:

```markdown
## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "[exact wording from test]" | [direct counter] |
```

Only add entries observed during actual testing, not hypothetical ones.

### Red Flags List

Self-check mechanism for agents to recognize when they're rationalizing:

```markdown
## Red Flags — STOP

- [symptom of about-to-violate]
- [common rationalization opening]
- "This is different because..."

**All of these mean: [corrective action].**
```

## Test Artifacts

- Scenarios live in `tests/scenarios/<skill-name>/`
- Each scenario is a markdown file describing the setup, input, and expected behavior
- Results (captured agent outputs) go in `tests/results/<skill-name>/<date>/`
- Results are evidence, not disposable — they justify the skill's current state

## When to Validate

- Every new skill: full cycle (red → green → adversarial → regression)
- Every skill modification: green + adversarial + regression at minimum
- Periodic spot checks: pick a skill, run its scenarios, verify it still holds

## Time Investment

Fifteen minutes per skill change. The cost of NOT validating is a bad skill propagating to every project rig immediately, producing subtly wrong outputs across all active work until someone notices.

Discipline-enforcing skills may require multiple REFACTOR iterations (superpowers' TDD skill took 6 iterations to reach 100% compliance). Budget accordingly.
