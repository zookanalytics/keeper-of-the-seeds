# Keeper of the Seeds

The operational system definition for AI-assisted software development with [Gas Town](https://github.com/zookanalytics/gastown). This repo defines *how work gets done* — workflow templates, execution knowledge, and enforcement mechanisms — across all projects and agent sessions.

This is not a project codebase. Project rigs contain the software being built. Keeper contains the institutional knowledge that compounds across every project.

## The Three Pillars

### Formulas — What happens and when

TOML workflow templates that compile into Gas Town molecules via `bd cook`. Each formula defines steps, dependencies, human gates, and variable slots for a specific type of work.

| Formula | Use case |
|---------|----------|
| `trivial` | Config changes, typo fixes, obvious one-step work |
| `standard-feature` | Well-scoped features with implementation, test, and review |
| `shiny` | Design-first features (design → review → implement → test) |
| `architecture` | Decisions with lasting consequences; multiple human gates |
| `consult` | Investigation work — output is a design doc, not code |
| `design-pipeline` | Multi-phase design with parallel review convoy |
| `document-review` | Parallel multi-lens review (8 aspects run concurrently) |

### Skills — How to do each thing well

Markdown execution guides that teach agents specific activities. Each skill includes activation conditions, step-by-step approach, red flags, anti-rationalization patterns, and concrete examples.

| Skill | Core principle |
|-------|---------------|
| `implementation` | Do exactly what the spec says — no more, no less |
| `code-review` | Review the change against the spec, not how you'd write it |
| `testing` | Cover the behaviors described in the spec |
| `research` | Understand the territory before drawing the map |
| `document-review` | Review through a declared lens, not a general "looks good" |

### Hooks — Enforcement that both are followed

Enforcement mechanisms that fire at specific points in the Gas Town lifecycle. Hooks make formulas and skills load-bearing rather than advisory:

- **Pre-dispatch** — Reject beads without workflow classification or triage level
- **Post-completion** — File `ks` beads for actionable observations (failures, misclassifications, anomalies)
- **Pre-merge** — Enforce human approval gates and required artifacts

## Directory Structure

```
keeper/
├── formulas/          # TOML workflow templates
├── skills/            # Markdown execution guides
├── checklists/        # Binary READY/NOT READY Definition of Done per step
├── tests/             # Skill validation scenarios and CI scripts
│   └── scenarios/     # Red/green/adversarial test cases per skill
├── docs/              # Deep reference documentation
│   ├── brief.md       # Full product brief (start here for deep detail)
│   ├── conventions.md # Naming, format, and structure rules
│   ├── validation.md  # Skill validation methodology
│   └── designs/       # Design artifacts from active beads
└── .beads/            # Keeper rig backlog (prefix: ks)
```

## Gas Town Integration

Keeper is mounted as a Gas Town rig (short name: `keeper`, prefix: `ks`). Any project rig can file improvement beads against it using the `ks` prefix.

**Skill resolution:** Formula steps reference `skill:<name>`, which agents resolve to `~/gt/keeper/skills/<name>.md`.

**Triage levels** determine human involvement for each bead:

| Level | Gate | Use when |
|-------|------|----------|
| `auto` | CI only | Config, typos, documentation |
| `review` | Human approval | New features, multi-file refactors |
| `consult` | Agent escalates with options | API surfaces, auth, data models |
| `plan` | Human provides direction first | Architecture, new subsystems, breaking changes |

**Retro through beads:** Post-completion hooks file `ks` beads for actionable observations. When the same pattern recurs, hooks link to the existing issue — link count is the frequency signal. No dashboards or separate pipeline; the improvement system runs on its own primitives.

## Skill Validation

Skills are validated before deployment using methodology adapted from [obra/superpowers](https://github.com/obra/superpowers):

1. **Red test** — Observe failure without the skill (baseline)
2. **Green test** — Verify the skill corrects the failure
3. **Adversarial test** — Apply pressure to provoke rationalization
4. **Regression test** — Ensure updates don't break correct behavior

See `docs/validation.md` for the full methodology and `tests/scenarios/` for existing test cases.

## Quick Reference

```bash
# Cook a formula (dry-run validation)
bd cook formulas/standard-feature.formula.toml --dry-run

# Pour a molecule from a formula
bd mol pour <formula> --var FEATURE="auth"

# File a bead against keeper
bd create --rig keeper --title "Skill gap: ..." --type task

# Run CI checks locally
bash tests/cook-all-formulas.sh
```

## License

[MIT](LICENSE)
