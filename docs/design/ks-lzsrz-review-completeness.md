# Review: Three-Layer Architecture Design Doc

Lens: **completeness**
Reviewer: polecat/rictus
Date: 2026-02-24

## Gate Assessment

- Does the doc address all questions raised? **NOT READY** (5 human feedback items unincorporated; 3 of 5 open questions have known answers that aren't reflected)
- Are the open questions resolved? **NOT READY** (Q1, Q3 have answers from research/feedback; Q2, Q6 partially addressed)
- Is anything missing for implementation? **READY** (Option A implementation is trivial and already done; remaining implementation is sub-bead scoping)

Overall: **NOT READY**

## BLOCK

- **Human feedback (ks-qz7l4) not incorporated.** The dependency bead specified 5 feedback items to incorporate before this validation review. None appear in the document:

  | Feedback Item | Status in Document |
  |---|---|
  | 1. Layer 3 is LLM directions, not shell commands | Not incorporated. Document frames Layer 3 as shell commands throughout. |
  | 2. Missing config should fail-that-pauses, not silent skip | Not incorporated. Open Question 3 still asks about this, but the human already answered it. |
  | 3. Implementation via sub-beads | Not incorporated. "Concrete Next Steps" section (line 235) lists tasks but doesn't specify they should be sub-beads. |
  | 4. Incorporate Gas Town research findings | Not incorporated. The research (ks-on7br) found that the mechanism exists and is documented. The document still says "mechanism doesn't exist." |
  | 5. Schema naming deferred pending research | Acknowledged as open question, but research has been completed and is not reflected. |

  This is a BLOCK because the document was explicitly required to have feedback incorporated before this review step. The validation review was sequenced after ks-qz7l4 for this reason.

- **Research findings (ks-on7br) not reflected.** The companion research bead produced 5 corrections to the design doc. The "Correction to Architecture Review" section of ks-on7br lists them explicitly:

  | Research Correction | Status in Document |
  |---|---|
  | "No mechanism exists" → mechanism exists | Still says "no mechanism exists" (line 10) |
  | "Layer 3 Missing entirely" → data missing, infrastructure complete | Still says "Missing entirely" (line 22) |
  | "A mechanism that doesn't exist" → mechanism exists and is documented | Still says "mechanism that doesn't exist" (line 28) |
  | Option A is "populate," not "extend" | Still framed as "extend" (line 81) |

  This is the same class of issue as the feedback incorporation above, but from a different source. Two independent inputs (human feedback + research findings) both require updates that haven't been made.

## CONCERN

- **Open Questions section has stale questions.** The document lists 5 open questions. Current known answers:

  | Question | Known Answer | Source |
  |---|---|---|
  | Q1: Config location (`settings/config.json` vs repo root) | `settings/config.json` is Gas Town's canonical location | ks-on7br research |
  | Q2: Schema naming | Deferred per human feedback; use Gas Town's naming for now | ks-qz7l4 feedback item 6 |
  | Q3: Silent skip behavior | Fail-that-pauses preferred | ks-qz7l4 feedback item 2 |
  | Q4: Scope of implementation | Sub-beads | ks-qz7l4 feedback item 4 |
  | Q5: Option B hybrid timing | Not answered | — |

  Four of five questions have answers. Presenting them as "open" invites re-litigation of decisions already made.

- **The `mol-polecat-work` formula is referenced but not included.** The document states (line 28): "Gas Town's built-in `mol-polecat-work` has Layer 3 variable slots (`test_command`, `build_command`, etc.) documented as 'Source: rig config.'" This formula exists in Gas Town's codebase (listed by `bd formula list`), but the document doesn't include its variable table or show the actual step descriptions that use these variables. Since this is the formula where rig config flows into polecat execution, the omission matters — a reader can't verify the claim without it.

- **Verified Assumptions table is incomplete post-research.** The table has 11 entries, all from the original research phase. The ks-on7br research verified additional facts (schema has `type` and `version` validation, error handling returns nil on missing file, no other rigs have config, Gas Town actively invests in the mechanism). These should be added or the existing entries updated with research confirmation status.

- **No mention of ks-4217r (the actual config creation).** The config file for keeper was created in commit `de003eb` as part of bead ks-4217r. This is the concrete action that partially resolves the document's core problem. It's not mentioned anywhere — neither as prior art, current state, nor as a dependency resolution. A complete decision record should reference the implementing bead.

## NOTE

- **The document's structure follows good design-doc conventions.** Executive summary, problem evidence, options analysis, comparison matrix, recommendation with rationale, open questions, verified assumptions. The structure itself is sound.

- **Prior Art Survey covers 8 systems comprehensively.** BMAD, superpowers, Claude Code, OpenHands, Cursor, Devin, SWE-agent, CrewAI. The common pattern extraction ("every system separates process/domain/config") is a useful generalization.

- **The Appendix sections are well-organized.** Verified assumptions and prior research sources provide traceability. The assumption verification methodology (marking each as confirmed/unverified with evidence) is a pattern worth standardizing.

- **Missing: how the session-start hook (ks-wr884) relates to rig config.** The document mentions ks-wr884 three times (lines 42, 89, 229) as blocked on this decision. But it doesn't describe how the hook would use the config — would it inject skill references? Read the config and set environment variables? This connection is important for understanding the downstream impact of the architecture choice.

## Coverage

Sections reviewed: Executive Summary, Three-Layer Model, Current State, The Problem (Evidence), End-to-End Trace, Prior Art Survey, Options A/B/C, Comparison Matrix, Recommendation, Concrete Next Steps, Open Questions, Verified Assumptions, Appendix (both)

Lens questions applied:
- Does it address every requirement? → No. Human feedback items (5) and research corrections (4) are unincorporated.
- What's missing? → Updated problem statement, feedback incorporation, research findings, reference to ks-4217r, trigger conditions for Option C evolution, `mol-polecat-work` variable details.
- Are edge cases considered? → Partial. The comparison matrix covers failure modes per option. But the "LLM directions" reframing changes the edge case analysis for Options B/C.
- Are cross-cutting concerns addressed? → The session-start hook relationship is mentioned but not detailed. The relationship between rig config and skill enforcement is underspecified.
