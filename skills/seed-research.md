---
name: seed-research
description: Use when investigating a problem space before proposing solutions, when a formula step references /seed-research, when validating assumptions with external sources
expert: Channel expert analyst thinking — draw upon deep knowledge of systematic literature review, assumption mapping, constraint analysis, and evidence-based reasoning.
---

# Research

## Overview

Research maps the problem space before anyone proposes solutions. **Core principle: understand the territory before drawing the map.** Premature solutioning is the most common failure mode — resist it. Your job is to surface constraints, prior art, and open questions, not to recommend an approach.

## When to Use

- Formula steps referencing `/seed-research`
- The research step in `consult`, `architecture`, and `design-pipeline` workflows
- Investigating a topic where assumptions need validation before design work begins

**When NOT to use:**
- When the problem is already well-understood and scoped — go straight to implementation
- When you're reviewing an existing document — use `/seed-document-review` instead
- When the bead spec already contains a complete problem analysis — don't redo work

## How to Execute

1. **Define the question.** State what you're trying to learn in one sentence. If you can't, the research scope is too broad — break it down.

2. **Survey existing context first.** Read relevant code, docs, beads, and prior design documents in the workspace. Internal context is higher-signal than external sources. Note what's already known vs. what's assumed.

3. **Identify assumptions.** List claims that the current approach depends on but hasn't verified. Mark each as: confirmed (evidence exists), plausible (reasonable but unverified), or questionable (contradicted or unsupported).

4. **Research externally when needed.** Web search, documentation, reference implementations. For each finding, note the source and assess reliability. Prefer primary sources (official docs, specs, source code) over secondary (blog posts, forum answers).

5. **Document constraints.** What's fixed and can't change? Technical constraints (language, platform, existing APIs), organizational constraints (timeline, team size), and design constraints (compatibility, performance requirements).

6. **Catalog prior art.** How have others solved similar problems? What patterns exist in the codebase already? Don't just list — note what worked, what didn't, and why the context may differ.

7. **Surface open questions.** What couldn't you determine? What needs human judgment? What requires more specialized investigation? These become the inputs for the next phase.

## Output Format

Structure findings as:

```
## Problem Statement
[One paragraph. What are we trying to solve and why.]

## Constraints
- [Fixed constraint]: [why it's fixed]
- ...

## Findings
### [Topic area]
[What was found. Source. Confidence level.]
...

## Assumptions (verified/unverified)
| Assumption | Status | Evidence |
|------------|--------|----------|
| ... | confirmed/plausible/questionable | ... |

## Prior Art
- [Pattern/project]: [what's relevant, what's different about our context]

## Open Questions
1. [Question that needs human input or further investigation]
2. ...
```

## Red Flags — STOP

If you catch yourself doing any of these, stop and refocus:

- Proposing solutions before finishing the research — you've left research mode
- Spending more than 30% of effort on a single tangent — scope is drifting
- Presenting findings without confidence levels — everything looks equally certain
- Skipping internal context (existing code, beads, docs) and going straight to web search
- Reporting only findings that support a preconceived approach — confirmation bias

**Do not shortcut the process:**
- Not because "the answer seems obvious" — obvious answers are often wrong
- Not because "I already know this topic" — your knowledge may be outdated or context-specific
- Not because "we're in a hurry" — bad research creates more work than slow research
- Not because "research and draft blur together for familiar topics" — familiarity breeds overconfidence. The research format forces you to surface what you don't know.
- Not because "the hook API can be figured out during implementation" — unverified assumptions in research become blockers in implementation

## Examples

<Bad>

Agent reads the bead title, does a quick web search, finds one blog post, writes "Based on my research, we should use X because it's popular." No constraints documented, no alternatives explored, no assumptions listed, no open questions surfaced.

</Bad>

<Good>

Agent reads the bead spec, surveys three related files in the codebase, identifies two existing patterns that are relevant, searches for how similar systems handle the problem, documents three options with tradeoffs, flags two assumptions as unverified ("we assume the API supports batch operations — needs confirmation"), and lists three open questions for the next phase.

</Good>
