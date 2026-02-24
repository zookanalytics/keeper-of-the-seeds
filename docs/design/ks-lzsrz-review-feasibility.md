# Review: Three-Layer Architecture Design Doc

Lens: **feasibility**
Reviewer: polecat/rictus
Date: 2026-02-24

## Gate Assessment

- Can this actually be implemented? **READY** (Option A is trivially implementable — and has already been partially implemented)
- Are there technical blockers? **NOT READY** (document describes a problem state that no longer exists)
- Does the Gas Town integration work as described? **READY** (the `loadRigCommandVars()` → formula vars pipeline is confirmed working)

Overall: **NOT READY**

## BLOCK

- **Executive Summary / Current State (lines 10, 30-31)**: The document states "no mechanism exists for rigs to declare their tooling" and "Layer 3 (Rig Config): Missing entirely." The companion research (ks-on7br) explicitly corrected this: the mechanism exists and is fully implemented — only keeper's data file was missing. Furthermore, `keeper/settings/config.json` was created in commit `de003eb` (ks-4217r) on 2026-02-24 with a working `test_command`. **The foundational problem claim is now factually incorrect.** The document cannot advance to human sign-off with a problem statement that has already been solved. Suggested resolution: Update the document to reflect that the infrastructure exists and the config file has been created. Reframe the remaining value as documentation of the three-layer model and future evolution path (Options B/C).

- **Dependency bead ks-qz7l4 closed without changes**: The "Incorporate feedback" bead (ks-qz7l4) was closed by polecat/furiosa, but the design doc on that branch (polecat/furiosa/ks-qz7l4@mm090xud) shows only the original commit — no feedback was actually incorporated. Five pieces of human feedback were specified (reframe Layer 3 as LLM directions, change silent skip to fail-that-pauses, incorporate research findings, use keeper-native naming, implementation via sub-beads). None of these appear in the current document. This is a BLOCK because the document was supposed to be updated before this validation review. Suggested resolution: Either re-open ks-qz7l4 and actually incorporate the feedback, or incorporate it as part of this review's remediation.

## CONCERN

- **"Next Steps" section (lines 236-240)**: Step 1 says "Create `keeper/settings/config.json` with test_command." This has already been done (ks-4217r). Steps 2-5 may or may not still be relevant. The next-steps section needs to be updated to reflect current state. Without this update, a human reviewer would approve work that's already done.

- **Option A framing (lines 81-111)**: The document frames Option A as "extend current config" requiring "minimal changes." The research bead clarified this is more accurately "populate the existing config" — no extension needed. The framing overstates the implementation effort, which could mislead priority decisions. The config file already exists, the schema is already documented in Gas Town's `docs/reference.md`, and the Go code needs zero changes.

- **End-to-end trace (lines 44-56)**: The trace shows `loadRigCommandVars()` returning empty because the config file doesn't exist. This trace is now a historical artifact — the file exists. The trace is still valuable as documentation of how the pipeline works, but should be framed as "how it worked before the fix" rather than "current state."

## NOTE

- **Prior art survey (lines 64-75)**: Thorough and well-structured. No issues found. The survey correctly identifies that every system separates process logic from domain knowledge from project config.

- **Comparison matrix (lines 203-214)**: Clear and balanced. The matrix supports the recommendation without overselling Option A or dismissing Options B/C.

- **Open questions (lines 244-255)**: Question 1 (config location) is answered by the research — Gas Town's intended location is `settings/config.json`. Question 3 (silent skip behavior) has human feedback: should be fail-that-pauses, not silent skip. These should be resolved in the document rather than left open.

- **Verified assumptions table (lines 259-271)**: 10 of 11 assumptions are marked confirmed. The one unverified assumption (Claude Code `.claude/commands/` shadowing in worktrees) remains unverified. This doesn't block Option A but would be needed for Option B.

## Coverage

Sections reviewed: Executive Summary, Three-Layer Model, Current State, The Problem (Evidence), End-to-End Trace, Prior Art Survey, Options A/B/C, Comparison Matrix, Recommendation, Next Steps, Open Questions, Verified Assumptions, Appendix

Lens questions applied:
- Can this be built? → Yes, Option A is trivially implementable (and partially done)
- What's the hardest part? → Nothing; the hard part (Go infrastructure) already exists
- What could go wrong during implementation? → Nothing significant for Option A; Options B/C have identified risks in the comparison matrix
- Are there technical blockers? → The document itself is the blocker — it describes a solved problem without reflecting the solution
