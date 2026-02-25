# Green Test: Systematic Lens Review

## Skill Under Test
`skills/seed-document-review.md`

## Test Type
Green — run WITH the document-review skill loaded.

## Purpose
Verify that the document-review skill corrects the rubber-stamp failure mode.
The agent should declare a lens, read the full document, classify findings as
BLOCK/CONCERN/NOTE, and state what was checked.

## Setup

Spawn a subagent using `subagent_type: "general-purpose"` WITH the full text
of `skills/seed-document-review.md` prepended to the prompt.

## Document to Review

```markdown
# Design: Automated Bead Escalation System

## Overview

This system automatically escalates beads that have been open for more than
72 hours without activity. Escalation sends a notification to the rig's
witness and marks the bead priority as P1.

## Implementation

The escalation check runs as a cron job every 15 minutes. It queries the beads
database for open beads with no updates in the last 72 hours and applies the
escalation logic.

The notification format reuses the existing gt mail interface. Bead priority
is updated via bd update.

## Trade-offs Considered

Speed vs. thoroughness: 15-minute intervals were chosen as a balance.

## Conclusion

This is a clean, minimal design that fits the existing architecture.
```

## Prompt (to agent, WITH skill loaded)

[Prepend full contents of `skills/seed-document-review.md` here before running]

---

You've been asked to review the above design document before it advances to
implementation. Apply the completeness + feasibility lens (default when none
is specified).

---

## Expected Green Behaviors

With the skill loaded, the agent should:

1. **Declare the lens** — explicitly state "Lens: completeness + feasibility"
   at the start of the review
2. **Read the full document before writing findings**
3. **Classify every finding** — use BLOCK/CONCERN/NOTE
4. **Catch the BLOCK-level issues:**
   - Undefined "activity": does an automated update reset the 72-hour clock?
     Could cause infinite escalation loop
   - No failure modes: what happens if beads DB is down during cron run?
     If gt mail fails?
5. **Catch at least one CONCERN:**
   - P1 applied automatically with no human review / appeal mechanism
   - "15-minute intervals chosen as balance" — balance between what?
6. **State coverage** — list sections reviewed and lens questions applied
7. **Not rubber-stamp** — summary should indicate whether the document can
   advance or needs revision first

## Pass/Fail Criteria

**PASS:** Agent declares lens, produces BLOCK/CONCERN/NOTE structure, catches
the infinite escalation loop risk and missing failure modes as BLOCK items,
states what was reviewed.

**FAIL:** Agent still produces general approval. Does not catch the undefined
"activity" ambiguity. Does not classify findings. Does not state coverage.

**If FAIL:** Apply meta-testing — ask how the skill could be rewritten to
make the correct behavior unambiguous.

## Comparison Points

Compare against red test. Green output should show:
- Explicit lens declaration (absent in red)
- BLOCK items for the actual logic errors (missed in red)
- Coverage statement (absent in red)
