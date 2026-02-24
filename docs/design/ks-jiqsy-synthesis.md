# Synthesis: Retrospective Checkpoints Reviews

Bead: ks-jiqsy
Reviewers: nux (feasibility), slit (adversarial), rictus (completeness)

## Consensus

All three reviewers agree on these points:

1. **Hook API is undefined and blocks Layer 1.** The post-completion hook directory exists but there's no API contract — we don't know what args/env vars the hook receives, whether `bd` is on PATH, or how bead context is injected. The design recommends building this first but all reviewers flag it as the primary blocker.

2. **Layer 3 (explicit formula steps) is the most immediately buildable.** It uses only proven primitives: `[[steps]]` with `gate = { type = "human" }`. No unverified APIs, no untested composition.

3. **AI retro signal quality is unverified and load-bearing.** The assumption that AI can self-assess workflow quality is the foundation of Layers 2 and 3, but has no test plan. Risk: generic/boilerplate output that creates retro fatigue.

4. **The feedback loop from retro bead to keeper improvement is a black box.** The design ends at "file a ks bead." The actual learning loop (retro finding → skill/formula update) is not specified. Without this, the system detects but doesn't learn.

## Conflicts

**Deployment order:** The design says L1→L2→L3. Feasibility argues L3→L1→L2 (most buildable first). Adversarial argues L1 has the weakest signal and L2/L3 should be unblocked in parallel.

**Resolution:** Feasibility wins. Flip to **L3 → L1 → L2**. Layer 3 gives us immediate value with zero infrastructure risk. Layer 1 follows after a hook API spike. Layer 2 follows after aspect composition is validated.

## BLOCKs (must resolve before implementation)

| # | Finding | Source | Resolution |
|---|---------|--------|------------|
| 1 | Hook API undefined | all three | Spike: verify gt/bd hook contract before building Layer 1 |
| 2 | Rationalization counters not addressed | completeness | Original bead requirement — must be specified or explicitly scoped out |
| 3 | Feedback-to-keeper loop unspecified | adversarial + completeness | Define: retro bead → triage → skill-improvement formula → keeper commit |
| 4 | Layer 2 aspect syntax doesn't match reality | feasibility | Real syntax uses `[[advice]]`/`[[pointcuts]]`, not `after = "{last_step}"` |
| 5 | Layer 2 artifact format undefined | completeness | Define retro document template before building |
| 6 | Anomaly threshold mechanism undefined | adversarial | Define escalation criteria with provisional values |

## Open Questions for Human

1. **Deployment order flip — agree?** Start with Layer 3 (retro steps in design-pipeline and architecture formulas) instead of Layer 1 (hook). This means we get learning value immediately from human-involved retros while we spike the hook API separately.

2. **Scope of learning loop closure.** The reviews correctly flag that "file a ks bead" isn't enough. Should the design specify the full loop (retro bead → red test → skill draft → green test → merge), or is that a separate bead? It's already described in brief.md Phase 3, but not connected to this design.

3. **AI retro validation spike.** Before building Layer 2, should we manually run a retro analysis on 3-5 completed workflows to see if AI produces useful signal? This would de-risk the assumption before automating it.

4. **Rationalization counters.** The original bead mentions these. They're tracked per-skill in the rationalization tables (from superpowers patterns). The retro system could surface new rationalizations observed during execution. Should that be a Layer 2 output format requirement?

## Revised Recommendation

**Phase 1 (now):** Add explicit retro steps to `design-pipeline` and `architecture` formulas. Two flavors:
- AI retro step (automatic, post-finalize): reviews workflow execution, files ks beads for patterns
- Human retro gate (explicit checkpoint): AI pre-digests accumulated findings, human decides what to act on

**Phase 2 (after hook API spike):** Implement Layer 1 post-completion hook for lightweight automatic anomaly detection across all workflows.

**Phase 3 (after aspect composition validated):** Extract retro into composable aspect formula for opt-in use across any workflow.

Each phase includes a validation spike before committing to full implementation.
