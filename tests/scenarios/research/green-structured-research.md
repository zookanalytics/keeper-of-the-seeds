# Green Test: Structured Research

## Skill Under Test
`skills/seed-research.md`

## Test Type
Green — run WITH the research skill loaded.

## Purpose
Verify that the research skill corrects the failure modes identified in the red
test. The agent should follow the structured process: define the question,
survey internal context first, classify assumptions, document constraints,
catalog prior art, and surface open questions without proposing solutions.

## Setup

Spawn a subagent using `subagent_type: "general-purpose"` WITH the full text
of `skills/seed-research.md` prepended to the prompt.

## Prompt

[Prepend full contents of `skills/seed-research.md` here before running]

---

You're working in a Gas Town keeper rig. A bead has been assigned to you:

**Bead: Add a notification system for overdue beads**

The rig currently has no notification mechanism. Witness monitors beads, but
agents and crew members have no way to receive alerts when beads they're
watching go overdue.

A formula step has asked you to research this. Provide your research output.

---

## Expected Green Behaviors

With the skill loaded, the agent should:

1. **Define the question first** — one sentence stating what the research
   needs to determine ("What mechanisms exist for delivering notifications to
   agents in the Gas Town architecture, and what constraints apply?")
2. **Survey internal context** — reference the rig's existing structure
   (witness, beads, gt mail) before reaching for external solutions
3. **Classify assumptions** — produce a table with confirmed/plausible/
   questionable status for each assumption
4. **Document constraints** — list what can't change (existing gt mail API,
   beads Dolt storage, etc.)
5. **Catalog prior art** — note how gt mail already handles agent messaging
   and what's different about the notification use case
6. **Surface open questions** — end with concrete questions for the next
   phase, NOT a recommendation
7. **NOT propose a solution** — the output should stop at "here's what we
   know and what we still need to determine"

## Pass/Fail Criteria

**PASS:** Output follows the structured format from the skill. Assumptions are
classified. Open questions are surfaced. No solution is proposed. Constraints
are documented.

**FAIL:** Agent still proposes a solution, skips internal context survey,
omits assumption classification, or otherwise follows the red-test pattern
despite having the skill loaded.

**If FAIL:** Run the meta-testing technique — ask the agent how the skill
could have been written to prevent it from choosing the wrong path.

## Comparison Points

Compare against the red test output. The green output should demonstrate:

- Explicit statement of what the research is trying to learn
- Internal context survey BEFORE external exploration
- Assumption table with status classifications
- Open questions at the end (not a recommendation)
