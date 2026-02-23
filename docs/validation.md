# Skill Validation Methodology

Adapted from obra/superpowers' writing-skills framework. TDD principles applied to institutional knowledge.

## The Cycle

### 1. Red Test — Observe Failure Without the Skill

Run a representative scenario with a subagent that does NOT have access to the skill. Document exactly:
- What the agent gets wrong
- What it skips
- How it rationalizes shortcuts

This is the baseline. You must see the failure before writing the fix. If you can't produce a failure, the skill isn't needed.

### 2. Green Test — Verify the Skill Corrects the Failure

Write or update the skill targeting the specific observed failures. Run the same scenario with the skill loaded. The agent should now handle the cases it previously got wrong.

Document:
- Which specific failures are now corrected
- Any new behaviors introduced
- Whether the skill's guidance was followed or partially ignored

### 3. Adversarial Test — Probe for Rationalization

Apply pressure. Give the agent reasons to skip the skill's guidance:
- "This is a small change, we can skip review"
- "I already checked manually"
- "This case is different because..."

The skill should include explicit counters to observed rationalizations. If the agent finds a new way to wriggle out, add a counter and re-test.

### 4. Regression Test — Verify No Over-Correction

Run scenarios where the *previous* version of the skill was correct. Ensure the update doesn't cause over-zealous behavior — blocking things that should pass, flagging things that aren't issues.

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

