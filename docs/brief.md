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

### The Pillars

```
keeper/
├── formulas/        ← WHAT happens and WHEN (8 workflow templates)
├── skills/          ← HOW to do each thing well (7 execution skills)
├── checklists/      ← WHEN you're done (17 binary gate criteria)
├── hooks/           ← ENFORCEMENT that process is actually followed
├── .claude/commands/← Skill symlinks enabling /slash-command invocation
├── tests/           ← Validation scenarios for skills
├── docs/            ← Deep reference (this brief, validation methodology, conventions)
└── .beads/          ← This repo is a rig with its own backlog (prefix: ks)
```

**Formulas** are TOML-defined workflow templates that compile into Gas Town molecules. They define the steps, dependencies, and gates for each type of work. A formula says "design before implement, test before merge, human approval before architecture decisions proceed." Formulas reference skills by name but don't contain the skill content — they are the process skeleton. Formulas support four types: workflow (sequential steps), aspect (cross-cutting advice), expansion (step-level refinement), and convoy (parallel multi-agent execution with synthesis).

**Skills** are markdown documents containing the rich knowledge agents need to execute each step well. A skill says "when reviewing code, check for these specific patterns, evaluate severity on this scale, structure feedback this way, block the PR if you find these categories of issues." Skills are the institutional expertise, refined over time through validated improvement cycles. Skills are deployed as Claude Code native commands via symlinks in `.claude/commands/`, enabling `/skill-name` invocation by agents.

**Checklists** are binary READY/NOT READY gate criteria. Each formula step references a checklist file that defines its Definition of Done. An agent evaluates each criterion before closing a step. Checklists are reusable across formulas — `human-gate-passed` serves multiple human gates, `merge-ready` serves any merge step.

**Hooks** are the enforcement mechanisms that make formulas and skills load-bearing rather than advisory. A pre-dispatch hook rejects design-pipeline beads without appropriate triage level. A post-completion hook observes outcomes and files `ks` beads when something actionable occurs (failures, multi-attempts, misclassification, unexpected escalation, duration anomalies). Hooks guarantee that the system defined by formulas and skills is actually the system that runs.

### Why One Repo

Skills and formulas are tightly coupled. A formula step says `/code-review`. The skill defines how to do the code review. When the skill evolves, the formula step description may need to update. When a new formula is added, it often requires a new skill. Hooks enforce both. Splitting these into separate repos creates cross-repo coordination overhead for every change.

The split point comes later, if it comes at all: when a category of skills emerges that has no formula dependency (general agent behavior, always-on competencies) and grows large enough to justify its own review cadence.

---

## Formulas: Workflow Templates

### What a Formula Is

A formula is a TOML file that defines a reusable workflow as a sequence of steps with dependencies, human gates, and variable slots. When cooked (`bd cook <formula>`), it compiles into a protomolecule — a template of beads wired together. When poured (`bd mol pour <formula> --var FEATURE="auth"`), it instantiates into a live molecule that agents walk step by step.

Formulas are the source code of process. Everything below them — protos, molecules, epics, issues — is generated runtime. You write formulas and let the system handle the rest.

### Workflow Archetypes

Different work needs fundamentally different process shapes. The current formula library contains 8 formulas covering these archetypes:

**Trivial** (`trivial.formula.toml`) — Single-step work requiring no design, no review gate. Copy changes, config updates, obvious fixes. Formula: implement → submit. 2 steps.

**Standard Feature** (`standard-feature.formula.toml`) — Well-scoped work with a clear implementation path. Formula: spec check → implement (per /implementation) → test (per /testing) → review (per /code-review, human gate) → merge. 5 steps.

**Shiny** (`shiny.formula.toml`) — Design-first feature workflow. Similar to standard feature but adds an upfront design phase with review before implementation. Formula: design → review design → implement → review implementation → test → submit. 6 steps.

**Consult** (`consult.formula.toml`) — Investigation workflow producing a design document, not code. Branch persists for mayor review. Formula: research → propose options → deliver. 3 steps.

**Architecture Decision** (`architecture.formula.toml`) — Work involving design choices with lasting consequences. Must NOT proceed to implementation without human direction. Formula: research → options → direction (human gate) → spec → spec review (human gate) → decompose → verify → retro → retro review (human gate). 10 steps.

**Design Pipeline** (`design-pipeline.formula.toml`) — Multi-phase design with parallel review convoy and human gates. Formula: research → draft → dispatch reviews (convoy) → human gate → finalize → retro → retro review (human gate). 9 steps.

**Document Review** (`document-review.formula.toml`, type: convoy) — Parallel multi-lens review. 11 available lenses (feasibility, adversarial, completeness, consistency, risk, assumptions, user-impact, cost, security-audit, performance, backward-compat). Named presets select lens subsets. Supports multi-model dispatch (Claude, Gemini, Convex backends). Used as a composable convoy expanded into other formulas like design-pipeline.

**TEA** (`tea.formula.toml`, type: aspect) — Cross-cutting test-first aspect. Weaves acceptance test requirements into any workflow's implement and test steps. Enforces ATDD: write acceptance tests before implementation, verify traceability after.

**Not yet implemented:** spike/research, release, quality-audit, skill-improvement. These remain planned archetypes that can be added as patterns emerge.

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

### Current Skills

**Execution skills** (how to perform workflow steps):
- `/research` — Problem space investigation before design
- `/implementation` — Spec-to-code execution
- `/testing` — Test writing and execution
- `/acceptance-testing` — ATDD test-first workflow
- `/pr-merge` — PR-based squash-merge procedure

**Quality skills** (how to evaluate work):
- `/code-review` — Structured code review with BLOCK/SHOULD/NIT classification
- `/document-review` — Multi-lens document evaluation with gate assessment

**Not yet built:** architecture-research, spec-writing, decomposition, security-audit, writing-skills (meta-skill). These remain planned skills that can be added as needs emerge.

### Skill Validation: The Superpowers Methodology

Skills must be validated before deployment. The approach, adapted from obra/superpowers' writing-skills framework, follows TDD principles applied to institutional knowledge:

**Red test — Observe failure without the skill.** Run a representative scenario with a subagent that does NOT have access to the skill. Document the exact behavior: what the agent gets wrong, what it skips, how it rationalizes shortcuts. This is the baseline. You must see the failure before writing the fix.

**Green test — Verify the skill corrects the failure.** Write the skill targeting the specific observed failures. Run the same scenario with the skill loaded. The agent should now handle the cases it previously got wrong.

**Adversarial test — Probe for rationalization.** Apply pressure: give the agent reasons to skip the skill's guidance ("this is a small change," "I already checked manually," "this case is different because..."). The skill should include explicit counters to observed rationalizations. If the agent finds a new way to wriggle out, add a counter and re-test.

**Regression test — Verify the skill doesn't break other things.** Ensure the updated skill doesn't cause over-zealous behavior on tasks where the previous version was correct.

This validation cycle will become a formula (skill-improvement) once retro patterns are mature enough to formalize. See `docs/validation.md` for the full methodology and the current test scenario inventory.

### Skill Reference Convention

Skills are deployed as Claude Code native commands. Each skill in `skills/` is symlinked into `.claude/commands/`, enabling direct `/skill-name` invocation. Formula steps reference skills using slash-command syntax:

```toml
[[steps]]
id = "code-review"
title = "Code review"
description = "Perform code review per /code-review"
needs = ["implement"]
```

Agents invoke `/code-review` which loads the skill via Claude Code's native command system. The 7 current skills and their slash commands: `/research`, `/implementation`, `/testing`, `/code-review`, `/document-review`, `/acceptance-testing`, `/pr-merge`. A `/handoff` command (not a skill file — standalone in `.claude/commands/`) handles session cycling.

---

## Hooks: Enforcement Layer

### What Hooks Do

Hooks are scripts or validation checks that fire at specific points in the Gas Town lifecycle. They ensure that formulas and skills are actually followed, not just available.

### Implemented Hooks

**Pre-dispatch: `validate-design-pipeline-triage.sh`** — Fires before a bead is slung to a worker. Enforces that design-pipeline beads require `consult` or `plan` triage level, rejecting `auto` or `review` triage which would skip the multi-phase review process.

**Post-completion: `observe-outcomes.sh`** — Fires when a bead is closed via `gt done`. Evaluates outcomes and files `ks` retro beads for 6 actionable conditions:
- Bead rejected or abandoned (ESCALATED/DEFERRED status)
- Multi-attempt beads (attempt:N labels, recycled/retry)
- Auto-triage beads that needed human intervention
- Escalation outside designated human gates
- Duration exceeded formula thresholds (trivial: 30min, standard: 4h, architecture: 24h)
- Test failures (tests-failed, ci-failed labels)

Links matching observations to existing open `ks` issues for deduplication. Routine successes produce nothing.

### Planned Hooks (Not Yet Implemented)

**Session-start hooks** — Inject role-appropriate skill references into agent context. Currently handled by Gas Town's own context injection (`gt prime`).

**Pre-merge hooks** — Enforce review gates and artifact requirements before Refinery merges. Currently enforcement is structural (bead dependencies, human gates in formulas).

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
~/gt/                                ← Gas Town root
├── CLAUDE.md                        ← Gas Town default (identity anchor)
├── CONTEXT.md                       ← Operational system, skill resolution, triage heuristics
├── mayor/                           ← Global coordinator
├── keeper/                          ← This repo, mounted as a rig
│   ├── CLAUDE.md                    ← Points to keeper playbook
│   ├── formulas/                    ← 8 workflow templates
│   │   ├── trivial.formula.toml
│   │   ├── standard-feature.formula.toml
│   │   ├── shiny.formula.toml
│   │   ├── consult.formula.toml
│   │   ├── architecture.formula.toml
│   │   ├── design-pipeline.formula.toml
│   │   ├── document-review.formula.toml  ← convoy type
│   │   └── tea.formula.toml              ← aspect type
│   ├── skills/                      ← 7 execution skills
│   │   ├── research.md
│   │   ├── implementation.md
│   │   ├── testing.md
│   │   ├── code-review.md
│   │   ├── document-review.md
│   │   ├── acceptance-testing.md
│   │   └── pr-merge.md
│   ├── .claude/commands/            ← Symlinks to skills (slash commands)
│   │   ├── research.md → ../../skills/research.md
│   │   ├── implementation.md → ...
│   │   ├── handoff.md               ← Standalone command (not a skill)
│   │   └── ...
│   ├── checklists/                  ← 17 binary gate criteria
│   │   ├── impl-ready.md
│   │   ├── tests-pass.md
│   │   ├── human-gate-passed.md
│   │   ├── merge-ready.md
│   │   └── ...
│   ├── hooks/
│   │   ├── pre-dispatch/
│   │   │   └── validate-design-pipeline-triage.sh
│   │   └── post-completion/
│   │       └── observe-outcomes.sh
│   ├── tests/
│   │   ├── scenarios/               ← 9 red/green/pressure scenarios
│   │   │   ├── document-review/     ← 6 scenarios
│   │   │   └── research/            ← 3 scenarios
│   │   ├── cook-all-formulas.sh
│   │   └── validate-design-pipeline-triage.sh
│   ├── .github/workflows/ci.yml     ← TOML validation, shellcheck, formula cook
│   ├── docs/
│   │   ├── brief.md                 ← This document
│   │   ├── conventions.md           ← Naming, format, structure rules
│   │   ├── validation.md            ← Superpowers testing methodology
│   │   ├── design/                  ← Design documents from consult beads
│   │   ├── bmad-study.md            ← BMAD persona methodology research
│   │   ├── superpowers-study.md     ← Superpowers writing-skills research
│   │   └── formula-audit.md         ← Formula structure audit
│   └── .beads/                      ← Keeper rig's own backlog (prefix: ks)
├── project-a/                       ← Project rig
└── ...
```

### CONTEXT.md References

The town-level CONTEXT.md (auto-injected by `gt prime` to all agents) establishes the keeper as the authoritative source:

```markdown
## Operational System

All workflow templates, execution skills, and enforcement hooks are defined in
the keeper rig (~/gt/keeper/). This is the institutional seed bank.

### Skill Resolution
When a formula step references /skill-name, the agent invokes it as a Claude
Code slash command. Skills live in ~/gt/keeper/skills/ and are symlinked
into .claude/commands/ for native invocation.

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

Formulas are accessed by Gas Town's `bd cook` and `bd mol pour` / `bd mol wisp` commands. The Mayor dispatches work using formulas, reading the TOML to understand the workflow shape and creating molecules via `bd` commands.

CI validates all formulas on every PR: TOML syntax check, shellcheck on hook scripts, and `bd cook` structural validation (when `bd` is available).

---

## Progress

### Phase 1: Foundation — Complete

- Repo created with directory structure, mounted as Gas Town rig (prefix: `ks`)
- Town-level CONTEXT.md written with skill resolution, triage heuristics, cross-rig routing
- CLAUDE.md written pointing to keeper playbook
- 8 formulas built (trivial, standard-feature, shiny, consult, architecture, design-pipeline, document-review convoy, TEA aspect) — exceeds the initial 2-3 target
- 7 skills built (research, implementation, testing, code-review, document-review, acceptance-testing, pr-merge) — exceeds the initial 2-3 target
- Skills converted to Claude Code native commands via `.claude/commands/` symlinks
- Post-completion hook (`observe-outcomes.sh`) implemented with 6 trigger conditions
- Pre-dispatch hook (`validate-design-pipeline-triage.sh`) implemented
- 17 checklists created for binary gate evaluation
- GitHub Actions CI running (TOML validation, shellcheck, formula cook)
- Squash-merge workflow established via GitHub PRs

### Phase 2: Validation — In Progress

- 9 test scenarios written across 2 skills (document-review: 6 scenarios, research: 3 scenarios)
- Document-review scenarios include red test (rubber-stamp), green test (systematic lens review), and 4 pressure scenarios
- Research scenarios include red test (premature solutioning), green test (structured research), and 1 application scenario
- 5 skills still lack test scenarios: implementation, testing, code-review, acceptance-testing, pr-merge
- End-to-end formula testing happening through live bead execution
- Post-completion hook firing in production

### Phase 3: Learning Loop — Early

- Cross-rig bead routing operational (any rig files `ks`-prefixed beads)
- Retro beads accumulating from post-completion hook observations
- Skill-improvement formula not yet written (retro patterns still emerging)

### Phase 4: Compound Growth — Ongoing

- Formula library expanding based on encountered work patterns (design-pipeline, document-review convoy emerged from real needs)
- Planned formulas not yet built: spike/research, release, quality-audit, skill-improvement
- Hook coverage: 2 of 4 planned categories implemented (pre-dispatch, post-completion; session-start and pre-merge remain structural only)

---

## Design Principles

**Formulas define what and when. Skills define how.** Keep them separate. A formula step should fit on one line. A skill can be as long as it needs to be to encode expertise.

**Structural enforcement over advisory guidance.** Where Gas Town provides structural mechanisms (bead dependencies, blocked states, GUPP propulsion), use them. Where enforcement must be instructional (agent behavior at decision points), make it explicit and use the retro system to verify compliance.

**Validate before deploying.** Every skill change follows the red-green-adversarial cycle. Untested skills have issues. Always. Fifteen minutes of testing saves hours of debugging a bad skill in production across every project.

**Beads all the way down.** The retro system uses beads, not a parallel data store. Post-completion hooks file `ks` beads for actionable observations. Frequency emerges from linked-bead counts on existing issues. The system improves using its own primitives.

**Start thin, grow through use.** Don't write twenty skills on day one. Write three, use them, learn from the retro data, improve them, add more as patterns emerge. The keeper should be pulled into existence by real needs, not pushed by speculation about what might be useful.

**Zero framework cognition.** Following Gas Town's design philosophy: the keeper provides data and instructions that agents consume. It does not encode complex reasoning in code. If an agent can observe data and make a judgment call, write a skill that guides its judgment rather than a hook that replaces its judgment with a heuristic.

**Minimal context tax.** CLAUDE.md is two lines. AGENTS.md is the playbook, loaded on demand. Deep reference lives in `docs/`, read when designing, not every session. Town-level context lives in CONTEXT.md, auto-injected by `gt prime`. Each layer adds what the others don't cover.

