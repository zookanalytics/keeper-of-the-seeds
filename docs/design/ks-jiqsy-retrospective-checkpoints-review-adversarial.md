## Review: Retrospective Checkpoints for Continuous Learning
Lens: adversarial
Reviewer: slit (keeper/polecats/slit)
Bead: ks-jiqsy.2

### Summary

The design is architecturally coherent and the layered approach is sensible in principle, but it defers the hardest problems — does AI retro produce useful signal, how does anomaly data become skill improvement, and what prevents retro beads from drowning the backlog — to later phases that may never arrive. The recommendation to start with Layer 1 optimizes for ease of deployment over learning value, and two load-bearing technical assumptions remain unverified. The design should not advance to implementation until the hook API is confirmed and the undefined threshold mechanism is resolved.

---

### BLOCK

- **[Open Questions / Implementation Sketch, Layer 1]**: The hook API is unverified but the implementation sketch treats it as settled. The design notes: "What's the hook API? How does post-completion receive bead context? Need to verify with gt/bd source." Yet the implementation sketch immediately describes the hook checking `bd mol status`, gate history, duration, and step ordering — all of which require specific API capabilities. If the hook receives only a bead ID and nothing else, the entire Layer 1 design needs to be rethought. This is not a planning risk to track — it's a prerequisite. **The implementation sketch cannot be valid before the API is confirmed.** Resolution: verify the hook API before advancing to implementation; update the design to match what actually exists.

- **[Recommendation / Implementation Sketch]**: The anomaly threshold mechanism (`N linked beads → trigger Layer 2/Layer 3`) is load-bearing but completely undefined. This is the core signal extraction logic. Without a calibrated N, Layer 1 is a data sink with no defined output condition — it accumulates beads indefinitely, and no one knows when to act. Open Question 2 acknowledges this ("too low = noise, too high = missed patterns") but treats it as a tuning detail. It is not — it is the decision rule for the entire system. A system that observes forever without triggering is not a learning loop. Resolution: define the threshold mechanism before implementation, even if the initial value is provisional and monitored.

---

### CONCERN

- **[Assumptions table]**: "AI retros can produce useful findings without human guidance" is marked "unverified — needs testing — risk of generic/low-signal output." This is the foundational bet for Layers 2 and 3, yet the design proceeds to specify both layers in detail without first proposing a validation spike. If AI retro output is generic (which is likely given that agents summarizing their own work tend toward self-congratulatory or boilerplate analysis), Layer 2 produces documents no one reads and Layer 3 asks humans to synthesize noise. The entire system assumes this problem is solvable. Resolution: this assumption needs a spike test before Layer 2 or 3 are designed in detail. A single pilot retro on a completed workflow would confirm or refute it.

- **[Recommendation]**: The design is a detection system, not a learning system. It has no defined path from "anomaly bead filed" to "skill improved." The brief.md Phase 3 lifecycle (intake → red test → draft → green test → adversarial test → review → merge) is not referenced anywhere. How does an anomaly bead become a skill draft? Who owns that transition? What is the SLA? The constraint says "Human time optimization: AI should do groundwork; surface only actionable items to human." But "actionable" implies the action is defined. Without a specified pipeline from retro finding to skill change, the system converts execution into paperwork. Resolution: the design should specify the handoff — what happens to a Layer 3 finding after the human reviews it.

- **[Recommendation — start with Layer 1]**: Starting with Layer 1 because it "requires no formula changes" optimizes for deployment ease rather than learning value. Layer 1 observes process compliance only: did steps complete, were there escalations, how long did it take. It cannot observe content quality — whether the polecat applied the skill correctly, whether the design was well-reasoned, whether the artifact was fit for purpose. The richest learning signals live in Layer 2 and Layer 3. Deploying Layer 1 first means months of data collection with the weakest signal source, while the more valuable layers wait for "when aspect composition works." If aspect composition is a prerequisite for Layer 2, that should be unblocked in parallel, not sequenced after Layer 1.

- **[Open Questions, Q3]**: Retro beads flooding the backlog is acknowledged briefly ("linking to existing issues helps, but we need a review cadence") but the mitigation is insufficient. In an active rig, even conservative anomaly detection generates significant volume. Without a defined review cadence, owner, and SLA, retro findings accumulate without processing. The design's constraint — "surface only actionable items to human" — cannot be satisfied by convention alone. It requires a structural filter. Resolution: define a retro review process (who, how often, what constitutes an actionable finding) as part of this design, not as a follow-on.

- **[Open Questions, Q5]**: Aspect composition is required for Layer 2 but explicitly unproven. "How does aspect composition actually work in bd cook? Not yet tested." If it doesn't work or requires significant infrastructure, Layer 2 needs an alternative approach. This should be flagged in the options analysis — Option B was rejected in favor of Option C and D partly because aspect composition "is not yet proven," but Layer 2 of Option D reintroduces exactly this dependency. The design appears to have inconsistently inherited the risk it discounted in Option B. Resolution: verify aspect composition works or specify a fallback approach for Layer 2.

---

### NOTE

- **[Constraints — "Zero framework cognition"]**: The constraint says "hooks don't replace [AI judgment]." Layer 1 is purely algorithmic — anomaly detection based on metadata. This is fine on its own, but the connection from Layer 1 findings to improved AI judgment requires human action (Layer 3) that is opt-in and not yet defined. The constraint is not violated, but neither is it fulfilled. The system is currently structured to observe execution without demonstrably improving it.

- **[Options analysis]**: Options A through C are presented and compared, but the comparison for Option D doesn't clearly explain why D is better than a minimal Option C (adding retro steps to a small number of high-value formulas only, without the hook infrastructure). A targeted Option C would have lower blast radius and no dependency on unverified hook APIs or aspect composition. The case for layering rather than selective direct inclusion deserves a stronger argument.

- **[Meta section]**: The process observations at the end are genuinely useful. The finding that "formula doesn't say where to commit the document" and "formula doesn't reference how to create the branch" identifies concrete gaps that will affect every design-pipeline user. These should be promoted to ks beads rather than left as a footnote — they're more actionable than the retrospective system they're documenting.

- **[Assumptions table — linked-bead frequency]**: "Linked-bead frequency is queryable — plausible — bd likely supports counting links." This is the second load-bearing "plausible" assumption. If `bd` doesn't expose link frequency queries, the threshold mechanism for Layer 1 escalation has no implementation path. Worth confirming alongside the hook API.

---

### Coverage

Sections reviewed: Problem Statement, Constraints, Findings (all subsections), Assumptions, Options (A–D), Recommendation, Implementation Sketch (Layers 1–3), Open Questions, Meta observations.

Lens questions applied:
- What's the strongest argument against this approach? (Learning loop is incomplete — detection without a defined path to improvement)
- What would a skeptic challenge? (AI retro signal quality, threshold mechanism undefined, Layer 1 = weakest signal first)
- Where is the reasoning weakest? (Hook API assumed functional; threshold value treated as tuning detail; aspect composition risk reintroduced after being discounted)
- What failure modes are not addressed? (Retro bead backlog flood, no defined owner/cadence for retro processing, no defined path from finding to skill change)
- Which assumptions are load-bearing? (Hook API, linked-bead frequency, AI retro signal quality, aspect composition)
