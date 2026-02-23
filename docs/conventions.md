# Conventions

## Formula Naming

- Filename: `<name>.formula.toml` (kebab-case)
- Examples: `standard-feature.formula.toml`, `architecture-decision.formula.toml`
- The name is the identifier used in triage classification and retro data

### Formula Types

Gas Town supports four formula types with distinct semantics:

| Type | Purpose | Example |
|------|---------|---------|
| **workflow** | Sequential steps with optional gates | `standard-feature`, `architecture` |
| **aspect** | Cross-cutting advice woven into other formulas | `security-audit` |
| **expansion** | Step-level refinement template | `rule-of-five` |
| **convoy** | Parallel multi-agent execution with synthesis | `design`, `code-review` |

### Composition Model

Formulas compose via:
- `extends = ["base-formula"]` — inherit steps
- `compose.aspects = ["security-audit"]` — weave cross-cutting concerns
- `compose.expand` with `target` and `with` — replace a step with an expansion

Prefer composition over copy-paste when creating formula variants.

### Variable Substitution

Two syntaxes serve different purposes:
- `{{var}}` — user-provided values at pour time (e.g., `{{issue}}`, `{{feature}}`)
- `{target}` / `{target.id}` / `{step.id}` — formula-internal references in aspects and expansions

## Skill Naming

- Filename: `<name>.md` (kebab-case)
- Examples: `code-review.md`, `spec-writing.md`
- Formula steps reference skills as `skill:<name>` (without extension)
- Use active voice, verb-first when naming: `code-review` not `review-of-code`

### Skill Frontmatter

Every skill file should have YAML frontmatter with exactly two fields:

```yaml
---
name: skill-name
description: Use when [triggering conditions and symptoms only]
---
```

- `name`: letters, numbers, hyphens only. Must match the filename (without `.md`).
- `description`: third person, starts with "Use when...", max ~500 characters.

**CSO trap warning:** The `description` must list only triggering conditions — never summarize the skill's workflow or process. When a description summarizes workflow, agents may follow the summary instead of reading the full skill body. Describe the *problem* or *situation*, not the *solution*.

```yaml
# BAD: summarizes workflow — agent follows this instead of reading skill
description: Use for code review — check correctness, security, then classify as BLOCK/SHOULD/NIT

# GOOD: triggering conditions only
description: Use when reviewing code changes before merge, when self-reviewing before submission
```

### Skill Document Structure

```markdown
---
name: skill-name
description: Use when [triggering conditions]
---

# Skill Name

## Overview
What is this? Core principle in 1-2 strong sentences.

## When to Use
- Specific situations and symptoms
- **When NOT to use:** [explicit negation]

## How to Execute
Step-by-step approach with decision points.

## Red Flags
- Signs the agent is going off track

## Common Rationalizations (discipline skills only)
| Excuse | Reality |
|--------|---------|
| "[exact observed rationalization]" | [direct counter] |

## Examples
Concrete before/after showing what the skill produces vs without it.
```

### Skill Types

Classify each skill to determine appropriate testing strategy (see `docs/validation.md`):

| Type | Characteristics | Testing |
|------|----------------|---------|
| **Discipline** | Enforces rules, has compliance cost | Pressure scenarios, rationalization tables |
| **Technique** | How-to guide, step-by-step process | Application + variation scenarios |
| **Pattern** | Mental model, design principle | Recognition + counter-example tests |
| **Reference** | API docs, syntax guides, lookup tables | Retrieval + application tests |

### Anti-Rationalization Patterns

For discipline-enforcing skills, use these patterns (from obra/superpowers methodology):

**Iron Law** — state the non-negotiable rule prominently:
```markdown
## The Iron Law
NO [VIOLATION] WITHOUT [PREREQUISITE] FIRST
```

**Rationalization Table** — build incrementally from observed failures:
```markdown
| Excuse | Reality |
|--------|---------|
| "[exact wording from testing]" | [direct counter] |
```

**Explicit Negation** — don't just state the rule, forbid specific workarounds:
```markdown
Don't skip review.
- Not for "small changes"
- Not because "I already checked manually"
- Not because "this case is different"
```

**Red Flags list** — self-check for agents recognizing rationalization:
```markdown
## Red Flags — STOP
- [symptom of about-to-violate]
- "This is different because..."
**All of these mean: [corrective action].**
```

Only add rationalizations observed during actual testing, not hypothetical ones.

### Cross-Referencing Skills

Use explicit requirement markers:
- `**REQUIRED:** Follow skill:testing for test execution`
- `**BACKGROUND:** Read skill:code-review first`

Do not use bare `skill:<name>` references without indicating whether the skill is required or optional context.

### Token Budget

Keep skills concise. Agent context is finite:
- Always-loaded skills (if any): <200 words
- On-demand skills: aim for <500 words in core sections
- Heavy reference material: separate file, loaded only when needed

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

For discipline-enforcing skills, add a pressure scenario variant:

```markdown
# Pressure Scenario: <descriptive name>

## Pressures Applied
- [pressure type 1]: [detail]
- [pressure type 2]: [detail]
- [pressure type 3]: [detail]

## Scenario
[Concrete situation forcing A/B/C choice]

## Expected Choice
[Which option and why]

## Observed Rationalizations (from RED test)
- "[verbatim excuse 1]"
- "[verbatim excuse 2]"
```

## Commit Messages

Follow conventional commits scoped to the pillar:

- `feat(formulas): add architecture-decision workflow`
- `fix(skills): strengthen code-review rationalization counters`
- `feat(hooks): add pre-dispatch classification validator`
- `test(skills): red/green scenarios for implementation skill`
- `docs: update validation methodology`
