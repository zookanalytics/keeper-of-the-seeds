# Design: Retrospective Checkpoints for Continuous Learning

Bead: ks-jiqsy
Phase: research → **draft**

## Problem Statement

Keeper's learning loop exists as documented vision (brief.md) but has no implementation. Post-completion hooks are empty directories. No mechanism automatically observes outcomes, surfaces patterns, or feeds improvements back into skills and formulas. The system can't learn from its own execution.

## Constraints

- **Beads all the way down**: retro findings must be ks beads, not a parallel data store (brief.md design principle)
- **Zero framework cognition**: skills guide judgment, hooks don't replace it (brief.md design principle)
- **Minimal context tax**: retro steps can't bloat every workflow with heavy analysis
- **Gas Town primitives**: must use existing gt/bd infrastructure (hooks, beads, mail, convoy)
- **Human time optimization**: AI should do groundwork; surface only actionable items to human

## Findings

### What Exists (documented, not implemented)

1. **Post-completion hook concept** — `hooks/post-completion/observe-outcomes.sh` placeholder. Designed to fire after bead closure, observe outcomes, file ks beads.
2. **Retro bead convention** — conventions.md defines: file ks beads for patterns, link to existing issues for frequency tracking, high-frequency issues get priority.
3. **Skill improvement lifecycle** — brief.md Phase 3: intake → red test → draft → green test → adversarial test → review → merge.
4. **Learning loop phases** — brief.md roadmap: implement retro review process (step 12), file skill improvement beads (step 13), run skill-improvement molecule (step 14).

### What's Missing

1. No actual hook implementation
2. No formula or skill for conducting retros
3. No distinction between AI-driven vs human-involved checkpoints
4. No definition of when in a workflow retros should fire
5. No mechanism for retro findings to trigger keeper changes
6. No template for what a retro checkpoint produces

### Prior Art

**Keystone bmad-epic**: Has an explicit retrospective step at the end of epic processing. Human-gated. Run via Claude with `/bmad-bmm-sprint-status`.

**BMAD method**: Sprint ceremonies (retrospectives) are explicit Phase 4 steps. Human reviews progress at sprint boundaries.

**git-workflow**: Post-merge cleanup + state verification. Not a retro per se, but a "verify the system is clean" pattern that retros could extend.

## Assumptions

| Assumption | Status | Evidence |
|------------|--------|----------|
| Post-completion hooks can access bead metadata | plausible | brief.md references it, hooks directory exists, but no implementation to confirm API |
| Polecats can file ks beads from any rig | confirmed | Cross-rig routing with ks prefix works |
| Linked-bead frequency is queryable | plausible | conventions.md describes it, bd likely supports counting links |
| AI retros can produce useful findings without human guidance | unverified | Needs testing — risk of generic/low-signal output |

## Options

### Option A: Retro as post-completion hook only

The hook fires after any bead closes. It examines the bead's history (status changes, time in each phase, escalations, gate outcomes) and files ks beads for anomalies.

**Tradeoffs**: Automatic, zero workflow changes needed. But hooks are blunt — they see outcomes, not the reasoning that led there. Low-signal risk.

### Option B: Retro as formula aspect

A cross-cutting aspect (`retro.formula.toml`, type: aspect) that can be composed into any workflow. Adds a retro step after the last step. The retro step runs an AI analysis of the full workflow execution.

**Tradeoffs**: Opt-in per formula, deeper analysis than a hook. But requires formula composition to work (not yet proven). Adds context to every workflow.

### Option C: Retro as explicit formula steps (two flavors)

Add retro steps directly to formulas that need them. Two flavors:

- **AI retro step**: Automatic, runs after pipeline completion. Analyzes: did the workflow follow the formula? Were skills applied? What was the quality of intermediate artifacts? Files ks beads for patterns.
- **Human retro step**: Gated checkpoint where AI pre-digests findings and presents a summary. Human decides what to act on.

**Tradeoffs**: Most flexible, most visible. But requires editing each formula. Risk of retro fatigue if overused.

### Option D: Layered approach (recommended)

Three layers, deployed incrementally:

1. **Layer 1: Post-completion hook** — Lightweight, automatic. Fires on every bead close. Checks: did the workflow complete all steps? Were there escalations? How long did it take? Files ks beads only for clear anomalies (skipped steps, unusual duration, repeated escalations).

2. **Layer 2: AI retro aspect** — Opt-in per formula via `compose.aspects = ["retro"]`. Adds a deeper analysis step: review all artifacts produced, check skill compliance, identify what worked vs what didn't. Produces a structured retro document.

3. **Layer 3: Human retro gate** — Explicit step in high-value formulas (design-pipeline, architecture). AI synthesizes accumulated retro findings and presents a batch summary. Human reviews, decides what becomes a keeper improvement bead.

**Deployment order**: Layer 1 first (cheapest, broadest coverage). Layer 2 when aspect composition works. Layer 3 for specific workflows where human review has high ROI.

## Recommendation

**Option D (layered approach)**. Start with Layer 1 (post-completion hook) because it:
- Requires no formula changes
- Covers all workflows automatically
- Produces the frequency data that tells us where Layers 2 and 3 are needed
- Aligns with "start thin, grow through use" principle

The hook should be minimal: check completion metadata, file ks beads for anomalies. The beads accumulate. When a pattern reaches threshold (N linked beads), that's the signal to add a Layer 2 aspect or Layer 3 gate to the relevant formula.

## Implementation Sketch

### Layer 1: Post-completion hook

```
hooks/post-completion/observe-outcomes.sh
```

Triggered after `bd close <bead>`. Receives bead ID. Checks:
- Did all molecule steps complete? (bd mol status)
- Were there escalations? (gate history)
- Duration vs estimate (if estimate was set)
- Were any steps skipped or done out of order?

Files ks bead only if anomaly detected. Links to existing ks issue if pattern matches.

### Layer 2: Retro aspect formula

```toml
# retro.formula.toml
type = "aspect"
description = "Post-workflow retrospective analysis"

[[steps]]
id = "retro-analysis"
title = "Retrospective: {{topic}}"
after = "{last_step}"  # aspect injection point
description = "Review all artifacts produced during this workflow..."
```

### Layer 3: Human retro gate

Added as a step in specific formulas:

```toml
[[steps]]
id = "human-retro"
title = "Human retrospective checkpoint"
needs = ["finalize"]
gate = { type = "human" }
description = "AI synthesizes accumulated retro findings..."
```

## Open Questions

1. What's the hook API? How does post-completion receive bead context? Need to verify with gt/bd source.
2. What's the anomaly threshold for filing ks beads? Too low = noise, too high = missed patterns.
3. How do we prevent retro beads from drowning the backlog? Linking to existing issues helps, but we need a review cadence.
4. Should AI retros have access to the full conversation transcript, or just the artifacts? Transcripts have more signal but much higher token cost.
5. How does aspect composition actually work in bd cook? Not yet tested.

---

## Meta: Design-Pipeline Process Observations

*Notes on using the design-pipeline formula for this work:*

1. **Branch creation worked well** — `ks-jiqsy` branch name from parent bead is clean and traceable.
2. **Research + draft merged naturally** — For a domain-expert (crew) working on a familiar topic, the research and draft steps blur together. The research skill's output format forced good structure though.
3. **No convoy dispatch yet** — This is where the formula gets interesting. Need to dispatch review polecats next.
4. **Missing: formula doesn't say where to commit the document** — Had to invent `docs/designs/` directory. Should the formula specify an artifact path convention?
5. **Missing: formula doesn't reference how to create the branch** — Had to know to use `git checkout -b`. Should the formula's first step include branch setup instructions?
