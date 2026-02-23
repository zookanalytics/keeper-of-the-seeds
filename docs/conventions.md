# Conventions

## Formula Naming

- Filename: `<name>.formula.toml` (kebab-case)
- Examples: `standard-feature.formula.toml`, `architecture-decision.formula.toml`
- The name is the identifier used in triage classification and retro data

## Skill Naming

- Filename: `<name>.md` (kebab-case)
- Examples: `code-review.md`, `spec-writing.md`
- Formula steps reference skills as `skill:<name>` (without extension)

## Hook Naming

- Filename: descriptive of what it enforces (kebab-case)
- Must be executable (`chmod +x`)
- Exit 0 = pass, non-zero = reject/fail
- Hooks should write to stderr for rejection reasons

## Retro Beads

Post-completion hooks file `ks` beads for actionable observations. No separate log file.

When filing a retro bead:
- Check for existing `ks` issues describing the same pattern
- If found: link to the existing issue instead of creating a duplicate
- If new: create the issue with enough context to act on (what happened, which skill/formula was involved, what went wrong)

Frequency = number of linked beads on an issue. High-frequency issues get priority in retro review.

## Test Scenario Format

Each scenario is a markdown file in `tests/scenarios/<skill-name>/`:

```markdown
# Scenario: <descriptive name>

## Setup
What context the agent has. What files exist. What the bead says.

## Input
The prompt or task given to the agent.

## Expected (with skill)
What the agent should do.

## Expected (without skill)
What the agent typically does wrong — the red test baseline.
```

## Commit Messages

Follow conventional commits scoped to the pillar:

- `feat(formulas): add architecture-decision workflow`
- `fix(skills): strengthen code-review rationalization counters`
- `feat(hooks): add pre-dispatch classification validator`
- `test(skills): red/green scenarios for implementation skill`
- `docs: update validation methodology`

