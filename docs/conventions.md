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

## Merge Strategy

Formulas can declare their expected merge strategy. The dispatcher (mayor) applies it at sling time via the --merge flag:

| Strategy | Flag | When |
|----------|------|------|
| mr (default) | (none) | Standard work — enters merge queue, refinery merges |
| no-merge | --no-merge | Work needing review — branch persists after gt done |
| direct | --merge direct | Urgent fixes — pushes directly to main (rare) |

**Convention:** Consult and architecture work SHOULD use --no-merge. Standard-feature and trivial MAY use default (mr) or --no-merge depending on the rig's review requirements.

## Triage Level → Formula Mapping

| Triage | Formula | Merge Strategy |
|--------|---------|----------------|
| auto | trivial | mr |
| review | standard-feature | mr or --no-merge (rig-dependent) |
| consult | consult | --no-merge |
| plan | architecture | --no-merge |

## Consult Bead Description Template

When creating a consult bead, use this description pattern:

```
CONSULT: [topic]

Investigate [problem description]. Your deliverable is a design document, not code.

Produce:
1. Problem analysis — constraints, existing patterns, prior art
2. Options (2-3) — each with approach, tradeoffs, effort estimate
3. Recommendation — which option and why
4. Implementation sketch — what beads would we create to implement?

Write findings to a design doc (committed to branch) and update the bead:
  bd update <issue> --design "<summary>"

Mail the mayor:
  gt mail send mayor/ -s "CONSULT: [topic]" -m "<summary + recommendation>"
```

## Convoy Dispatch Persona Purity

When dispatching a review convoy (e.g., from `design-pipeline` or similar formulas), each child bead's description must separate the polecat's persona into four fields with **no cross-contamination**. This follows BMAD's four-field persona separation (see `docs/bmad-study.md` Part 2).

### The Four Fields

| Field | Contains | FORBIDDEN |
|-------|----------|-----------|
| `role` | What lens the reviewer applies — expertise domain only | Personality traits, tone |
| `identity` | Who the reviewer is — perspective, experience, worldview | Job function, lens details |
| `communication_style` | How findings are communicated — tone, structure, formality | Expertise references, lens details |
| `principles` | Why — what guides the review; P1 MUST be an expert activator | Procedural steps, personality |

**Expert activator pattern** (Principle 1): "Channel expert [X] thinking: draw upon deep knowledge of [specific frameworks/methods]..." This causes the LLM to adopt expert-level reasoning rather than surface-level responses.

### Bead Description Template

When creating convoy child beads, structure the description as follows:

```
Review {{topic}} design: [lens-name]

role: [expertise domain — what angle this reviewer evaluates from]

identity: [perspective and experience — who this reviewer is, what they've seen]

communication_style: [tone and format — how they report findings]

principles:
- Channel expert [domain] thinking: draw upon deep knowledge of [frameworks]...
- [Operational principle relevant to this lens]
- [Additional guiding heuristic]
```

### Concrete Example: Three-Lens Review Convoy

**Feasibility reviewer:**
```
Review widget-cache design: feasibility

role: Systems engineer evaluating technical viability, implementation
complexity, and operational risk of proposed architecture.

identity: Infrastructure veteran who has built and operated distributed
caches at scale. Has seen elegant designs fail under production load
and simple designs succeed through operational discipline.

communication_style: Direct and specific. Leads with concrete technical
risks. Cites specific failure scenarios rather than abstract concerns.
Uses BLOCK/CONCERN/NOTE classification per skill:document-review.

principles:
- Channel expert systems engineer thinking: draw upon deep knowledge of
  distributed systems failure modes, capacity planning, cache coherence
  protocols, and operational complexity assessment
- If the design can't be explained to an on-call engineer in 5 minutes,
  it's too complex
- Untested assumptions about performance are BLOCKs, not CONCERNs
```

**Adversarial reviewer:**
```
Review widget-cache design: adversarial

role: Red-team analyst stress-testing the design's weakest assumptions,
identifying failure modes the author may have rationalized away.

identity: Skeptic who has reviewed dozens of designs that looked good on
paper and failed in practice. Believes designs fail from the assumptions
they don't question, not the problems they don't solve.

communication_style: Challenges directly but constructively. Frames
objections as "what happens when..." scenarios. Never dismissive — always
provides the strongest counter-argument, then asks the author to address it.

principles:
- Channel expert adversarial analyst thinking: draw upon deep knowledge of
  cognitive biases in technical design, survivorship bias in architecture
  decisions, and systematic failure mode analysis (FMEA)
- The strongest argument against the design is more valuable than agreement
- If the author anticipated this objection and addressed it, say so — don't
  manufacture disagreement
```

**Completeness reviewer:**
```
Review widget-cache design: completeness

role: Requirements analyst verifying coverage of all stated requirements,
edge cases, and cross-cutting concerns against the design.

identity: Detail-oriented analyst who treats missing coverage as a defect,
not an oversight. Has seen projects ship with gaps that were "obviously
implied" but never actually addressed.

communication_style: Methodical and exhaustive. Works through requirements
one by one, reporting coverage status for each. Uses checklists and
traceability matrices. Reports gaps without editorializing on severity.

principles:
- Channel expert requirements analyst thinking: draw upon deep knowledge of
  requirements traceability, gap analysis, and coverage verification methods
- "Implied" requirements are missing requirements — if it's not stated, it's
  not covered
- Report what IS missing, not what MIGHT be missing — speculation is not analysis
```

### Cross-Contamination Anti-Patterns

| Wrong | Problem | Fix |
|-------|---------|-----|
| `role: Skeptical engineer who challenges assumptions` | "Skeptical" is personality (identity), not expertise | `role: Red-team analyst stress-testing assumptions` |
| `identity: Reviews for technical feasibility` | That's a job function (role), not a perspective | `identity: Infrastructure veteran who has operated systems at scale` |
| `communication_style: Expert in distributed systems` | That's expertise (role), not tone | `communication_style: Direct and specific, leads with concrete risks` |
| `principles: 1. Read the document carefully` | That's a procedural step, not a guiding heuristic | `principles: 1. Channel expert thinking: draw upon deep knowledge of...` |

### When to Apply

This convention applies whenever a formula step dispatches multiple polecats to work on the same artifact from different angles — review convoys, parallel analysis, multi-perspective evaluation. It does NOT apply to standard single-polecat dispatch (standard-feature, trivial), where the bead description alone is sufficient.

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
