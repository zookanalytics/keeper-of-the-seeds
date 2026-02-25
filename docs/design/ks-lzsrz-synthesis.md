# Validation Review Synthesis: Three-Layer Architecture Design Doc

**Bead:** ks-fiy4n | **Date:** 2026-02-24
**Document reviewed:** `docs/designs/ks-lzsrz-three-layer-architecture.md`
**Lenses applied:** feasibility, adversarial, completeness

---

## Overall Assessment: NOT READY

The document cannot advance to human sign-off in its current state. All three lenses returned NOT READY independently, and they converge on the same root cause.

---

## Root Cause

**The document was not updated after two critical events:**

1. **Human feedback (ks-qz7l4)** — 5 feedback items were specified for incorporation. The dependency bead was closed by polecat/furiosa, but no changes were made to the document. The git history confirms: the furiosa branch has only the original commit plus a gitignore change. Zero feedback was incorporated.

2. **Research findings (ks-on7br)** — The companion research bead found that Gas Town's rig config mechanism exists, is fully implemented, and is documented. It produced 4 explicit corrections to claims in the design doc. None were incorporated.

Additionally, **the core problem was fixed** in commit `de003eb` (ks-4217r) — `keeper/settings/config.json` now exists with a working `test_command`. The document still describes this as missing.

The document is a snapshot from before the research phase, presented as if it's post-research and post-feedback. This makes it misleading as a decision record.

---

## Consolidated Findings

### BLOCKs (must resolve before advancing)

| # | Finding | Lenses | Resolution |
|---|---------|--------|------------|
| B1 | Problem statement is factually incorrect — rig config mechanism exists, config file exists | Feasibility, Adversarial, Completeness | Rewrite problem statement to reflect current state |
| B2 | Human feedback (5 items) not incorporated despite dependency bead being closed | Feasibility, Completeness | Incorporate feedback or re-open ks-qz7l4 |
| B3 | Research findings (4 corrections) not reflected | Completeness | Update claims per ks-on7br corrections |
| B4 | Document argues for a decision already implemented (ks-4217r) | Adversarial | Reframe as decision record documenting rationale for action taken |

### CONCERNs (should be addressed)

| # | Finding | Lenses | Resolution |
|---|---------|--------|------------|
| C1 | "Evolve toward C" has no defined trigger conditions | Adversarial | Define 2-3 concrete triggers |
| C2 | "No work wasted" migration claim understates schema mismatch | Adversarial | Acknowledge impedance mismatch explicitly |
| C3 | Silent skip vs fail-that-pauses not resolved (human answered Q3) | Adversarial, Completeness | Incorporate the "fail-that-pauses" decision |
| C4 | Open Questions section has 4/5 questions already answered | Completeness | Move answered questions to "Resolved" section |
| C5 | `mol-polecat-work` variable table not shown | Completeness | Include or reference |
| C6 | "LLM directions" reframing changes Options B/C evaluation | Adversarial | Re-evaluate through this lens |

### NOTEs (observations)

| # | Finding | Lenses |
|---|---------|--------|
| N1 | Three-layer model is the document's lasting contribution | Adversarial |
| N2 | Prior art survey is thorough (8 systems) | Feasibility, Completeness |
| N3 | Document structure follows good design-doc conventions | Completeness |
| N4 | Research bead (ks-on7br) is better verified than this document | Adversarial |
| N5 | Option B's value increases under "LLM directions" framing | Adversarial |
| N6 | Session-start hook (ks-wr884) relationship underspecified | Completeness |

---

## Recommendation for Human

**The three-layer model is sound. The analysis was good at time of writing. But the document has not kept up with events.**

Two paths forward:

### Path 1: Update the document (preferred)
Incorporate the feedback, research corrections, and ks-4217r resolution. Reframe as a decision record. This preserves the analytical work and makes it a useful reference. Estimated effort: 1 standard-feature bead.

### Path 2: Close and extract
Accept that the document served its purpose (drove the research that led to ks-4217r and ks-on7br). Close ks-lzsrz, extract the three-layer model into `docs/brief.md` or a standalone concept doc, and move on. The decision is made; the implementation exists. The remaining value is in the conceptual model, not the options analysis.

Either path resolves the BLOCKs. Path 1 is more thorough. Path 2 is faster.

---

## Review Process Notes

This review was performed as a single-polecat three-lens pass rather than a convoy dispatch with separate polecats per lens. Findings are cross-referenced across lenses where they overlap. Each review file is self-contained and follows the `/seed-document-review` skill output format.

Files produced:
- `ks-lzsrz-review-feasibility.md` — Technical viability assessment
- `ks-lzsrz-review-adversarial.md` — Red-team stress test of assumptions
- `ks-lzsrz-review-completeness.md` — Coverage and gap analysis
- `ks-lzsrz-synthesis.md` — This document
