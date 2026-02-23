# Gas Town Built-in Formula Audit

Audit of `~/gt/.beads/formulas/` for keeper adoption candidates.

## Inventory

Gas Town ships 35 formulas. Excluding `mol-*` operational molecules and `towers-of-hanoi-*` demos, the **workflow formulas** evaluated are:

| Formula | Type | Description |
|---------|------|-------------|
| `shiny` | workflow | Design → Implement → Review → Test → Submit |
| `shiny-enterprise` | workflow | Shiny + rule-of-five expansion on implement |
| `shiny-secure` | workflow | Shiny + security-audit aspect |
| `security-audit` | aspect | Cross-cutting security scanning (before/after) |
| `rule-of-five` | expansion | 4-pass iterative refinement (draft → correctness → clarity → edge cases → excellence) |
| `design` | convoy | Parallel multi-analyst design exploration (6 legs + synthesis) |
| `code-review` | convoy | Parallel multi-reviewer code review (10 legs + synthesis, with presets) |
| `architecture` | workflow | Research → Options → Human Gate → Spec → Human Gate → Decompose → Verify |
| `standard-feature` | workflow | Implement → Test → Code Review Gate → Merge |
| `trivial` | workflow | Implement → Submit |
| `beads-release` | workflow | 15-step release orchestration for beads project |
| `gastown-release` | workflow | 14-step release orchestration for gastown project |

## Overlap with Keeper

Keeper currently has three formulas: `trivial`, `standard-feature`, `architecture`.

### trivial

**Verdict: No change needed.** Keeper's version is functionally identical to Gas Town's. Both define implement → submit with an `issue` variable. Minor wording differences only.

### standard-feature

**Verdict: No change needed.** Both define implement → test → review (human gate) → merge. Keeper's version references `skill:implementation`, `skill:testing`, `skill:code-review` which is a keeper-specific enhancement. Keep the keeper version.

### architecture

**Verdict: No change needed.** Both define the same 7-step flow with two human gates. Keeper's version has richer acceptance criteria and more detailed step descriptions. Keep the keeper version.

## New Formula Types Worth Adopting

Gas Town introduces three formula types keeper doesn't have: **aspect**, **expansion**, and **convoy**. These represent composable building blocks, not just standalone workflows.

### 1. security-audit (aspect) — RECOMMEND: Symlink

**What it does:** Injects pre/post security scanning around `implement` and `submit` steps. Uses AOP-style `advice` blocks with `before`/`after` weaving.

**Why adopt:** Cross-cutting concern applicable to any workflow. Keeper's `standard-feature` and `architecture` workflows could compose with it via `compose.aspects = ["security-audit"]`. No modification to existing formulas needed — just reference it.

**Adoption method:** Symlink from Gas Town. This formula has no project-specific content.

### 2. rule-of-five (expansion) — RECOMMEND: Symlink

**What it does:** Expands a single step into 5 sub-steps: draft → refine(correctness) → refine(clarity) → refine(edge cases) → refine(excellence). Based on the observation that LLM agents produce best work through iterative passes.

**Why adopt:** Applicable when a keeper-dispatched task needs higher-quality output (e.g., writing skills, specs, complex implementations). Compose via `compose.expand` targeting any step.

**Adoption method:** Symlink from Gas Town. Generic and reusable.

### 3. design (convoy) — DEFER

**What it does:** Spawns 6 parallel polecats (API, data, UX, scale, security, integration), each analyzing a design problem from one dimension. Synthesis step combines findings.

**Why defer:** Convoy execution requires multi-agent infrastructure (parallel polecat spawning, output collection, synthesis orchestration). Keeper doesn't currently dispatch convoy work. Adopt when keeper has convoy support.

### 4. code-review (convoy) — DEFER

**What it does:** Spawns up to 10 parallel reviewers (correctness, performance, security, elegance, resilience, style, smells, wiring, commit-discipline, test-quality). Includes presets for different review depths (gate, full, security-focused, refactor).

**Why defer:** Same infrastructure dependency as design convoy. The preset model is worth studying for future keeper formula configurability.

## New Workflow Candidates

### shiny — RECOMMEND: Fork

**What it does:** Design → Implement → Review → Test → Submit. The "canonical right way" with a mandatory design step before coding.

**Gap it fills:** Keeper has `trivial` (no design, no review) and `architecture` (heavyweight with human gates). Shiny fills the middle: design-first but no human gates. Good for well-scoped work where thinking before coding matters but human approval isn't needed.

**Adoption method:** Fork (copy into keeper formulas). Adapt step descriptions to reference keeper skills (`skill:implementation`, `skill:code-review`). This makes it consistent with keeper's existing formulas.

### shiny-enterprise, shiny-secure — DEFER

**What they do:** Extend shiny with rule-of-five and security-audit respectively, using `extends` and `compose`.

**Why defer:** Adopt these after adopting shiny + the underlying expansion/aspect formulas. They demonstrate the composition model but aren't independently useful.

### beads-release, gastown-release — DO NOT ADOPT

**Why:** Project-specific release workflows. Keeper is an operational system, not a software project with releases. If keeper ever needs a release workflow, create a keeper-specific one.

## Patterns to Learn From

### 1. Composition Model (`extends`, `compose`)

Gas Town formulas compose via:
- `extends = ["base-formula"]` — inherit steps from another formula
- `compose.aspects = ["security-audit"]` — weave cross-cutting concerns
- `compose.expand` with `target` and `with` — replace a step with an expansion

**Recommendation:** Keeper's formulas should use this model when creating variants. Instead of copy-pasting `standard-feature` to add security, compose: `extends = ["standard-feature"]` + `compose.aspects = ["security-audit"]`.

### 2. Formula Type System

Gas Town uses four types: `workflow`, `aspect`, `expansion`, `convoy`. Each has distinct semantics:
- **workflow**: Sequential steps with optional gates
- **aspect**: Cross-cutting advice woven into other formulas
- **expansion**: Step-level refinement template
- **convoy**: Parallel multi-agent execution with synthesis

**Recommendation:** Keeper should document this type system in conventions.md and design new formulas with it in mind.

### 3. Variable Conventions

Two substitution syntaxes appear:
- `{{var}}` — standard variable substitution in workflows
- `{target}` / `{target.id}` / `{step.id}` — expansion/aspect template references

**Recommendation:** Document both in conventions.md. They serve different purposes: `{{var}}` for user-provided values, `{target}` for formula-internal references.

### 4. Presets (from code-review)

Code-review defines named presets selecting subsets of legs:
```toml
[presets.gate]
legs = ["wiring", "security", "smells", "test-quality"]

[presets.full]
legs = ["correctness", "performance", "security", ...]
```

**Recommendation:** When keeper adopts convoy formulas, use presets to configure depth/scope.

## Summary of Recommendations

| Formula | Action | Method | Priority |
|---------|--------|--------|----------|
| `security-audit` | Adopt | Symlink | High — universally useful |
| `rule-of-five` | Adopt | Symlink | High — improves output quality |
| `shiny` | Adopt | Fork + adapt | Medium — fills workflow gap |
| `design` | Defer | — | Low — needs convoy infra |
| `code-review` | Defer | — | Low — needs convoy infra |
| `shiny-enterprise` | Defer | — | Low — depends on shiny + rule-of-five |
| `shiny-secure` | Defer | — | Low — depends on shiny + security-audit |
| `beads-release` | Skip | — | N/A — project-specific |
| `gastown-release` | Skip | — | N/A — project-specific |

### Immediate Actions

1. **Symlink** `security-audit.formula.toml` and `rule-of-five.formula.toml` into `keeper/formulas/`
2. **Fork** `shiny.formula.toml` into `keeper/formulas/`, adapting descriptions to reference keeper skills
3. **Update** `conventions.md` to document formula types (aspect, expansion, convoy) and composition model
4. **Update** `conventions.md` to document variable substitution conventions (`{{var}}` vs `{target}`)
