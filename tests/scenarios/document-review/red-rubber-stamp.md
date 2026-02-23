# Red Test: Rubber Stamp Review

## Skill Under Test
`skills/document-review.md`

## Test Type
Red — run WITHOUT the document-review skill loaded.

## Purpose
Verify that agents without the skill rubber-stamp design documents rather than
conducting structured lens-based reviews. Establishes the baseline failure mode.

## Setup

Spawn a subagent using `subagent_type: "general-purpose"` with NO skill context.

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

## Prompt (to agent, no skill loaded)

You've been asked to review the above design document before it advances to
implementation. The document is a proposal for automated bead escalation.

Please review it and provide your assessment.

---

## Expected Failure Behaviors (Red)

Without the skill, agents typically:

1. **No declared lens** — review proceeds without stating what angle they're
   evaluating from
2. **General approval** — "This looks good, I recommend proceeding"
3. **Substance skipped** — comments focus on wording or formatting, not logic
4. **No classification** — no BLOCK/CONCERN/NOTE structure
5. **Missing sections ignored** — the document is missing risk analysis,
   failure modes, and what happens if the gt mail call fails; agents skip this
6. **Coverage not stated** — no list of what was actually checked

Capture exact wording of approval language. Common patterns:
- "This appears to be a well-thought-out approach"
- "The design is clean and aligns with existing architecture"
- "I recommend proceeding to implementation"

## Actual Issues the Review Should Catch

A good review would identify:

1. **BLOCK** — No failure mode documented: what happens if the beads DB is
   unavailable during the cron run? What if gt mail fails?
2. **BLOCK** — "72 hours without activity" is undefined: does an automated
   system update count as "activity"? Could the escalation trigger infinitely?
3. **CONCERN** — P1 priority is applied automatically but no human reviews
   whether escalation was warranted — no appeal mechanism documented
4. **CONCERN** — "15-minute intervals chosen as a balance" — balance between
   what? The trade-off is not stated
5. **NOTE** — No mention of testing strategy for the cron job

## Pass/Fail Criteria

**FAIL (expected for RED test):** Agent approves the document without catching
the undefined "activity" loop risk, missing failure modes, or unexplained
trade-off framing.

**PASS (unexpected):** Agent spontaneously applies structured review without
the skill.
