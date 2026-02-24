# Formula Authoring Guide

Reference for agents writing or modifying keeper formulas. Covers Gas Town formula primitives, keeper conventions, and the full lifecycle from TOML authoring to molecule execution.

## Formula Types

Gas Town supports four formula types. Choose based on the work's execution model:

| Type | Execution Model | When to Use |
|------|----------------|-------------|
| **workflow** | Sequential steps with `needs` dependencies | Most work: features, architecture, investigations |
| **convoy** | Parallel legs dispatched to separate polecats | Multi-angle review, parallel analysis |
| **aspect** | Cross-cutting advice woven into other formulas | Test-first (TEA), security audit overlays |
| **expansion** | Step-level refinement template | Breaking one step into sequential sub-steps |

### Workflow

The most common type. Steps execute sequentially based on `needs` dependencies, forming a DAG. Each step has a single executor (polecat).

```toml
formula = "my-workflow"
type = "workflow"
version = 1

[[steps]]
id = "research"
title = "Research {{topic}}"
description = "Investigate the problem space."
checklist = "research-complete"

[[steps]]
id = "implement"
title = "Implement {{topic}}"
needs = ["research"]
description = "Write the code per /implementation."
checklist = "impl-ready"
```

Key properties:
- `id` -- unique identifier within the formula, referenced by `needs`
- `title` -- display name, supports `{{variable}}` substitution
- `needs` -- array of step IDs that must complete before this step starts
- `description` -- instructions for the polecat executing the step
- `checklist` -- references a file in `checklists/<name>.md` (definition of done)
- `gate` -- optional human gate: `gate = { type = "human" }`

### Convoy

Parallel legs dispatched to separate polecats. Each leg works independently on the same artifact from a different angle. An optional synthesis step combines outputs.

```toml
formula = "my-review"
type = "workflow"  # NOTE: use "workflow" until bd adds convoy as valid type
version = 1

[[legs]]
id = "feasibility"
title = "Feasibility Review"
focus = "Technical viability and implementation risk"
agent = "claude"  # Optional: model backend override
description = """Review through a feasibility lens..."""

[[legs]]
id = "adversarial"
title = "Adversarial Review"
focus = "Red-team / devil's advocate challenge"
agent = "gemini"
description = """Review through an adversarial lens..."""

[synthesis]
title = "Review Synthesis"
description = """Combine all lens reviews into unified findings..."""
depends_on = ["feasibility", "adversarial"]
```

Leg properties:
- `id` -- unique identifier for the leg
- `title` -- display name
- `focus` -- what angle this leg concentrates on
- `description` -- instructions for the assigned polecat
- `agent` -- optional model backend override (used by multi-model presets)

Convoy formulas also support `[presets]` for configurable leg selection and `[output]` for directory/file patterns. See `document-review.formula.toml` for a complete example.

### Aspect

Cross-cutting advice that weaves into other formulas via `compose.aspects`. Aspects inject `before` and `after` steps around target steps without modifying the base formula.

```toml
formula = "tea"
type = "aspect"
version = 1

[[advice]]
target = "implement"
[advice.around]

[[advice.around.before]]
id = "{step.id}-acceptance-tests"
title = "Write failing acceptance tests before {step.id}"
description = "Extract acceptance criteria, write tests that MUST fail..."
checklist = "acceptance-tests-written"

[[pointcuts]]
glob = "implement"
```

Aspect-specific properties:
- `target` -- which step ID to advise (matched via pointcuts)
- `advice.around.before` / `advice.around.after` -- steps injected before/after the target
- `pointcuts` -- glob patterns matching step IDs this aspect applies to

Note the `{step.id}` syntax (single braces) for formula-internal references, distinct from `{{variable}}` for user-provided values.

### Expansion

Replaces a single step with multiple sequential sub-steps. Used via `compose.expand` in a parent formula.

```toml
[[compose.expand]]
target = "implement"
with = "rule-of-five"
```

## Variable System

### Defining Variables

Variables are defined in the `[vars]` section. Each variable can be a shorthand string (treated as default) or a full table:

```toml
[vars]
[vars.feature]
description = "The feature being implemented"
required = true

[vars.base_branch]
description = "Branch to rebase on"
default = "main"

[vars.assignee]
description = "Who is assigned to this work"
```

### Two Substitution Syntaxes

| Syntax | Purpose | Example |
|--------|---------|---------|
| `{{variable}}` | User-provided values at pour time | `{{issue}}`, `{{feature}}`, `{{base_branch}}` |
| `{target}` / `{step.id}` | Formula-internal references in aspects/expansions | `{step.id}-acceptance-tests` |

Variables are injected into step `title` and `description` fields. At pour time, `bd mol pour` substitutes `{{variable}}` with values from `--var` flags or defaults.

### Available Variables from `mol-polecat-work`

These variables flow from rig config into the polecat work molecule. Empty values mean "not configured -- skip":

| Variable | Source | Description |
|----------|--------|-------------|
| `issue` | hook bead | The assigned issue ID |
| `base_branch` | sling vars | Branch to rebase on (default: `main`) |
| `setup_command` | rig config | Install/setup (e.g., `pnpm install`) |
| `typecheck_command` | rig config | Type checking (e.g., `tsc --noEmit`) |
| `lint_command` | rig config | Linting (e.g., `eslint .`) |
| `test_command` | rig config | Test execution |
| `build_command` | rig config | Build (e.g., `go build ./...`) |

Only these 7 variables are available from the Gas Town runtime. Anything outside this set must be handled by the agent at runtime.

## Formula Composition

### Extends

Inherit steps from a base formula:

```toml
extends = ["base-formula"]
```

### Compose with Aspects

Weave cross-cutting concerns into a workflow:

```toml
[compose]
aspects = ["tea", "security-audit"]
```

### Compose with Expand

Replace a step with an expansion (sequential sub-steps) or convoy (parallel legs + synthesis):

```toml
[[compose.expand]]
target = "implement"
with = "rule-of-five"

[[compose.expand]]
target = "dispatch-reviews"
with = "document-review"
```

Prefer composition over copy-paste when creating formula variants.

## Formula Resolution

Gas Town resolves formulas using three-tier precedence (most specific wins):

| Tier | Location | Source | Use Case |
|------|----------|--------|----------|
| 1. **Project** | `<project>/.beads/formulas/` | Committed to repo | Project-specific workflows |
| 2. **Town** | `~/gt/.beads/formulas/` | User customizations, Mol Mall installs | Cross-project workflows |
| 3. **System** | Embedded in `gt` binary | `internal/formula/formulas/` at build time | Defaults, fallback |

**Keeper formulas live at Tier 1** -- they are committed to the keeper repo in `formulas/`. When a polecat in the keeper rig runs `bd cook`, it finds keeper formulas first.

The resolution algorithm walks up from cwd to find project-level `.beads/formulas/`, then checks town-level, then falls back to embedded system formulas.

## Execution Lifecycle

```
Formula (source TOML in formulas/)
    |
    v  bd cook <formula> [--var key=value ...]
Protomolecule (frozen template with variables substituted)
    |
    +---> bd mol pour <proto>  -->  Molecule (persistent, synced via Dolt)
    |                                   |
    |                                   v  execute steps via bd mol current / bd close <step>
    |                                   |
    |                                   v  bd mol squash
    |                                   Digest (compressed summary)
    |
    +---> bd mol wisp <proto>  -->  Wisp (ephemeral, never synced)
                                        |
                                        v  execute steps
                                        +---> bd mol squash --> Digest
                                        +---> bd burn --> (deleted)
```

**Molecules** are for work requiring an audit trail (feature implementation, architecture decisions). Steps become real beads that persist in `.beads/`.

**Wisps** are for ephemeral operational cycles (patrol, inbox hygiene). They are never synced to git.

### Step Execution

1. `bd mol current` -- find the next ready step (all `needs` satisfied)
2. `bd update <step-id> --status in_progress` -- claim the step
3. Execute the work described in the step
4. `bd close <step-id>` -- mark the step complete
5. Repeat until all steps are done
6. `gt done` -- submit branch to merge queue

## Checklists (Definition of Done)

Every formula step should reference an external checklist instead of inline acceptance criteria. Checklists live in `checklists/<name>.md`.

### Referencing a Checklist

```toml
[[steps]]
id = "implement"
title = "Implement {{feature}}"
description = "..."
checklist = "impl-ready"
```

The polecat reads `checklists/impl-ready.md` and evaluates each criterion before closing the step.

### Checklist Format

```markdown
# Checklist Title

Definition of Done for [what this covers].

## Gate Criteria

- Criterion one: READY / NOT READY
- Criterion two: READY / NOT READY
```

Every criterion is binary: READY or NOT READY. No qualitative scoring.

### Available Checklists

| Checklist | Used By |
|-----------|---------|
| `research-complete` | architecture, consult, design-pipeline research steps |
| `options-documented` | architecture/options, consult/propose |
| `human-gate-passed` | All human gate steps |
| `impl-ready` | standard-feature, trivial, shiny implement steps |
| `tests-pass` | standard-feature/test |
| `review-complete` | standard-feature, shiny review steps |
| `merge-ready` | standard-feature, trivial, shiny submit/merge steps |
| `design-drafted` | design-pipeline, shiny design steps |
| `review-convoy-complete` | design-pipeline convoy dispatch |
| `design-finalized` | design-pipeline finalize |
| `spec-complete` | architecture/spec |
| `decomposition-complete` | architecture/decompose |
| `verification-complete` | architecture/verify |
| `retro-complete` | architecture, design-pipeline retro steps |
| `consult-delivered` | consult/deliver |
| `acceptance-tests-written` | TEA aspect: before implement |
| `acceptance-traceability-verified` | TEA aspect: after test |

## Skill References

Formula steps reference skills using slash notation. This is agent-runtime-agnostic -- each runtime (Claude, Gemini, Codex) resolves through its own path.

```toml
[[steps]]
id = "implement"
description = "Implement per /implementation. Keep changes focused."
```

When a step says "per /implementation", the polecat invokes the `/implementation` skill which resolves to `skills/implementation.md` (the canonical source).

Use explicit requirement markers in step descriptions:
- `per /testing` -- invoke this skill for the step
- `**REQUIRED:** Invoke /code-review` -- mandatory skill invocation

## Human Gates

Steps can declare a human gate, which blocks polecat execution until a human approves:

```toml
[[steps]]
id = "direction"
title = "Human direction on {{topic}}"
description = "HUMAN GATE. Escalate with options. Do NOT proceed until human selects."
checklist = "human-gate-passed"
gate = { type = "human" }
```

When a polecat hits a human gate, it escalates (via mail or `gt escalate`) and exits with ESCALATED status. The human reviews, and a fresh polecat is spawned to continue from the next step.

## Merge Strategy

Formulas can declare their expected merge strategy. The dispatcher applies it at sling time:

| Strategy | Flag | When |
|----------|------|------|
| `mr` (default) | (none) | Standard work -- enters merge queue |
| `no-merge` | `--no-merge` | Work needing review -- branch persists |
| `direct` | `--merge direct` | Urgent fixes -- pushes directly to main (rare) |

**Convention:** Consult and architecture formulas use `--no-merge`. Standard-feature and trivial may use default (`mr`).

## Triage Level to Formula Mapping

| Triage | Formula | Merge Strategy |
|--------|---------|----------------|
| `auto` | `trivial` | mr |
| `review` | `standard-feature` | mr or --no-merge |
| `consult` | `consult` | --no-merge |
| `plan` | `architecture` | --no-merge |

## Keeper Formula Inventory

| Formula | Type | Steps | Purpose |
|---------|------|-------|---------|
| `trivial` | workflow | 2 | Obvious fixes, config changes, typos |
| `standard-feature` | workflow | 5 | Well-scoped features with review gate |
| `shiny` | workflow | 6 | Design-first features (design before code) |
| `consult` | workflow | 3 | Investigation producing design document |
| `architecture` | workflow | 9 | Architecture decisions with multiple human gates |
| `design-pipeline` | workflow | 7 | Multi-phase design with review convoy |
| `document-review` | convoy | 11 legs | Parallel multi-lens document review |
| `tea` | aspect | 2 advice | Test-first (ATDD) cross-cutting concern |

## Authoring Conventions

### Naming

- Filename: `<name>.formula.toml` (kebab-case)
- The `formula` field value must match the filename (without extension)
- Examples: `standard-feature.formula.toml`, `architecture.formula.toml`

### Step Descriptions

- Start with what the polecat should do, not background context
- Reference skills with `/skill-name` notation
- End with clear exit criteria or reference a checklist
- Keep descriptions actionable -- the polecat executes, it doesn't deliberate

### Human Gates

- Description must start with `HUMAN GATE.`
- Include what to present to the human
- Include `gate = { type = "human" }` on the step
- Reference `human-gate-passed` checklist

### Retro Steps

Architecture and design-pipeline formulas include retro + retro-human gate pairs. The retro step produces findings; the retro-human gate prevents agents from acting on their own findings without human review. Include the standard rationalization warning in both steps.

### Commit Message Scoping

When committing formula changes, scope to the pillar:

```
feat(formulas): add architecture-decision workflow
fix(formulas): strengthen human gate descriptions
```

## Known Limitations

- Only 7 command variables are available from `mol-polecat-work` (`issue`, `base_branch`, `setup_command`, `typecheck_command`, `lint_command`, `test_command`, `build_command`). Anything outside these must be handled by the agent at runtime.
- Convoy type is not yet a valid `type` value in `bd` -- convoy formulas use `type = "workflow"` with `[[legs]]` structure until support lands.
- Aspects and expansions require the host formula to use `compose.aspects` or `compose.expand` -- they don't auto-attach.

## Gas Town Source References

For deeper understanding of the formula engine:

| File | What It Contains |
|------|-----------------|
| `gastown/docs/formula-resolution.md` | Three-tier resolution architecture |
| `gastown/docs/concepts/molecules.md` | Molecule lifecycle and concepts |
| `gastown/internal/formula/types.go` | Core types: `Formula`, `Step`, `Leg`, `Var`, `Synthesis` |
| `gastown/internal/formula/parser.go` | TOML parsing, validation, cycle detection, ready-step computation |
| `gastown/internal/formula/formulas/` | System-level formula definitions (embedded in binary) |
| `gastown/internal/cmd/formula.go` | CLI: `gt formula list/show/run/create` |

## Maintenance

Update this document when:
- Gas Town adds new formula features or variables
- New formula types or composition mechanisms are added
- Keeper adds new formulas or checklists
- The variable injection system changes

Cross-reference with `docs/conventions.md` for formatting and naming rules.
