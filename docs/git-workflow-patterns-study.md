# Git-Workflow Patterns for Keeper Adoption

**Bead**: ks-t5hrm
**Source**: `github.com/zookanalytics/claude-devcontainer/tree/main/packages/git-workflow`
**Purpose**: Extract enforcement patterns that strengthen keeper's hook and skill layers

---

## Executive Summary

The `git-workflow` package implements a complete enforcement architecture for git operations in Claude Code. It demonstrates five patterns directly applicable to keeper's planned hooks layer, which is architecturally defined but not yet implemented. This study maps each pattern onto keeper's existing three-pillar architecture (formulas/skills/hooks) and identifies concrete adoption opportunities.

**Key finding**: Keeper already has strong instructional enforcement (skills with anti-rationalization) and structural enforcement (formula gates, step dependencies). The missing piece is the **runtime enforcement layer** — hooks that fire at lifecycle points to verify compliance. The git-workflow package provides a proven blueprint for this layer.

---

## Pattern 1: State File as Workflow Gate

### What git-workflow does

A PreToolUse hook intercepts every `Bash` tool call. When the command matches `\bgit\b.*\bcommit\b`, the hook checks for `.claude/.commit-state.json`:

1. **Existence** — File must exist (proves skill was invoked)
2. **Freshness** — File must be < 300 seconds old (prevents stale proof)
3. **Completion** — File must contain `"workflow_completed": true` (proves skill ran to completion)

If any check fails, the hook blocks the tool call and redirects the agent to the correct skill. The state file is written by the skill at its final step, creating a proof token that the enforcement layer verifies.

### Keeper adoption opportunity

**Pre-merge verification via state files.** When a polecat runs `gt done`, a pre-merge hook could check for completion proof of required molecule phases:

```
.claude/mol-state.json
{
  "molecule_id": "ks-wisp-wisp-f5cgd",
  "phases_completed": ["context", "branch", "preflight", "implement", "review", "test", "commit"],
  "workflow_completed": true
}
```

Each molecule step, when closed via `bd close`, would write its phase to the state file. The `gt done` hook verifies all required phases are present before allowing submission. This converts molecule step completion from instructional (agent follows the steps) to structural (hook verifies the steps ran).

**State file properties to preserve:**
- **Freshness TTL** — Prevents proof from a previous session being reused
- **Deletion on failure** — Incomplete or stale files are deleted, forcing full re-execution
- **Not deleted on success** — Allows retry if subsequent steps fail (e.g., git push fails after commit)

### Adaptation notes

The git-workflow state file is minimal (single boolean). Keeper's would need to be richer (list of completed phases) because molecules have many steps. Consider whether the state file should be written by the skill/step closure or by the `bd close` command itself — the latter is more tamper-resistant since it's infrastructure, not agent action.

---

## Pattern 2: Anti-Rationalization Enforcement

### What git-workflow does

Three coordinated mechanisms prevent agents from reasoning their way around enforcement:

1. **Hook error messages redirect to skills** — When blocking, the hook doesn't explain the problem diagnostically. Instead, it tells the agent exactly what to do next: "Run: Skill(creating-commits)". The agent's next action is scripted by the error message.

2. **Skills contain rationalization tables** — Each skill pre-lists the rationalizations agents construct, with factual counters:

| Rationalization | Counter |
|----------------|---------|
| "Just a comment, skip checks" | Comments have syntax errors |
| "Too simple for pre-commit" | Hooks fail on "simple" changes |
| "One extra file won't hurt" | Breaks atomic commits |

3. **Commands contain their own rationalization tables** — Even orchestration documents list the ways agents skip sub-steps.

### Keeper current state

Keeper's skills already implement rationalization tables (code-review has 5 entries, document-review has 6, research has explicit anti-premature-solutioning). The architecture formula embeds historical failure examples from ks-jiqsy dogfooding.

### Keeper adoption opportunity

**Hook error messages as skill redirectors.** When keeper hooks exist and block an action, the error messages should follow the git-workflow pattern:

- **Don't**: "Error: molecule phase 'test' not completed"
- **Do**: "BLOCKED: You must complete testing before submitting. Run: `bd mol current` and follow the testing step using skill:testing."

This converts a diagnostic message into an executable instruction.

**Rationalization table density.** Git-workflow places rationalization tables at every layer — not just skills, but commands and hooks. Keeper could add rationalization sections to formula step descriptions in TOML, so they're injected into the molecule step instructions agents see:

```toml
[[steps]]
id = "test"
title = "Run quality checks"
description = "Execute skill:testing. Do NOT rationalize skipping tests."
rationalization_counter = """
- "Tests will pass, I checked manually" — Manual checking misses regressions.
- "Only changed one file" — Single-file changes break integration tests.
- "Tests aren't configured for this project" — File a bead and proceed, don't skip.
"""
```

---

## Pattern 3: Idempotent State Machine

### What git-workflow does

The `/git:orchestrate` command detects current state through parallel git/GitHub queries and resumes from wherever the workflow left off. It never persists its own phase state — every invocation re-derives state from observable reality (git log, PR status, CI checks).

**State detection runs in parallel:**
- Git queries: status, branch, fetch, log, ancestry
- GitHub queries: PR list, PR view, CI checks, review threads

**State classification:**
| State | Condition | Resume action |
|-------|-----------|--------------|
| `uncommitted` | Dirty working tree | Run commit flow |
| `needs-branch` | On main with commits | Self-review → branch → PR |
| `checks-pending` | PR exists, CI running | Wait and poll |
| `merge-blocked` | Checks pass, threads open | Process feedback |
| `ready` | All green, no threads | Report completion |

**Iteration limits prevent infinite loops:**
- CI fix attempts: 3 per failure type
- Feedback cycles: 5 round-trips
- Copilot wait: 10 minutes (then proceed without)

### Keeper adoption opportunity

**Polecat session recovery as idempotent state machine.** When a polecat cycles (via `gt handoff`) or crashes and restarts, it currently re-reads the molecule steps via `bd mol current`. But molecules already provide the state — each step is `done`, `open`, or `pending`. The molecule IS the state machine.

The git-workflow pattern validates this approach but adds a key insight: **derive state from observable reality, not just declared state.** A molecule step marked `done` should be verifiable:

- "implement" step is `done` → verify commits exist on the branch
- "test" step is `done` → verify test results exist / tests pass
- "commit" step is `done` → verify git status is clean

This creates a **trust-but-verify** layer where `bd mol current` shows declared state, but a session-start hook could spot-check that declared state matches reality.

**Iteration limits for keeper.** The git-workflow's explicit limits (3 CI fix attempts, 5 feedback cycles) map to keeper's escalation protocol. Currently keeper says "don't spin > 15 minutes, escalate." The pattern suggests making limits explicit per failure type in the formula:

```toml
[[steps]]
id = "test"
max_attempts = 3
on_exceed = "escalate"
```

---

## Pattern 4: Completion Verification Loops

### What git-workflow does

After processing review threads, a blocking verification query runs:

```bash
UNRESOLVED=$(gh api graphql ... | jq '...select(.isResolved == false)] | length')
```

**"BLOCKING: Do NOT report completion until UNRESOLVED = 0."**

If unresolved > 0, the agent loops back to processing, not forward to "done." The verification is a loop condition, not an end-of-process assertion. The same pattern repeats at multiple layers (review processor, orchestrator Phase 4, orchestrator Phase 5 final check).

### Keeper adoption opportunity

**Checklist verification as loop condition.** Keeper already has 16 checklists with binary READY/NOT READY criteria. Currently these are evaluated by the agent before closing a step (instructional enforcement). The git-workflow pattern suggests making them loop conditions:

1. Agent attempts to close step via `bd close <step-id>`
2. Pre-close hook evaluates the associated checklist
3. If any criterion is NOT READY → block the close, redirect agent to address gaps
4. Agent fixes → retries `bd close` → hook re-evaluates

This converts checklists from agent self-evaluation (soft) to infrastructure-enforced gates (hard).

**Multi-layer verification.** Git-workflow verifies at the step level AND at the orchestrator level (defense in depth). Keeper could verify at:
- Step close (checklist evaluation)
- Molecule completion (`gt done` pre-submission check)
- Refinery merge (pre-merge hook verifying all gates passed)

Each layer catches what the previous missed.

**The "not done until proven done" principle.** The key insight is philosophical: agents should never be trusted to self-report completion. Every "done" claim must be backed by a verifiable query. For keeper, this means:
- `bd close` for a test step → hook verifies tests actually passed
- `bd close` for a review step → hook verifies human approval exists
- `gt done` for the molecule → hook verifies all required steps are closed

---

## Pattern 5: Three-Layer Architecture Validation

### What git-workflow implements

```
Hook (Enforcement)     → Checks for proof of compliance
  ↕ state file
Skill (Knowledge)      → Defines the correct process, writes proof
  ↕ invocation
Command (Orchestration) → Decides when to invoke which skill
```

**Key architectural properties:**
1. **Hook is simple** — Just checks a file (hard to get wrong)
2. **Skill is rich** — Contains all process knowledge (easy to update)
3. **Command composes** — Orchestrates skills into workflows (reusable)
4. **State file is the contract** — Skill writes it, hook reads it (clean interface)

The hook does NOT enforce the process itself — it only checks for proof that the process was followed. This separation means process changes (skill updates) don't require hook changes.

### Keeper's current architecture

Keeper already has this three-layer architecture conceptually:
- **Formulas** = Commands (orchestration, "what happens when")
- **Skills** = Skills (execution knowledge, "how to do it well")
- **Hooks** = Hooks (enforcement, "verify it was actually done")

But the hooks layer is **not yet implemented**. Formulas and skills are live. Enforcement currently relies on:
1. Structural formula gates (`gate = { type = "human" }`)
2. Step dependencies (`needs = [...]`)
3. Merge strategy (`--no-merge`)
4. CI checks (GitHub Actions)
5. Instructional skill guidance (anti-rationalization patterns)

### Keeper adoption opportunity

**Implement hooks as proof-checkers, not process-enforcers.** Following the git-workflow pattern, keeper hooks should:

- **Pre-dispatch hook**: Check that classification and triage level metadata exist on the bead (proof that triage ran), not re-run triage logic
- **Session-start hook**: Check that skills are accessible and molecule is attached (proof that dispatch was correct), not load skills itself
- **Post-completion hook**: Check that required artifacts exist and steps are closed (proof that process was followed), not evaluate work quality
- **Pre-merge hook**: Check that human approval beads exist for gated steps (proof that gates were respected), not re-evaluate the work

This keeps hooks simple, fast, and hard to get wrong — exactly the git-workflow property that makes their enforcement reliable.

**The contract surface is the state file / bead metadata.** In git-workflow, `.commit-state.json` is the contract between layers. In keeper, the equivalent is bead metadata:
- Step status (open/closed) — written by `bd close`, read by hooks
- Checklist evaluations — written by agent during step, verified by hooks
- Human approval records — written by humans, verified by pre-merge hooks

---

## Recommendations

### Immediate (adopt in keeper hooks implementation)

1. **Hook error messages as skill redirectors** — Every hook rejection message should include the exact command to run next. Copy git-workflow's pattern verbatim.

2. **State file proof tokens for molecule completion** — `gt done` should verify a state file proving all required phases completed. Phase completion proof is written by `bd close`, verified by the `gt done` hook.

3. **Completion verification as loop condition** — `bd close` on checklist-gated steps should verify the checklist before allowing closure. Failed verification redirects the agent back to the step, not forward.

### Medium-term (strengthen existing patterns)

4. **Rationalization tables at every layer** — Extend from skills (where they exist) to formula step descriptions and hook error messages. Defense in depth.

5. **Explicit iteration limits per failure type** — Add `max_attempts` and `on_exceed` to formula step definitions. Replace the informal "15 minutes" rule with structured escalation triggers.

6. **Derived state verification on session restart** — When a polecat resumes, spot-check that declared molecule state matches git/file reality. Trust but verify.

### Architectural (validate keeper's design)

7. **Hooks as proof-checkers** — This is the most important architectural validation. Git-workflow confirms that hooks should check for proof, not enforce process. Keeper's brief already describes this correctly. Implementation should preserve this property.

8. **Three-layer separation** — Git-workflow confirms that keeping process knowledge in skills (not hooks) and orchestration in commands/formulas (not hooks) makes the system maintainable. Skill updates don't require hook changes. This is already keeper's design; the git-workflow package validates it empirically.

---

## Appendix: Source Structure Reference

```
packages/git-workflow/
├── plugin.json                    # Claude Code plugin manifest
├── commands/
│   ├── orchestrate.md             # 5-phase idempotent state machine
│   ├── commit.md                  # Thin wrapper → creating-commits skill
│   ├── create-pull-request.md     # Branch, push, PR creation
│   ├── merge-pull-request.md      # Validation + squash merge
│   ├── receiving-code-review.md   # Parallel subagent review dispatch
│   └── cleanup.md                 # Repo sync + branch pruning
├── hooks/
│   ├── hooks.json                 # PreToolUse matcher for Bash
│   └── scripts/
│       └── enforce-commit-skill.sh # Gate: blocks git commit without state proof
└── skills/
    ├── creating-commits/SKILL.md  # 6-step commit checklist + rationalization table
    └── pull-request-conventions/SKILL.md  # Naming + format rules
```
