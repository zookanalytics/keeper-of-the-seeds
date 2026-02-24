# Retro Spike: ks-jiqsy Design Pipeline Execution

Testing whether AI retro produces useful signal by analyzing this workflow's own execution.

## 1. Process Compliance

| Step | Followed? | Notes |
|------|-----------|-------|
| research | Partial | Research and draft merged into one pass. The research skill says "Do NOT propose solutions — map the territory" but the research doc included options (draft content). Crew blended steps 1-2, which was efficient but violated the formula's step separation. |
| draft | Yes | Design doc produced with options, tradeoffs, recommendation. |
| dispatch-reviews | Yes | Three child beads created with --parent for hierarchical IDs. Convoy dispatched. |
| synthesize | Yes | Synthesis produced with consensus/conflicts/blockers/open questions. |
| human-gate | Yes | Four questions surfaced, human provided direction on all four. |
| finalize | In progress | Applying human feedback now. |

**Finding**: Step separation between research and draft was violated. The research skill's "do NOT propose solutions" constraint was not enforced. This is a **discipline gap** — the skill exists but the agent rationalized merging steps because "the topic was familiar."

**Rationalization observed**: "For a domain-expert (crew) working on a familiar topic, the research and draft steps blur together." This is exactly the kind of excuse the research skill should counter.

## 2. Artifact Quality

- **Research doc**: Structured correctly per skill:research format. Good internal context survey. But thin on external prior art (only listed keystone and BMAD briefly, didn't dig into specific mechanisms).
- **Design doc**: Four options well-analyzed. Recommendation was reasonable but reviewers correctly identified it optimized for deployment ease over learning value.
- **Reviews**: All three were substantive. Feasibility caught the hook API blocker. Adversarial caught the incomplete learning loop. Completeness caught the missing requirement (rationalization counters). No rubber-stamps.
- **Synthesis**: Accurately distilled three reviews. Surfaced the right questions to the human.

**Finding**: Review convoy produced genuinely distinct findings per lens. The three-lens minimum (feasibility, adversarial, completeness) was well-chosen for design documents.

## 3. Review Convoy Effectiveness

| Reviewer | Lens | Unique findings | Overlap |
|----------|------|-----------------|---------|
| nux | feasibility | Hook API blocker, aspect syntax wrong, Layer 3 most buildable | Hook API (shared with all) |
| slit | adversarial | Learning loop incomplete, threshold undefined, L1 = weakest signal | Hook API (shared) |
| rictus | completeness | Rationalization counters missing, artifact format undefined, missing open questions | Hook API (shared), feedback loop (shared with adversarial) |

**Finding**: High distinctiveness across lenses. Each reviewer caught things the others missed. The overlap on hook API is appropriate — it's a genuine cross-cutting blocker. The adversarial reviewer's finding about the learning loop gap was the most important contribution.

## 4. Rationalizations Observed

| Rationalization | Where | Which skill should counter it |
|-----------------|-------|-------------------------------|
| "Research and draft blur together for familiar topics" | research step | research skill — add to Red Flags |
| "Hook API can be figured out during implementation" | design doc | research skill — add to "Do not shortcut" section |
| "The design recommends L1 first because it's cheapest" | recommendation | document-review skill — add to rationalization table: "Cheapest first" ≠ "most valuable first" |

## 5. Cycle Efficiency

- **Good**: Review convoy ran 3 polecats in parallel. All completed.
- **Good**: Human gate batched 4 questions into one checkpoint.
- **Bad**: Crew did research + draft + dispatch manually instead of having polecats handle research. For familiar topics this was faster, but it doesn't scale — the formula should work even when the topic is unfamiliar.
- **Bad**: Two polecats were zombies and needed Deacon recovery. Infrastructure issue, not formula issue.
- **Observation**: Branch creation and artifact path conventions were not in the formula, requiring crew to invent them. This slowed the start of the workflow.

## 6. Skill Gaps

| Gap | Impact | Suggested action |
|-----|--------|-----------------|
| No artifact path convention in formulas | Crew invented docs/designs/ ad hoc | Add convention to design-pipeline formula or conventions.md |
| No branch setup instructions in formulas | Crew had to know git checkout -b | Add to formula research step: "Create branch named after parent bead" |
| Research skill doesn't enforce step separation from draft | Steps blurred | Add to research skill Red Flags: "If you're proposing solutions, you've left research mode" |
| No retro skill existed | This retro was done ad hoc | The retro steps now in the formula address this, but a retro skill would standardize the analysis |

## Spike Verdict

**AI retro produces useful, actionable signal.** This analysis identified:
- 3 specific rationalizations to add to skill tables
- 4 concrete skill/formula gaps with suggested fixes
- 1 process compliance violation with a clear pattern
- Quantitative review convoy effectiveness data

The signal is NOT generic. It's specific to this execution and produces items that can be directly acted on. Recommend proceeding with Layer 3 retro steps in formulas.
