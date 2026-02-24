# Review: Three-Layer Architecture Design Doc

Lens: **adversarial**
Reviewer: polecat/rictus
Date: 2026-02-24

## Gate Assessment

- What are the weakest assumptions? **NOT READY** (the document's problem statement is its weakest assumption, and it's wrong)
- What breaks first? **NOT READY** (the "Option A now, evolve toward C" strategy has an unexamined migration path)
- What failure modes are unaddressed? **NOT READY** (human feedback on silent-skip behavior was not incorporated)

Overall: **NOT READY**

## BLOCK

- **The document is arguing for a decision that was already made and executed.** The recommendation is "Option A now" — create `settings/config.json`. This was done in ks-4217r before this review was dispatched. The document's entire argumentative structure (problem → options → recommendation → next steps) is built around a decision that no longer needs to be made. This makes the document misleading as a decision record: a future reader would think the decision was made based on this analysis, when in fact the implementation preceded the validation review. Suggested resolution: Reframe the document as a decision record that documents the rationale for the action already taken, and shift forward-looking content toward the Option B/C evolution path.

- **Human feedback was specified but not incorporated (ks-qz7l4).** Five specific feedback items were given. The most architecturally significant was: "Layer 3 is LLM directions, not shell commands." This reframes the entire conceptual model — config entries are prompts directed at the LLM, which usually ARE commands or skill invocations, but the frame is "LLM directions." The document currently frames Layer 3 as concrete shell commands throughout (e.g., `bash tests/cook-all-formulas.sh && shellcheck hooks/**/*.sh`). This conceptual error affects Options B and C design, not just Option A. If Layer 3 is LLM directions, then Option B's CLAUDE.md approach and Option C's `rig.toml` approach need different evaluation criteria. Suggested resolution: Incorporate the "LLM directions" framing. Re-evaluate Options B/C through this lens.

## CONCERN

- **"Evolve toward C when rig count demands it" — what triggers the evolution?** The recommendation says to evolve toward Option C "when rig count demands it" but provides no criteria for what "demands it" means. Is it 3 rigs? 10? When the first rig needs per-context commands (quick vs thorough)? When someone needs a rig.toml feature that config.json can't express? Without a trigger, "evolve later" means "never evolve" — the document becomes a permanent deferral of the structured manifest. What would resolve this: Define 2-3 concrete trigger conditions. Example: "Move to Option C when (a) 3+ rigs have config.json files and share the same schema frustrations, or (b) a rig needs per-context commands that `merge_queue.*_command` can't express."

- **The "no work is wasted" migration claim (line 228) is optimistic.** The document claims "Option A config files become seed data for Option C's rig.toml." But the migration path is underspecified. Config.json has `merge_queue.test_command`. Rig.toml (Option C) has `commands.test.default`. The nesting, naming, and semantics differ. The migration is not "extract values" — it's "redesign the schema and port values." This is still feasible, but the document should be honest about the impedance mismatch rather than framing it as trivial. What would resolve this: Acknowledge the schema mismatch explicitly. Show a concrete before/after for the migration.

- **Silent skip vs fail-that-pauses.** Human feedback specifically said: "Warning or fail, not silent skip. Preference is fail-that-pauses (blocking) if possible." The document's Open Question 3 asks about this behavior, but the human already answered it. The current system silently skips when commands are empty. The document doesn't address how to change this behavior — it's not clear whether this requires a Gas Town code change or can be handled via hook/formula logic. What would resolve this: Investigate whether fail-that-pauses can be implemented without Gas Town changes (e.g., a pre-merge hook that checks if test_command was empty and blocks), or whether it requires a Gas Town PR.

- **The "Schema naming" concern (Open Question 2) has a live tension.** The document asks whether to rename `merge_queue.test_command` to something rig-neutral. But Gas Town's schema is in Go structs — keeper can't rename it unilaterally. If the naming is wrong, it needs a Gas Town PR. If keeper should have its own naming, it needs a separate config mechanism (which contradicts Option A). The document doesn't resolve this tension. What would resolve this: Acknowledge that keeper must use Gas Town's naming as-is for Option A. If keeper-native naming is desired (per human feedback), that's an argument for Option C, not a modification to Option A.

## NOTE

- **The three-layer model itself is the document's lasting contribution.** Regardless of which option is implemented, the conceptual separation of skills (universal knowledge) / formulas (process) / rig config (project-specific) is a useful architectural frame. The model should survive even if the problem statement and recommendation sections need rewriting.

- **Option B's insight about skill command discovery (line 232) is valuable but untested.** The recommendation suggests skills should check CLAUDE.md as a fallback. This is a good idea but introduces non-deterministic behavior (LLM parsing CLAUDE.md for commands). The document correctly identifies this risk in the comparison matrix ("Low determinism"). If adopted, it should be a defined fallback order, not an open-ended discovery mechanism.

- **The research companion bead (ks-on7br) is better verified than this document.** The research doc was written after the design doc and explicitly corrects several claims. A reader should trust ks-on7br over ks-lzsrz where they conflict. The design doc should incorporate or defer to the research findings rather than contradicting them.

- **Options B and C may be more relevant than the document suggests, given the "LLM directions" reframing.** If Layer 3 is LLM directions rather than shell commands, then Option B (CLAUDE.md + skill discovery) becomes more natural — LLM directions in an LLM-native format. The document evaluates Option B purely as "shell commands in CLAUDE.md" which it correctly identifies as fragile. But "LLM directions in CLAUDE.md" is a different evaluation.

## Coverage

Sections reviewed: Executive Summary, Three-Layer Model, The Problem (Evidence), Options A/B/C, Comparison Matrix, Recommendation, Next Steps, Open Questions, Verified Assumptions

Lens questions applied:
- What's the strongest argument against this approach? → The approach was already implemented, making the document a post-hoc rationalization rather than a decision record
- What would a skeptic challenge? → The "evolve toward C" timeline is undefined; the "no work is wasted" migration claim is oversimplified
- Where is the reasoning weakest? → The problem statement (Layer 3 missing) is factually incorrect post-ks-4217r and post-ks-on7br research
- What assumptions are load-bearing? → That silent skip is acceptable (human says it's not); that `merge_queue.*_command` naming is adequate (human wants keeper-native naming)
- What breaks if key assumptions are wrong? → If Layer 3 is "LLM directions" not "shell commands," Options B/C evaluation criteria change significantly
