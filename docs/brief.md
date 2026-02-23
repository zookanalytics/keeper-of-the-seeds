# Keeper of the Seeds

## Product Brief

**What it is:** A single repository containing the complete operational system definition for AI-assisted software development using Gas Town (or compatible multi-agent orchestration). It houses three tightly coupled concerns — formulas (workflows), skills (knowledge), and hooks (enforcement) — that together define how work gets done across all projects.

**What it is not:** A project codebase. Project rigs contain the software being built. This repo contains *how* that software gets built — the institutional knowledge that compounds across every project and every agent session.

---

## The Problem

Multi-agent development systems like Gas Town provide the machinery for orchestrating AI agents: dispatching work, managing sessions, merging branches, recovering from crashes. But the machinery is empty without answers to three questions:

1. **What process should this work follow?** A typo fix and an architecture redesign both arrive as beads. Without workflow differentiation, agents treat all work the same — charging ahead without appropriate design phases, review gates, or human checkpoints.

2. **How should each step be performed well?** An agent told to "do code review" will produce a generic review. An agent equipped with specific knowledge about what to look for, how to evaluate severity, when to block versus comment, and what patterns are red flags in this codebase will produce a review worth reading.

3. **How do we enforce that agents actually follow the process and apply the knowledge?** Without structural enforcement, workflows are suggestions and skills are reference documents that agents may or may not consult. Advisory systems degrade silently.

These three gaps — workflow definition, execution knowledge, and enforcement — are what this repo fills.

---

## Core Architecture

### The Three Pillars

```
keeper-of-the-seeds/
├── formulas/        ← WHAT happens and WHEN (workflow templates)
├── skills/          ← HOW to do each thing well (execution knowledge)
├── hooks/           ← ENFORCEMENT that both are actually followed
├── tests/           ← Validation that skills produce better outcomes
├── docs/            ← Deep reference (this brief, validation methodology, conventions)
└── .beads/          ← This repo is a rig with its own backlog (prefix: ks)
```

**Formulas** are TOML-defined workflow templates that compile into Gas Town molecules. They define the steps, dependencies, and gates for each type of work. A formula says "design before implement, test before merge, human approval before architecture decisions proceed." Formulas reference skills by name but don't contain the skill content — they are the process skeleton.

**Skills** are markdown documents containing the rich knowledge agents need to execute each step well. A skill says "when reviewing code, check for these specific patterns, evaluate severity on this scale, structure feedback this way, block the PR if you find these categories of issues." Skills are the institutional expertise, refined over time through validated improvement cycles.

**Hooks** are the enforcement mechanisms that make formulas and skills load-bearing rather than advisory. A pre-dispatch hook rejects beads without workflow classification. A session-start hook ensures agents load the correct skills for their role. A post-completion hook observes outcomes and files `ks` beads when something actionable occurs. Hooks guarantee that the system defined by formulas and skills is actually the system that runs.

### Why One Repo

Skills and formulas are tightly coupled. A formula step says `skill:code-review`. The skill defines how to do the code review. When the skill evolves, the formula step description may need to update. When a new formula is added, it often requires a new skill. Hooks enforce both. Splitting these into separate repos creates cross-repo coordination overhead for every change.

The split point comes later, if it comes at all: when a category of skills emerges that has no formula dependency (general agent behavior, always-on competencies) and grows large enough to justify its own review cadence.

---

## Formulas: Workflow Templates

### What a Formula Is

A formula is a TOML file that defines a reusable workflow as a sequence of steps with dependencies, human gates, and variable slots. When cooked (`bd cook <formula>`), it compiles into a protomolecule — a template of beads wired together. When poured (`bd mol pour <formula> --var FEATURE="auth"`), it instantiates into a live molecule that agents walk step by step.

Formulas are the source code of process. Everything below them — protos, molecules, epics, issues — is generated runtime. You write formulas and let the system handle the rest.

### Workflow Archetypes

Different work needs fundamentally different process shapes. The formula library should cover at least these archetypes:

**Trivial** — Single-step work requiring no design, no review gate. Copy changes, config updates, obvious fixes. The bead IS the spec. Formula: implement → auto-merge. No molecule needed; a single bead suffices.

**Standard Feature** — Well-scoped work with a clear implementation path. Requires implementation skill but not design exploration. Formula: implement (per skill:implementation) → test (per skill:testing) → review (per skill:code-review, human gate) → merge.

**Architecture Decision** — Work involving design choices with lasting consequences. Must NOT proceed to implementation without human direction. Formula: research → options generation → direction (human gate, escalation) → spec → spec review (human gate) → decompose into standard-feature sub-beads → verify against spec.

**Spike / Research** — Time-boxed exploration where the output is knowledge, not code. Formula: define question → investigate (time-boxed) → document findings → recommend (proceed / abandon / pivot) → human decision.

**Release** — Multi-step process with external wait states (CI, deployment, artifact publishing). Gas Town already has a release formula as a reference pattern.

**Quality Audit** — Targeted verification against specific standards. Security audit, accessibility sweep, performance review. Formula: define scope → execute audit (per relevant skill) → document findings → file remediation beads → human review of findings.

These are starting points. The formula library grows as you recognize new repeatable patterns. Any time work has steps, dependencies, or a gate, it's a formula waiting to be written.

### Triage Classification

Every bead entering the system needs a triage level before dispatch. Triage determines how much human involvement the workflow requires:

- **auto** — Agent implements, tests pass, merges. You see it in the convoy summary. CI is the gate, not human review.
- **review** — Agent implements, creates PR, bead state changes to review-pending. Refinery holds until human approval.
- **consult** — Agent starts work, hits a decision point, escalates with context and options. Blocks until you respond.
- **plan** — Nothing executes until you provide direction. Bead starts blocked. Agent can research and present options, but cannot implement.

The Mayor classifies incoming beads using heuristics defined in the town-level CONTEXT.md. Classification can be overridden by explicit tags. The retro system surfaces misclassification over time.

### Human Gates and Escalation

Gas Town has a built-in escalation system with severity levels:

- **CRITICAL (P0)** — System-threatening issues requiring immediate attention (data corruption, security breach).
- **HIGH (P1)** — Important blockers needing attention soon (unresolvable merge conflicts, ambiguous requirements).
- **MEDIUM (P2)** — Standard escalations for attention at convenience (design decisions, unclear requirements).

Agents trigger escalation via `gt escalate -s <severity> "message"` and exit with `ESCALATED` status. The dashboard surfaces escalations. Formula steps that require human input should have agents escalate and then exit, with the next phase of the molecule unlocking when the human provides direction.

Formula steps encode human gates as dependencies on beads that start in blocked state. An agent cannot work a blocked bead. GUPP cannot propel it. The gate is structural, not advisory.

---

## Skills: Execution Knowledge

### What a Skill Is

A skill is a markdown document that teaches an agent how to perform a specific activity well. It contains the rich, specific knowledge that makes the difference between generic execution and expert execution.

A skill is NOT a narrative about how a problem was solved once. It is a reusable reference guide for proven techniques, patterns, and judgment calls. It should be written so that any capable agent following it produces consistently good output.

### Skill Structure

Each skill should include:

- **When to use** — Activation conditions. What formula steps or situations trigger this skill.
- **What good looks like** — Concrete criteria for a successful outcome. Not vague ("thorough review") but specific ("review must cover error handling, edge cases, and API contract compliance").
- **How to execute** — Step-by-step approach with decision points. When the agent encounters ambiguity, the skill tells it how to resolve or when to escalate.
- **Red flags** — Specific patterns that indicate the agent is going off track. Adapted from Superpowers' anti-rationalization approach: identify the ways agents typically wriggle out of following the skill, and include explicit counters.
- **Examples** — Concrete before/after examples showing what the skill produces versus what agents do without it.

### Skill Categories

**Execution skills** — How to perform specific workflow steps: code review, testing, implementation, architecture research, spec writing, decomposition.

**Quality skills** — How to evaluate work against standards: security audit patterns, accessibility verification, performance profiling, API contract validation.

**Communication skills** — How to produce artifacts for humans: release notes, stakeholder updates, decision records, escalation messages with proper context.

**Meta skills** — How to write and validate skills themselves. Adapted from obra/superpowers' writing-skills methodology.

### Skill Validation: The Superpowers Methodology

Skills must be validated before deployment. The approach, adapted from obra/superpowers' writing-skills framework, follows TDD principles applied to institutional knowledge:

**Red test — Observe failure without the skill.** Run a representative scenario with a subagent that does NOT have access to the skill. Document the exact behavior: what the agent gets wrong, what it skips, how it rationalizes shortcuts. This is the baseline. You must see the failure before writing the fix.

**Green test — Verify the skill corrects the failure.** Write the skill targeting the specific observed failures. Run the same scenario with the skill loaded. The agent should now handle the cases it previously got wrong.

**Adversarial test — Probe for rationalization.** Apply pressure: give the agent reasons to skip the skill's guidance ("this is a small change," "I already checked manually," "this case is different because..."). The skill should include explicit counters to observed rationalizations. If the agent finds a new way to wriggle out, add a counter and re-test.

**Regression test — Verify the skill doesn't break other things.** Ensure the updated skill doesn't cause over-zealous behavior on tasks where the previous version was correct.

This validation cycle is itself a formula in this repo — the skill-improvement molecule that governs how changes to skills flow through the system. See `docs/validation.md` for the full methodology.

### Skill Reference Convention

Formula steps reference skills by name using a `skill:<n>` convention:

```toml
[[steps]]
id = "code-review"
title = "Code review"
description = "Perform code review per skill:code-review"
needs = ["implement"]
```

Agents resolve `skill:code-review` to the file path `~/gt/keeper/skills/code-review.md`. The town-level CONTEXT.md defines the resolution path.

---

## Hooks: Enforcement Layer

### What Hooks Do

Hooks are scripts or validation checks that fire at specific points in the Gas Town lifecycle. They ensure that formulas and skills are actually followed, not just available.

### Hook Categories

**Pre-dispatch hooks** — Fire before a bead is slung to a worker.
- Validate that bead has a workflow classification (trivial/standard/architecture/spike)
- Validate that triage level is set (auto/review/consult/plan)
- Reject dispatch if required metadata is missing

**Session-start hooks** — Fire when an agent session begins.
- Inject role-appropriate skill references into agent context
- Ensure agent has access to the keeper repo
- Load project-specific configuration and constraints

**Post-completion hooks** — Fire when a bead is closed via `gt done`.
- Evaluate outcome against expectations for the formula type
- If actionable (failure, repeated attempts, misclassification, unexpected escalation): file a `ks` bead
- If observation matches an existing `ks` issue: link to it instead of creating a duplicate
- Routine successes: do nothing

**Pre-merge hooks** — Fire before the Refinery merges work.
- Enforce that review-tier beads have received human approval
- Validate that required molecule phases completed before implementation phases
- Check that skill-mandated artifacts exist (e.g., decision records for architecture work)

### Retro Through Beads

There is no separate retro log. The post-completion hook is the entry point for the continuous learning system, and its output is beads in the keeper's own backlog.

The hook files a `ks` bead when it observes:

- Outcome was rejected or abandoned
- Bead took more than one attempt
- Triage was `auto` but ended up needing human intervention
- Agent escalated during a step that wasn't a designated human gate
- Duration significantly exceeded expectations for the formula type

Routine successes produce nothing. The system only surfaces what's actionable.

### Frequency Through Linking

When the hook observes a pattern that matches an existing `ks` issue — same skill gap, same failure mode, same misclassification — it links the completing bead to that existing issue rather than creating a duplicate.

An issue with one linked bead happened once. An issue with five linked beads is a pattern demanding attention. The frequency signal emerges from the data without analytics code, dashboards, or a separate data pipeline.

### Retro Review

Retro review is triaging the `ks` backlog:

- Sort issues by linked-bead count — highest frequency first
- Issues with multiple links are candidates for skill improvements, formula changes, or triage rule updates
- Each approved change becomes a bead worked through the skill-improvement formula

---

## This Repo as a Gas Town Rig

This repo is not just a file collection — it is a Gas Town rig (short name: `keeper`, prefix: `ks`) with its own beads database, backlog, and crew. This means:

### Cross-Rig Bead Routing

Any project rig can file beads against the keeper using the `ks` prefix. When a polecat working in project-a discovers that the code review skill missed a category of bug, it creates a bead with the keeper's prefix. That bead lands in the keeper's backlog, not project-a's.

Post-completion hooks in project rigs automatically file `ks` beads for actionable observations. When the same pattern recurs, hooks link to the existing `ks` issue rather than duplicating. The link count becomes the frequency signal.

### Skill Improvement Molecule

The keeper rig has its own formula for how skill changes flow:

1. **Intake** — A proposed improvement arrives as a bead (from any project rig's retro system, from an agent's escalation, or filed by the human).
2. **Red test** — A crew member in the keeper rig reproduces the failure without the proposed change. Documents baseline behavior.
3. **Draft** — Write the skill update targeting the specific observed failure.
4. **Green test** — Run the same scenario with the updated skill. Verify correction.
5. **Adversarial test** — Attempt to provoke rationalization around the new guidance.
6. **Human review** — Human approves, because a bad skill change propagates to every project immediately.
7. **Merge** — Updated skill is available to all project rigs.

### Retro Review Process

Retro review is triaging the keeper's `ks` backlog, sorted by linked-bead count:

- High-frequency issues (many linked beads) are patterns demanding attention
- Each approved change produces a bead worked through the skill-improvement formula
- The system improves without requiring manual identification of each improvement

Examples of proposals that emerge from patterns:
- "Beads touching API surfaces failed at auto-tier 4/6 times. Proposed: add triage rule for API-surface beads → review."
- "Consult-tier response time averaged 6 hours, 3 overnight. Proposed: batch into morning review queue."
- "Workers on UI tasks succeeded more with screenshot reference. Proposed: Mayor require visual reference for UI-tagged beads."

---

## Town Integration

### Context Layering

Gas Town provides multiple mechanisms for injecting context into agents. Each has a distinct scope and purpose:

| File | Mechanism | Scope | Purpose |
|------|-----------|-------|---------|
| `CLAUDE.md` (town root) | Claude Code auto-load | Identity anchor | Prevents identity drift after compaction. Gas Town default — do not modify. |
| `AGENTS.md` (town root) | Claude Code auto-load | Beads reference | Issue tracking commands, session completion protocol. Gas Town default — do not modify. |
| `CONTEXT.md` (town root) | `gt prime` injection | All agents, all roles | Operational system description. **This is where keeper references live.** |
| `CLAUDE.md` (repo root) | Claude Code auto-load | Crew in this repo | Points crew to the repo-level AGENTS.md. |
| `AGENTS.md` (repo root) | On-demand (`@AGENTS.md`) | Crew in this repo | Full keeper playbook — formulas, skills, hooks, validation, design principles. |
| `docs/*` (repo) | On-demand | Crew doing design work | Deep reference — this brief, validation methodology, conventions. |

The key insight: `gt prime` injects Gas Town mechanics (commands, propulsion, session protocol). CONTEXT.md injects operational policy (skill resolution, triage, routing). The repo's AGENTS.md injects domain knowledge (how to work on seeds). Each layer adds what the others don't cover.

### Directory Structure

```
~/gt/                                ← Gas Town root (the-citadel)
├── CLAUDE.md                        ← Gas Town default (identity anchor)
├── AGENTS.md                        ← Gas Town default (beads reference)
├── CONTEXT.md                       ← Operational system, skill resolution, triage heuristics
├── mayor/                           ← Global coordinator
├── deacon/                          ← Daemon agent
├── keeper/                          ← This repo, mounted as a rig
│   ├── CLAUDE.md                    ← Points to @AGENTS.md
│   ├── AGENTS.md                    ← Full keeper playbook
│   ├── docs/
│   │   ├── brief.md                 ← This document
│   │   ├── validation.md            ← Superpowers methodology
│   │   └── conventions.md           ← Naming, format, structure rules
│   ├── formulas/
│   │   ├── trivial.formula.toml
│   │   ├── standard-feature.formula.toml
│   │   ├── architecture.formula.toml
│   │   ├── spike.formula.toml
│   │   ├── release.formula.toml
│   │   ├── quality-audit.formula.toml
│   │   └── skill-improvement.formula.toml
│   ├── skills/
│   │   ├── code-review.md
│   │   ├── implementation.md
│   │   ├── testing.md
│   │   ├── architecture-research.md
│   │   ├── spec-writing.md
│   │   ├── decomposition.md
│   │   ├── security-audit.md
│   │   ├── writing-skills.md        ← meta-skill, from Superpowers methodology
│   │   └── ...
│   ├── hooks/
│   │   ├── pre-dispatch/
│   │   │   └── validate-classification.sh
│   │   ├── post-completion/
│   │   │   └── observe-outcomes.sh
│   │   ├── pre-merge/
│   │   │   └── enforce-review-gate.sh
│   │   └── session-start/
│   │       └── load-skills.sh
│   ├── tests/
│   │   ├── scenarios/               ← Red/green test scenarios per skill
│   │   └── results/                 ← Captured outputs from validation runs
│   └── .beads/                      ← Keeper rig's own backlog (prefix: ks)
├── project-a/                       ← Project rig
├── project-b/                       ← Project rig
└── ...
```

### CONTEXT.md References

The town-level CONTEXT.md (auto-injected by `gt prime` to all agents) establishes the keeper as the authoritative source:

```markdown
## Operational System

All workflow templates, execution skills, and enforcement hooks are defined in
the keeper rig (~/gt/keeper/). This is the institutional seed bank.

### Skill Resolution
When a formula step references skill:<n>, read ~/gt/keeper/skills/<n>.md
and follow its instructions.

### Workflow Classification
Every bead must be classified before dispatch. Classification determines which
formula template applies. See ~/gt/keeper/formulas/ for available workflow types.

### Triage Levels
Every bead must have a triage level: auto, review, consult, or plan.
Default heuristics:
- Config changes, typo fixes, documentation → auto
- New features, refactors touching multiple files → review
- Anything touching API surfaces, auth, or data models → consult
- Architecture decisions, new subsystems, breaking changes → plan

### Cross-Rig Routing
File beads against the keeper using the ks prefix. When the same pattern recurs,
link to the existing ks issue rather than creating a duplicate.
```

### Formula Deployment

Formulas in this repo need to be accessible to Gas Town's `bd cook` and `bd mol pour` commands. There are two paths:

1. **Symlink formulas into each rig's `.beads/formulas/` directory.** This makes them available to `bd` commands run in that rig's context.

2. **Use the keeper's formulas as reference and have the Mayor pour them.** The Mayor reads the TOML, understands the workflow shape, and creates the molecule by running `bd` commands. This is more flexible but relies on the Mayor correctly interpreting the formula.

The first approach is more reliable for structural enforcement. Test which approach works with the current Gas Town formula resolution system.

---

## Getting Started

### Phase 1: Foundation (Day 1)

1. Create the repo with the directory structure above.
2. Write the town-level CONTEXT.md with skill resolution path and classification heuristics.
3. Write the keeper's CLAUDE.md (points to AGENTS.md) and AGENTS.md (full playbook).
4. Write 2-3 starter formulas: trivial, standard-feature, and one that exercises human gates (architecture or spike).
5. Write 2-3 starter skills: code-review, implementation, testing. Keep them short — you'll refine through the validation cycle.
6. Implement the post-completion hook that observes outcomes and files `ks` beads for actionable observations.
7. Add the repo as a rig: `gt rig add keeper <repo-url>`.

### Phase 2: Validation (Week 1)

8. Test the standard-feature formula end to end. File a bead, classify it, pour the molecule, sling to a polecat, observe the agent walking the steps.
9. Verify human gates work: architecture formula should block at the direction step until you act.
10. Run Superpowers-style red/green tests on each starter skill. Observe agent behavior without the skill, then with it. Refine.
11. Verify post-completion hook fires and files `ks` beads for failures and misclassifications.

### Phase 3: Learning Loop (Week 2+)

12. Implement the retro review process: triage the `ks` backlog sorted by linked-bead count.
13. File first skill improvement beads based on retro patterns.
14. Run the skill-improvement molecule for the first time. Validate that the process works end to end: red test → draft → green test → adversarial test → review → merge.
15. Begin expanding formula library based on work patterns you encounter.

### Phase 4: Compound Growth (Ongoing)

16. Cross-rig bead routing: ensure project rigs can file beads against the keeper rig using the `ks` prefix.
17. Formula library grows as new workflow patterns emerge.
18. Skills deepen as the retro system surfaces specific failure modes via linked-bead frequency.
19. Hooks tighten as you identify enforcement gaps.
20. The keeper becomes the institutional memory that makes every new project start from a higher baseline.

---

## Design Principles

**Formulas define what and when. Skills define how.** Keep them separate. A formula step should fit on one line. A skill can be as long as it needs to be to encode expertise.

**Structural enforcement over advisory guidance.** Where Gas Town provides structural mechanisms (bead dependencies, blocked states, GUPP propulsion), use them. Where enforcement must be instructional (agent behavior at decision points), make it explicit and use the retro system to verify compliance.

**Validate before deploying.** Every skill change follows the red-green-adversarial cycle. Untested skills have issues. Always. Fifteen minutes of testing saves hours of debugging a bad skill in production across every project.

**Beads all the way down.** The retro system uses beads, not a parallel data store. Post-completion hooks file `ks` beads for actionable observations. Frequency emerges from linked-bead counts on existing issues. The system improves using its own primitives.

**Start thin, grow through use.** Don't write twenty skills on day one. Write three, use them, learn from the retro data, improve them, add more as patterns emerge. The keeper should be pulled into existence by real needs, not pushed by speculation about what might be useful.

**Zero framework cognition.** Following Gas Town's design philosophy: the keeper provides data and instructions that agents consume. It does not encode complex reasoning in code. If an agent can observe data and make a judgment call, write a skill that guides its judgment rather than a hook that replaces its judgment with a heuristic.

**Minimal context tax.** CLAUDE.md is two lines. AGENTS.md is the playbook, loaded on demand. Deep reference lives in `docs/`, read when designing, not every session. Town-level context lives in CONTEXT.md, auto-injected by `gt prime`. Each layer adds what the others don't cover.

