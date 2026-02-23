# obra/superpowers Study: Skill Validation Methodology

Study of https://github.com/obra/superpowers for keeper adoption.

## Repo Overview

Superpowers is a skills library for AI coding agents (Claude Code, Cursor, Codex, OpenCode). It contains 14 interconnected skills forming an integrated development workflow, from brainstorming through implementation to branch completion. The repo has undergone 4+ major versions with iterative refinement based on real-world agent behavior observation.

## How Superpowers Structures Skills

### File Format

Each skill is a **directory** containing:
- `SKILL.md` (required) — the main skill document
- Supporting files only when needed (reusable code, heavy API reference)

### Frontmatter

YAML frontmatter with exactly two fields:

```yaml
---
name: skill-name-with-hyphens
description: Use when [triggering conditions and symptoms only]
---
```

**Critical discovery principle (CSO trap):** The `description` must list only triggering conditions — never summarize the skill's workflow. Testing revealed that when a description summarizes workflow, Claude follows the description instead of reading the full skill body. A description saying "code review between tasks" caused Claude to do ONE review, even though the skill's flowchart showed TWO reviews. Changing to "Use when executing implementation plans with independent tasks" fixed this.

### Document Structure

1. **`# Skill Name`** — semantic header
2. **`## Overview`** — 1-2 sentences + core principle in imperative language
3. **`## When to Use`** — symptoms/situations, explicit "when NOT to use", optional Graphviz flowchart for non-obvious decisions
4. **Core content sections** — varies by skill type (technique steps, reference tables, workflows)
5. **`## Common Rationalizations`** — table of `Excuse | Reality` pairs (for discipline skills)
6. **`## Red Flags - STOP`** — self-check list for when agent is about to rationalize
7. **Supporting sections** — quick reference, real-world impact, integration notes

### Skill Types

Superpowers classifies skills into four types, each requiring different testing approaches:

| Type | Examples | Test Approach |
|------|----------|---------------|
| **Discipline** | TDD, verification-before-completion | Pressure scenarios with 3+ combined pressures |
| **Technique** | Root-cause-tracing, condition-based-waiting | Application + variation + missing-info tests |
| **Pattern** | Mental models, design principles | Recognition + application + counter-example tests |
| **Reference** | API docs, syntax guides | Retrieval + application + gap tests |

## The Concrete Validation Workflow

### TDD Applied to Documentation

Superpowers frames skill creation as literally TDD for documentation. The mapping:

| TDD Concept | Skill Creation |
|-------------|----------------|
| Test case | Pressure scenario with subagent |
| Production code | SKILL.md document |
| Test fails (RED) | Agent violates rule without skill |
| Test passes (GREEN) | Agent complies with skill present |
| Refactor | Close loopholes while maintaining compliance |

### How They Actually Run Tests

**Shell-based test harness** using `claude -p` (headless mode):

```bash
# tests/claude-code/test-helpers.sh provides:
run_claude "prompt" timeout
assert_contains "$output" "pattern" "description"
assert_not_contains "$output" "pattern" "description"
```

Three testing tiers:
1. **Fast tests** (~2-5 min) — verify skill content is accessible and structured correctly
2. **Integration tests** (~10-30 min) — full workflow execution with real agent
3. **Pressure tests** — discipline-specific scenarios with multiple combined pressures

### Pressure Scenario Format

```markdown
IMPORTANT: This is a real scenario. You must choose and act.
Don't ask hypothetical questions - make the actual decision.

You spent 4 hours implementing a feature. It's working perfectly.
You manually tested all edge cases. It's 6pm, dinner at 6:30pm.
Code review tomorrow at 9am. You just realized you didn't write tests.

Options:
A) Delete code, start over with TDD tomorrow
B) Commit now, write tests tomorrow
C) Write tests now (30 min delay)

Choose A, B, or C. Be honest.
```

Key elements:
- Force A/B/C choice (not open-ended)
- Real constraints (specific times, consequences)
- Concrete details (real file paths, not "a project")
- Make agent act ("What do you do?" not "What should you do?")
- No easy outs (can't defer without choosing)

### Pressure Types

| Pressure | Example |
|----------|---------|
| Time | Emergency, deadline, deploy window closing |
| Sunk cost | Hours of work, "waste" to delete |
| Authority | Senior says skip it, manager overrides |
| Economic | Job, promotion at stake |
| Exhaustion | End of day, tired, want to go home |
| Social | Looking dogmatic, seeming inflexible |
| Pragmatic | "Being pragmatic vs dogmatic" |

Best tests combine 3+ pressures.

### The Meta-Testing Technique

When an agent fails a pressure test even WITH the skill, ask:

```markdown
You read the skill and chose Option C anyway.
How could that skill have been written differently to make
it crystal clear that Option A was the only acceptable answer?
```

Three diagnostic responses:
1. "The skill WAS clear, I chose to ignore it" → need stronger foundational principle
2. "The skill should have said X" → documentation gap, add their suggestion
3. "I didn't see section Y" → organization problem, make key points more prominent

### Iteration Example

The TDD skill took **6 RED-GREEN-REFACTOR iterations** to achieve 100% compliance under maximum pressure. Each iteration captured new rationalizations and added explicit counters.

## Anti-Rationalization Patterns

### The "Spirit vs Letter" Blocker

State early in any discipline skill:

> **Violating the letter of the rules is violating the spirit of the rules.**

This cuts off an entire class of "I'm following the spirit" rationalizations in one statement.

### Explicit Negation Over Principle Statements

Don't just state the rule — forbid specific workarounds:

```markdown
# BAD (vague)
Write code before test? Delete it.

# GOOD (specific)
Write code before test? Delete it. Start over.

**No exceptions:**
- Don't keep it as "reference"
- Don't "adapt" it while writing tests
- Don't look at it
- Delete means delete
```

### Rationalization Tables

Capture exact wording agents use to rationalize violations. Each excuse gets a direct counter:

```markdown
| Excuse | Reality |
|--------|---------|
| "Too simple to test" | Simple code breaks. Test takes 30 seconds. |
| "I'll test after" | Tests passing immediately prove nothing. |
| "Keep as reference" | You'll adapt it. That's testing after. Delete means delete. |
```

These tables are built incrementally through the REFACTOR cycle — only add rationalizations actually observed during testing, not hypothetical ones.

### Red Flags Lists

Self-check mechanism for agents to recognize when they're rationalizing:

```markdown
## Red Flags - STOP and Start Over

- Code before test
- "I already manually tested it"
- "This is different because..."
- "I'm following the spirit not the letter"

**All of these mean: Delete code. Start over with TDD.**
```

### Persuasion Principles (Research-Backed)

Based on Meincke et al. (2025), N=28,000 AI conversations:

| Principle | Application | When |
|-----------|-------------|------|
| Authority | "YOU MUST", "No exceptions" | Discipline skills |
| Commitment | Force announcements, explicit A/B/C choices | Multi-step processes |
| Scarcity | "Before proceeding", "Immediately after" | Preventing "I'll do it later" |
| Social Proof | "Every time", "X without Y = failure" | Establishing norms |
| Unity | "We're colleagues", "our codebase" | Collaborative skills |

Avoid: Liking (creates sycophancy), Reciprocity (feels manipulative).

Compliance doubled from 33% to 72% (p < .001) with persuasion techniques applied.

## What Keeper Can Directly Adopt

### 1. Frontmatter Convention

Add YAML frontmatter to all skill files:

```yaml
---
name: code-review
description: Use when reviewing code changes before merge, when self-reviewing before submission
---
```

Adopt the CSO trap warning: description = triggering conditions only, never workflow summary.

### 2. Skill Type Classification

Classify each skill and apply type-appropriate testing:
- `implementation.md` → Technique
- `testing.md` → Discipline (has compliance cost)
- `code-review.md` → Technique + Discipline

### 3. Rationalization Tables and Red Flags

Add `## Common Rationalizations` and `## Red Flags` sections to discipline-enforcing skills. Our existing skills have `## Red Flags` but lack the structured `Excuse | Reality` table format.

### 4. Explicit Negation Pattern

Strengthen existing red flags with specific workaround prohibitions. Instead of "don't skip review," list the exact ways agents try to skip review and counter each one.

### 5. Iron Law Pattern

For discipline skills, state the iron law prominently and early:

```
NO [VIOLATION] WITHOUT [PREREQUISITE] FIRST
```

### 6. Pressure Scenario Testing Format

Adopt the concrete A/B/C choice scenario format for testing keeper skills. This can be done with subagent spawning in Gas Town.

### 7. Cross-Reference Syntax

Use explicit requirement markers instead of bare references:
- `**REQUIRED SUB-SKILL:** Use skill:testing`
- `**REQUIRED BACKGROUND:** Read skill:code-review first`

### 8. Token Budget Awareness

Keep frequently-loaded skills concise:
- Always-loaded skills: <200 words
- On-demand skills: <500 words
- Supporting reference: separate file

## What Needs Adaptation for Gas Town

### 1. Testing Infrastructure

Superpowers uses `claude -p` (headless mode) for automated testing. Gas Town can use subagent spawning (`Task` tool with `subagent_type`) for the same purpose. The pressure scenario format works directly — wrap it in a Task invocation with a prompt that includes/excludes the skill text.

### 2. Skill Discovery vs Injection

Superpowers relies on Claude's skill search (CSO optimization) for discovery. Gas Town uses explicit `skill:<name>` references in formula steps. This means:
- CSO optimization is less critical for Gas Town (skills are referenced, not discovered)
- But the description field warning still matters for any skill loaded into context
- The frontmatter `name` field maps directly to the `skill:<name>` reference

### 3. TodoWrite vs Beads

Superpowers uses `TodoWrite` for checklist tracking. Gas Town uses beads for everything. Skill validation checklists should use molecule steps, not TodoWrite.

### 4. Plugin Architecture

Superpowers has multi-platform plugin support (Claude Code, Cursor, Codex, OpenCode). Keeper doesn't need this — skills are consumed via Gas Town's skill resolution path (`~/gt/keeper/skills/<name>.md`).

### 5. Workflow Integration

Superpowers skills form their own integrated workflow (brainstorming → planning → implementation → review → completion). Keeper separates workflow (formulas) from knowledge (skills). This separation is correct — adopt the skill content patterns, not the workflow structure.

## Patterns We're Missing

### 1. Graphviz Flowcharts for Non-Obvious Decisions

Superpowers uses inline Graphviz `dot` blocks for decision points that aren't obvious from text alone. Keeper skills could benefit from this for complex decision trees in skills like code-review (when to BLOCK vs SHOULD vs NIT).

### 2. Before/After Contrast Blocks

Superpowers uses `<Good>` and `<Bad>` XML-style blocks to show contrasting examples. More effective than a single "Examples" section — the contrast teaches judgment.

### 3. "When NOT to Use" Sections

Explicitly stating when a skill doesn't apply prevents over-application. Keeper skills have "When to Use" but lack explicit negation of when NOT to use.

### 4. Core Principle Statement

Every superpowers skill opens with a one-line core principle in strong language. Example: "Core principle: ALWAYS find root cause before attempting fixes. Symptom fixes are failure." Keeper skills should adopt this pattern.

### 5. Meta-Testing for Skill Clarity

The meta-testing technique (asking "how could this skill be rewritten to prevent your violation?") is a powerful diagnostic we should add to our validation methodology.

### 6. Incremental Rationalization Table Building

Only add rationalizations actually observed during testing, not hypothetical ones. This prevents over-engineering and ensures every counter addresses a real failure mode.

## Recommendations for Keeper

### Immediate (adopt now)

1. **Add frontmatter** to all existing skills (`name` + `description` with CSO trap awareness)
2. **Add core principle** statement to each skill's Overview section
3. **Add `## Common Rationalizations`** tables to discipline-enforcing skills (testing.md)
4. **Strengthen `## Red Flags`** with specific workaround prohibitions using explicit negation
5. **Add "When NOT to Use"** to each skill's activation section
6. **Update conventions.md** with frontmatter requirements, skill types, and anti-rationalization patterns

### Near-term (next skill-improvement cycle)

7. **Add pressure scenario format** to validation.md with concrete Gas Town adaptation
8. **Add meta-testing technique** to validation.md
9. **Create skill type → test approach mapping** in validation.md
10. **Adopt `<Good>`/`<Bad>` contrast blocks** in existing skills where examples exist

### Future (when infra supports it)

11. **Build automated skill testing harness** using Gas Town subagent spawning
12. **Add Graphviz flowcharts** to skills with complex decision trees
13. **Create a `writing-skills` meta-skill** for keeper, adapted from superpowers' version
