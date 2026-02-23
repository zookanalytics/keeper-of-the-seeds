# Review: Retrospective Checkpoints for Continuous Learning
Lens: completeness
Reviewer: keeper/polecats/rictus

## Summary

The design frames the problem well and the layered option analysis is sound. However, it has significant coverage gaps: one stated requirement from the parent bead is entirely absent, the implementation sketches for Layers 2 and 3 are too thin to act on, the artifact format is undefined, and several open questions that would block implementation are missing. The document can inform a direction decision but needs gaps addressed before implementation begins.

---

## BLOCK

**[Constraints / Implementation Sketch — "Rationalization counters" unaddressed]**

The parent bead (ks-jiqsy) explicitly states: "Both should feed back into keeper: updating skills, tuning formulas, adding rationalization counters." The design never mentions rationalization counters. This is a stated deliverable, not an implementation detail to defer. Either (a) the design must define what rationalization counters are and how the retro system tracks/surfaces them, or (b) the design must explicitly scope them out with rationale. Omitting a requirement without acknowledgment is a gap that will resurface in implementation.

**[Options / Recommendation — Feedback-to-keeper loop is a black box]**

The design's learning loop ends at "file a ks bead." The parent bead's actual goal is to close a loop: retro findings → keeper improvements (updated skills, tuned formulas). The mechanism from "retro bead exists" to "skill or formula is updated" is entirely unspecified. What triage process handles retro beads? Who dispatches them? Do they go through the design-pipeline formula, or direct implementation? Without this the system generates observations but doesn't learn. The loop is broken at the mechanism that matters most.

**[Implementation Sketch — Layer 2 artifact format undefined]**

Layer 2 is described as producing "a structured retro document" but the format is not defined. A step that instructs an agent to "review all artifacts and produce a structured document" without a format spec will produce inconsistent output that can't be reliably used by Layer 3. The design needs at minimum a skeleton of what the retro document contains (sections, required fields).

---

## CONCERN

**[Assumptions — Hook API is load-bearing and unverified]**

Assumption 1 (hook API) is marked "plausible" with no path to verification described. Layer 1 is the entire first-deployment strategy. If the hook can't receive bead metadata (or the API doesn't exist in the form assumed), Layer 1 can't be built as designed. The design should include a verification step or a fallback if the API doesn't support the needed access pattern.

**[Implementation Sketch — Anomaly detection for Layer 1 has no baselines]**

Layer 1 checks "duration vs estimate" but there is no mechanism for setting duration estimates on beads (the design doesn't reference one, and it's not obvious from bd primitives). "Unusual duration" is undefined without a baseline. Similarly, "pattern matches" assumes the linked-bead frequency query works (Assumption 3: "plausible"). The hook could fail silently on its most important checks. The sketch needs either: (a) confirmation that these primitives exist, or (b) a narrower scope limited to checks that are definitively possible.

**[Options D — Escalation criteria from L1 to L2 are undefined]**

The deployment sequence is described as "Layer 2 when aspect composition works" and "Layer 3 for specific workflows where human review has high ROI." Neither has a measurable trigger. "Aspect composition works" is a dependency, not a milestone. "High ROI" has no measurement. Without thresholds, the layered approach has no graduation conditions — you can't know when to advance.

**[Implementation Sketch — Layer 3 batch synthesis process not described]**

Layer 3's gate description says "AI synthesizes accumulated retro findings." Over what time window? From which beads? What's the selection criteria? Does it pull all retro beads linked to the formula, or all retro beads system-wide? What format does the synthesis take? How does the human's decision get recorded and acted on? The step definition shown is too bare to implement.

**[Open Questions — Token/cost budget for Layer 2 not addressed]**

Constraint says "minimal context tax" but Layer 2 ("review all artifacts produced during this workflow") could be expensive for long workflows. No budgeting or truncation strategy is specified. This gap is especially notable given that "minimal context tax" is an explicit constraint. The question of what counts as "all artifacts" and how to bound scope needs to be in the open questions at minimum.

**[Implementation Sketch — Retro bead lifecycle not defined]**

Open Question 3 notes the backlog risk but only gestures at linking as a solution. Missing: what is the lifecycle of a retro bead? Does it stay open until an improvement bead closes? Does it auto-close after N days if unlinked? Who is responsible for triaging the retro backlog? Without a defined lifecycle, retro beads will accumulate as dead weight.

---

## NOTE

**[Open Questions — Missing questions that should be explicit]**

The five listed questions are appropriate, but several questions that would block implementation are missing from the list:
- What does the Layer 2 retro document format look like? (covered in BLOCK above, but the question itself is absent from Open Questions)
- How do retro layers interact? Does L1 inform whether L2 fires? Does L2 feed L3's batch?
- What is the success metric? How do we know the retro system is producing useful signal vs. noise?
- What are "rationalization counters"? (See BLOCK above)

Including these in Open Questions would make the gaps explicit for the author rather than invisible.

**[Assumptions — AI retro quality problem needs more treatment]**

Assumption 4 (AI retros can produce useful findings without human guidance) is flagged "unverified" but the design doesn't propose a verification approach. A note on how to calibrate or validate Layer 2 output quality — even just "run on 5 completed workflows and manually evaluate findings before widening" — would strengthen the recommendation.

**[Prior Art — Keystone analogy could be pressed further]**

The bmad-epic retrospective step is mentioned as inspiration but the design doesn't extract which specific elements map to this design (human gate? AI pre-digest? cadence?). Making the analogy more concrete would help justify the Layer 3 design choices.

**[Meta section — Useful observations, could become beads]**

The Meta section at the end (observations on using design-pipeline) contains actionable findings: the formula doesn't specify where to commit artifacts, the formula doesn't include branch setup instructions. These should be filed as ks beads if not already done. Good observations, wrong document.

---

## Coverage

**Sections reviewed:** Problem Statement, Constraints, Findings (What Exists + What's Missing), Prior Art, Assumptions, Options A–D, Recommendation, Implementation Sketch (all three layers), Open Questions, Meta

**Lens questions applied:**
- Does it address every requirement from the parent bead? → **NO** (rationalization counters missing)
- Does it cover all three layers adequately? → **Partially** (Layer 1 adequate, Layers 2+3 thin)
- Are edge cases considered? → **Partially** (backlog risk noted; cost/token, lifecycle, and quality calibration are gaps)
- What's missing? → See BLOCK and CONCERN sections
- Are the open questions the right ones? → **Partially** — existing questions are correct, but several blocking questions are absent
