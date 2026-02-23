## Review: Retrospective Checkpoints for Continuous Learning
Lens: feasibility
Reviewer: keeper/polecats/nux

### Summary

The design is directionally sound and the layered approach is correct, but the recommended starting point (Layer 1, post-completion hook) has a critical blocker: the hook API contract doesn't exist. The design itself flags this as an open question, then recommends building Layer 1 first anyway. Layer 3 (explicit formula steps) is actually the most immediately buildable component and should be the real starting point.

---

### BLOCK

**[Assumptions / Options / Implementation Sketch] Hook API is undefined — Layer 1 cannot be built yet**

The design recommends "Layer 1 first" because it's the "cheapest, broadest coverage." But `hooks/post-completion/` is an empty directory with no shim, stub, or API contract. Open Question #1 in the design itself asks: "What's the hook API? How does post-completion receive bead context?" — this isn't a detail to resolve during implementation, it's the gating question for Layer 1.

Concrete gap: the implementation sketch proposes the hook calls `bd mol status`, but:
- The actual command is `bd mol current`, not `bd mol status` (verified against live system)
- Whether `bd` is even on `PATH` inside a hook, whether the hook runs as a subprocess with bead context injected as args or env vars, and whether `bd` commands work without a working directory that has `.beads/` — none of this is specified anywhere

The hook directory exists because the concept was designed. The API was not designed with it.

**Resolution**: Before committing to Layer 1 as the starting point, the hook API must be spec'd: what arguments does `hooks/post-completion/<script>.sh` receive? What environment variables? Can it invoke `bd` commands? If this can't be answered from gt source in a short spike, flip the implementation order — start with Layer 3.

---

**[Implementation Sketch / Option B] Layer 2 aspect injection syntax doesn't match reality**

The sketch proposes:
```toml
[[steps]]
id = "retro-analysis"
after = "{last_step}"  # aspect injection point
```

But actual aspect formulas in the Gas Town formula library use `[[advice]]` blocks with `[advice.around]` sections and `[[pointcuts]]` glob patterns (from `security-audit.formula.toml`). The `after = "{last_step}"` syntax does not appear in any implemented aspect formula.

Additionally, keeper's formulas have never used `compose.aspects = [...]`. The syntax exists in Gas Town's formula library (`shiny-secure.formula.toml`) but has not been validated against keeper's formula structure. The test suite (`tests/cook-all-formulas.sh`) only tests `--dry-run` on keeper's five formulas, none of which use composition.

**Resolution**: Before the Layer 2 design section is finalized, a spike test is needed: create a minimal retro aspect formula using the real `[[advice]]`/`[[pointcuts]]` syntax and verify `bd cook` handles it correctly against a keeper formula. Without this, the Layer 2 sketch is speculative.

---

### CONCERN

**[Options / Recommendation] Recommended deployment order inverts feasibility**

The design recommends: Layer 1 → Layer 2 → Layer 3. But feasibility runs the other direction:

| Layer | Component | Feasibility | Blocker |
|-------|-----------|-------------|---------|
| 1 | Post-completion hook | Low | Hook API undefined |
| 2 | Retro aspect formula | Medium | Aspect composition untested in keeper |
| 3 | Human retro gate (explicit step) | High | None — adding steps to TOML formulas is proven and tested |

Layer 3 — adding a `[[steps]]` entry with `gate = { type = "human" }` to specific formulas — uses only primitives that are already demonstrated working in keeper's formula set. It would deliver immediate, low-risk value in design-pipeline and architecture workflows.

The design's argument for Layer 1 first ("requires no formula changes, covers all workflows automatically") is a product argument, not a feasibility argument. For a first implementation, Layer 3's certainty outweighs Layer 1's coverage.

**Resolution**: Consider restructuring the deployment order as Layer 3 → Layer 1 (after hook API is resolved) → Layer 2 (after aspect composition is validated). The section should acknowledge this trade-off explicitly.

---

**[Assumptions] "AI retros can produce useful findings without human guidance" remains unverified with no test plan**

The design correctly marks this assumption as "unverified." But it's load-bearing for Layer 2 (the AI retro aspect), and there's no proposed way to test it short of running it. The risk isn't just low-signal output — it's that a low-signal AI retro step, running automatically after every workflow, creates retro fatigue: polecats learn to ignore ks beads because too many are noise.

**Resolution**: Add a testing approach for this assumption — e.g., retrospectively apply the proposed AI analysis to 3-5 completed bead histories and evaluate output quality before building the automation.

---

### NOTE

**[Open Questions] Cross-rig ks bead filing is confirmed, not just plausible**

The design marks "Polecats can file ks beads from any rig" as "confirmed," which is correct. `routes.jsonl` maps `ks-` prefix to the keeper rig and the routing infrastructure is in place. The design's confidence level here is appropriately set.

---

**[Open Questions] "Linked-bead frequency is queryable" needs a quick API check**

The design marks this "plausible." Given that cross-rig routing works, a `bd` command to count beads linked to a specific issue is likely, but worth confirming with `bd help` or a quick test before designing the threshold logic around it.

---

**[Meta section] The "formula doesn't say where to commit the document" observation is a real gap**

The meta section notes that design-pipeline has no artifact path convention. This is worth filing as a separate ks bead against design-pipeline formula — the observation is correct and actionable, but it's not blocking the retro checkpoints design itself.

---

**[Option C / Layer 3] The two-flavor explicit step design is the cleanest primitive**

The distinction between AI retro step (automatic, filed as bead) and Human retro step (gate, human-reviewed summary) is the right abstraction. These map cleanly to existing formula primitives (`skill:` steps vs `gate = { type = "human" }`). This section is the most implementation-ready piece of the design.

---

### Coverage

Sections reviewed: Problem Statement, Constraints, Findings (What Exists / What's Missing), Assumptions, Options A–D, Recommendation, Implementation Sketch, Open Questions, Meta section

Lens questions applied:
- *Can this actually be built?* — Yes, partially. Layer 3 is buildable now. Layer 1 is blocked on hook API. Layer 2 needs a composition spike.
- *What's the hardest part?* — Defining and implementing the hook API. Everything else has a clear path.
- *What could go wrong during implementation?* — Hook API doesn't work as assumed; aspect composition doesn't generalize to keeper's formula structure; AI retro produces low-signal output causing retro fatigue.
- *What infrastructure exists vs. is assumed to exist?* — Hook directories exist, hook API does not. Aspect composition syntax exists in Gas Town formulas, untested in keeper. Cross-rig routing is fully implemented.
