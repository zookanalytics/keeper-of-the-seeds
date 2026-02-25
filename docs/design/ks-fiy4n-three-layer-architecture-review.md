# Validation Review: Three-Layer Architecture Design Doc

**Bead:** ks-fiy4n | **Date:** 2026-02-24
**Document reviewed:** `docs/design/ks-lzsrz-three-layer-architecture.md`
**Reviewer:** polecat/rictus | **Model:** claude-opus-4-6

---

## Summary

Three review passes were applied: **feasibility**, **adversarial**, and **completeness**. The document reaches the correct bottom-line action (create `settings/config.json` for keeper), but the analysis framing overstates the problem and understates what Gas Town already provides. The adversarial review in particular found that the `ks-on7br` research (a dependency of this doc) contradicts several claims about "missing mechanisms."

**Overall assessment: NOT READY** — 6 BLOCKs, 10 CONCERNs, 13 NOTEs across all lenses.

The BLOCKs cluster around three themes:
1. **Factual errors about Gas Town infrastructure** — the doc says Layer 3 is "missing entirely" when the mechanism exists and is documented
2. **Unresolved open questions that block implementation** — config location, schema naming, and failure behavior are all unspecified
3. **Unincorporated feedback** — "LLM directions" reframing and "fail/warn not silent skip" are acknowledged but not applied

---

## Pass 1: Feasibility Review

**Lens:** Can this actually be built? What's the hardest part? What could go wrong?

### Gate Assessment

| Question | Verdict |
|----------|---------|
| Can this actually be built? | READY |
| Gas Town integration works as described? | READY |

**Hardest part:** The config file lives in the rig directory (`~/gt/keeper/settings/config.json`), not in the git repo. The doc conflates these two locations in several places. Getting the config location semantics right determines whether config is portable or local-only.

**What could go wrong:** (1) The `merge_queue` nesting implies merge-queue-only scope, but variables are used across the full `mol-polecat-work` lifecycle. (2) Without Go source access, the exact JSON schema accepted by the config reader cannot be verified from this workspace. (3) The session-start hook (ks-wr884) is listed as unblocked by Option A, but the connection between config.json and skill enforcement is not explained.

**Overall: READY** (with blocks below)

### BLOCK

- **End-to-End Trace (lines 46-56):** The function name `loadRigCommandVars()` in `sling_helpers.go` cannot be verified from this workspace. Binary string analysis shows `loadRigsConfig` and `*rig.RigConfig` types instead. The trace diagram may be inaccurate about the specific code path. The binary references both `config.json` and `settings/config.json` — the proposed config must go in whichever location the Go binary actually reads. **Resolution:** Verify config location with `gt rig settings show keeper` before implementation.

- **Config Location Ambiguity (lines 92-101, 236):** `settings/config.json` is a rig-level runtime file at `/home/zook/gt/keeper/settings/config.json`, not a file in the git repository. "Concrete Next Steps" say "Create `keeper/settings/config.json`" — which could mean either location. If rig-level, it's installation-specific and not version-controlled. **Resolution:** State explicitly whether this is (a) the rig-level file (local, not committed), or (b) a new file in the git repo that Gas Town discovers.

### CONCERN

- **Verified Assumptions Table (line 264):** States "`keeper/settings/` exists but is empty" — accurate for the rig-level directory. But the git repo has no `settings/` directory at all. The doc should be precise about which `keeper/settings/` it means.

- **`merge_queue` Naming (lines 95-101):** The Go binary's struct tag is `json:"merge_queue"` — compiled-in. The formula uses these variables for the entire polecat work lifecycle, not just merge. Renaming in Option C requires Go changes, recompilation, and re-deployment. **Suggestion:** If the Go code already accepts alternative keys, rename now while zero config files exist. Otherwise accept the debt explicitly.

- **"No Go Code Changes Needed" Claim (line 109):** Only true if the existing config reader already supports the exact proposed JSON schema. Without Go source, this cannot be independently confirmed. **Suggestion:** Create a test config file and run `gt sling --dry-run` to confirm.

- **Silent Skip Behavior:** The `mol-polecat-work` formula says "Empty commands mean 'not configured for this project' — skip silently." Changing to "warn" or "fail" requires formula text changes, contradicting "no formula changes needed." **Suggestion:** If silent skip is kept for Option A (with pre-dispatch warning hook instead), state this explicitly.

- **Unblock Claim for ks-wr884 (line 240):** Option A provides command variables, not skill enforcement. The connection between "config.json exists" and "session-start hook is unblocked" is not explained.

- **Layer 3 as "LLM Directions":** Prior feedback said entries are "LLM directions, not raw shell commands." But the proposed config still shows `"test_command": "bash tests/cook-all-formulas.sh && shellcheck hooks/**/*.sh"` — a raw shell command. **Suggestion:** Acknowledge that for Option A these are raw commands, and the "LLM directions" evolution happens in Option C.

### NOTE

- Prior art survey (lines 63-75) is thorough and the common-pattern conclusion is well-supported.
- 8 formulas claimed, 8 found (verified). 7 skills claimed, 7 found (verified, plus 1 standalone `handoff.md`).
- Option B hybrid suggestion (skill checks CLAUDE.md as fallback) would shift the testing skill from pure Layer 1 to a Layer 1+3 hybrid, partially undermining the clean separation.
- Option C's TOML-in-shell-hooks concern could be resolved by a Go helper command (e.g., `gt rig config get commands.test.default`).

---

## Pass 2: Adversarial Review

**Lens:** What's the strongest argument against this approach? Where is the reasoning weakest?

### Gate Assessment

| Question | Finding |
|----------|---------|
| Strongest argument against? | The doc inflates a data-population task into an architecture decision. The mechanism exists; only the config file is missing. |
| Where is reasoning weakest? | The "Option A now, evolve toward C" phased strategy for a problem that doesn't require phasing. |
| Weakest assumptions? | That `merge_queue` naming is "debt" (it's Gas Town's deliberate design); that "no work is wasted" in A-to-C migration (no forcing function exists). |
| What breaks first? | Once rigs populate config.json and it works, there is no forcing function for Option C. It becomes permanent backlog debt. |

**Overall: NOT READY**

### BLOCK

- **Problem Framing (Executive Summary, Layer 3 Current State):** The document states "Layer 3 (Rig Config): Missing entirely" and "a mechanism that doesn't exist." The `ks-on7br` research found the mechanism is fully implemented: `loadRigCommandVars()` in Go, `LoadRigSettings()` in `config/loader.go`, documented in `docs/reference.md`, with a CLI (`gt rig config`), and a property-layers design doc. The infrastructure is not missing; only keeper's config file is missing. This factual error pervades the entire document. **Resolution:** Rewrite to distinguish "missing mechanism" from "unpopulated config file." Incorporate `ks-on7br` findings.

- **Option C Justification:** Option C proposes replacing `settings/config.json` with `rig.toml` but never justifies why the existing JSON format is inadequate. Gas Town's `RigSettings` struct already has the fields Option C proposes, plus additional fields Option C doesn't cover (`on_conflict`, `retry_flaky_tests`, `poll_interval`, etc.). Option C would be a regression in capability. **Resolution:** Provide concrete evidence that `settings/config.json` is insufficient, or remove Option C from the recommendation.

- **"No Work Is Wasted" (Recommendation point 4):** Unsubstantiated. No migration tooling, no timeline, no trigger condition for when Option C activates. "When rig count grows" is unfalsifiable without thresholds. **Resolution:** Define concrete criteria for Option C, or drop the evolution path and recommend Option A as the terminal state.

### CONCERN

- **Comparison Matrix / Failure Mode row:** Lists Option A's failure as "Silent skip (empty command)" — but that's the pre-Option-A state. With config populated, the failure mode changes to standard "wrong command" or "command fails." This biases comparison toward Option C.

- **Schema Naming (Open Question 2):** `merge_queue` is where commands are actually consumed. The naming is descriptively accurate for its primary consumer. Renaming creates breaking changes across Go types, config files, and docs for an aesthetic preference.

- **Silent Skip Behavior (Open Question 3):** The `ks-on7br` research notes this is by-design in Gas Town. Changing it requires a Go code change, contradicting "no Go code changes needed."

- **Documentation Duplication (Next Step 2):** Gas Town already documents the schema in `docs/reference.md` and `docs/concepts/integration-branches.md`. Creating keeper-local schema docs is a duplicate source of truth.

- **Prior Art Survey omits Gas Town itself** — the most relevant prior art. Gas Town already has the three-layer separation. The survey makes it appear Gas Town lacks something it already has.

### NOTE

- The P1 (ks-58cnr: `go test ./...` on non-Go repo) was a formula-default bug (Layer 2), not a Layer 3 absence. Using it to motivate Layer 3 conflates two different problems.
- Option B is rejected for CLAUDE.md parsing unreliability, then re-introduced as a fallback in the Option A recommendation. This is contradictory.
- Effort estimate for Option A is "Hours" but if it's literally "create one JSON file," the effort is minutes.
- The "Option A now, Option C later" recommendation introduces a ghost standard that future contributors may attempt to implement prematurely.

---

## Pass 3: Completeness Review

**Lens:** Does it address every requirement? Are open questions resolved? Is anything missing for implementation?

### Gate Assessment

| Question | Verdict |
|----------|---------|
| Addresses every requirement? | NOT READY |
| Edge cases considered? | NOT READY |
| Open questions resolved? | NOT READY |
| Anything missing for implementation? | NOT READY |

**Overall: NOT READY**

### BLOCK

- **Open Questions Unresolved:** Five open questions are listed but none are resolved. Questions 1 (config location), 2 (schema naming), and 3 (silent skip behavior) directly affect implementation. An implementer cannot begin without knowing where the file goes, what keys to use, and what happens on missing config. **Resolution:** Each open question needs a stated recommendation with rationale. Questions 1-3 must have proposed defaults.

- **"LLM Directions" Feedback Not Incorporated:** The Layer 3 table (line 22), Option A config example (lines 92-101), and Option C `rig.toml` examples all show raw shell commands. If these are meant to be LLM directions (prose instructions the polecat interprets), the schema, examples, and mental model all need revision. **Resolution:** Clarify the semantic nature of Layer 3 values and update all examples accordingly, or document why the feedback was rejected.

- **Fail/Warn Behavior Not Committed:** The recommendation lists "pre-dispatch validation warning" (line 88) and next step 4 says "warn when rig has no config.json." But open question 3 is unresolved, prior feedback says "fail/warn not silent skip," and the comparison matrix still lists Option A's failure mode as "Silent skip." **Resolution:** Specify exact fail/warn behavior for (a) config.json missing entirely, and (b) specific command variable is empty string.

### CONCERN

- **Keeper-Native Naming:** Prior feedback requested keeper-native naming. The doc uses Gas Town infrastructure terminology throughout without addressing this concern. Open question 2 touches `merge_queue` naming narrowly but the broader question is not addressed.

- **`mol-polecat-work` Not Examinable:** The formula lives in Gas Town core (Go code), not in keeper. The doc references its variables as confirmed but the reviewer cannot independently verify variable names, their exact keys, or default behavior. **Suggestion:** Include the actual variable table in an appendix.

- **Dual Source of Truth (Next Step 3):** Adding a "Repository Commands" section to CLAUDE.md hybridizes Options A and B, introducing the dual-source risk that Option B's con column warns about. No conflict precedence is specified.

- **Migration Path Underspecified:** One-sentence sketch with no trigger condition, no automation, no cleanup plan. Should at minimum state the trigger condition and confirm Option A format is a strict subset of Option C.

- **Session-Start Hook Undefined:** Listed as unblocked by Option A but the mechanism is entirely undefined: what does "nudges skill invocation" mean? Does it inject text? Invoke a command? How does it read config.json?

### NOTE

- Verified assumption "Claude Code `.claude/commands/` shadowing in worktrees" remains unverified (line 271). Relevant if the Option B hybrid is included.
- Prior research sources are commit hashes, not files — cannot verify synthesis fidelity.
- Keeper formulas reference `/seed-testing` skill, not `{{test_command}}`. Option A's config only matters for `mol-polecat-work`, not keeper's own formulas. This distinction could be more explicit.
- Option A con "Schema additions require Go changes" is listed but the recommendation does not address whether current Go code supports arbitrary keys or only hard-coded names.

---

## Cross-Cutting Synthesis

### Theme 1: The Problem Is Smaller Than Presented

The doc frames a three-option architecture decision. The adversarial review found the actual problem is: "keeper hasn't created its `settings/config.json` file." Gas Town's infrastructure exists, is documented, and has active development. The document should be rescoped as "populating keeper's rig config" rather than "designing a three-layer architecture."

### Theme 2: Feedback Not Yet Incorporated

Three pieces of prior feedback are acknowledged but not applied:
- "LLM directions, not shell commands" — examples still show shell commands
- "Fail/warn, not silent skip" — behavior still unspecified
- "Keeper-native naming" — Gas Town terminology used throughout

### Theme 3: Option C Is Speculative Debt

Every review found the A-to-C evolution path unjustified. No trigger condition, no forcing function, no evidence the existing format is inadequate. Recommending "evolve toward C" introduces a ghost standard without accountability. The doc should either commit to Option C with a timeline or recommend Option A as terminal.

### Blocking Issues (Must Resolve)

| # | Issue | Lens |
|---|-------|------|
| 1 | "Layer 3 missing entirely" is factually incorrect — mechanism exists, file is unpopulated | adversarial |
| 2 | Config location ambiguity (rig-level vs git repo) | feasibility |
| 3 | Open questions 1-3 unresolved — blocks implementation | completeness |
| 4 | "LLM directions" feedback not incorporated | completeness |
| 5 | Fail/warn behavior not committed | completeness |
| 6 | Option C unjustified — no evidence existing format is inadequate | adversarial |

### Recommended Path Forward

1. **Incorporate `ks-on7br` research findings** — correct the factual claims about missing infrastructure
2. **Resolve open questions 1-3** with proposed defaults (can be human-overridden)
3. **Apply the three feedback items** — LLM directions reframing, fail/warn behavior, keeper-native naming
4. **Decide on Option C** — either commit with a trigger condition or drop the evolution path
5. **Rescope the document** — from "architecture decision" to "populating keeper's rig config within Gas Town's existing infrastructure"

After these revisions, the doc should pass a second validation review without difficulty.
