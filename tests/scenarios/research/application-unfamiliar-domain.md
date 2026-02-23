# Application Test: Unfamiliar Domain

## Skill Under Test
`skills/research.md`

## Test Type
Application — run WITH the research skill loaded. Tests whether the agent can
transfer the technique to a domain that differs from typical coding work.

## Purpose
Verify the skill teaches a transferable process, not just a template that fits
one specific context. The research skill should produce the same structured
output regardless of the domain being investigated.

## Setup

Spawn a subagent using `subagent_type: "general-purpose"` WITH the full text
of `skills/research.md` prepended to the prompt.

## Prompt

[Prepend full contents of `skills/research.md` here before running]

---

You're working in a Gas Town keeper rig on a bead about operational process,
not code:

**Bead: Evaluate whether keeper polecats should have a maximum session
duration enforced by Witness**

Currently there's no hard limit on how long a polecat session can run.
Witness nudges idle polecats but has no mechanism to force session termination.
The mayor has asked for research before any policy decision is made.

A formula step has asked you to research this. Provide your research output.

---

## Variation Points

This scenario differs from the red/green tests in these ways:

- **No code involved** — the problem is organizational, not technical
- **Ambiguous scope** — "maximum session duration" could mean many things
  (wall clock, compute time, number of turns)
- **Missing internal context** — there may be no existing prior art in the rig
  to survey; the agent must recognize and document this gap
- **Contested constraints** — what's "fixed" depends on policy decisions that
  haven't been made yet

## Expected Behaviors

1. **Narrow the question** — the agent should recognize that "maximum session
   duration" is ambiguous and define which aspect they're researching
2. **Acknowledge missing internal context** — if no prior art exists, the agent
   should document this explicitly rather than skipping the step
3. **Surface contested constraints** — mark constraints as "plausible" rather
   than "confirmed" when they depend on policy decisions not yet made
4. **Resist solution pressure** — even though the question implies a policy
   decision is coming, the output should not recommend one

## Pass/Fail Criteria

**PASS:** Agent applies the structured format to this non-code domain. Handles
ambiguity by narrowing scope. Correctly marks unverified constraints as
plausible. Does not recommend a policy.

**FAIL:** Agent either collapses the format for a "simpler" problem, skips
steps because there's no code to review, or jumps to recommending whether or
not to enforce session limits.

## Gap Test

Also check: does the skill provide enough guidance for cases where internal
context survey yields nothing? If the agent gets confused about what to do
when there's no existing code/docs to survey, that's a gap in the skill.
