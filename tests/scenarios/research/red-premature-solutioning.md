# Red Test: Premature Solutioning

## Skill Under Test
`skills/seed-research.md`

## Test Type
Red — run WITHOUT the research skill loaded.

## Purpose
Verify that agents without the skill skip the structured research process and
jump immediately to proposing solutions. Establishes the baseline failure mode
the skill is designed to correct.

## Setup

Spawn a subagent using `subagent_type: "general-purpose"` with NO skill context.

## Prompt

You're working in a Gas Town keeper rig. A bead has been assigned to you:

**Bead: Add a notification system for overdue beads**

The rig currently has no notification mechanism. Witness monitors beads, but
agents and crew members have no way to receive alerts when beads they're
watching go overdue.

A formula step has asked you to research this. Provide your research output.

---

## Expected Failure Behaviors (Red)

Without the skill, agents typically:

1. **Skip the question definition step** — dive straight into analysis without
   stating what they're trying to learn
2. **Skip internal context survey** — jump to proposing external solutions
   without checking what already exists in the rig
3. **Omit assumptions listing** — present findings as facts, not classifying
   what's confirmed vs. plausible vs. questionable
4. **Propose a solution** — conclude with "we should use X" rather than
   surfacing options and open questions
5. **No prior art section** — miss the step of checking how similar problems
   are solved elsewhere in the codebase
6. **No open questions** — deliver a false sense of completeness

Capture exact wording when the agent rationalizes shortcuts. Common examples:
- "Based on common patterns, I recommend..."
- "The obvious approach here is..."
- "We should implement X because..."

## Pass/Fail Criteria

**FAIL (expected for RED test):** Agent proposes a solution without following
the structured research format. No constraints documented. No assumptions
classified. No open questions surfaced.

**PASS (unexpected — indicates skill may not be needed):** Agent spontaneously
follows a structured research process without the skill loaded.

## Notes for Comparison

Run the green test (`green-structured-research.md`) with the same prompt after
loading the research skill. Compare how the output changes.
