# Keeper Architecture Guide

How keeper organizes work across skills, formulas, and rig config. This is the document an agent reads to understand the operational system that governs all Gas Town rigs.

**Related docs:**
- [Formula Authoring Guide](formula-authoring.md) — Gas Town formula primitives, variable system, lifecycle
- [Product Brief](brief.md) — what keeper is and why it exists
- [Conventions](conventions.md) — naming, format, and structure rules

---

## The Three-Layer Model

Keeper separates operational concerns into three layers. Each layer has a distinct responsibility, a distinct owner, and a distinct rate of change.

```
┌─────────────────────────────────────────────────────┐
│  Layer 1: SKILLS                                    │
│  Universal execution knowledge                      │
│  "How to do each thing well"                        │
│  Location: keeper/skills/                           │
│  Changes: when institutional knowledge evolves      │
├─────────────────────────────────────────────────────┤
│  Layer 2: FORMULAS                                  │
│  Workflow sequencing and checkpoints                │
│  "What steps happen, in what order, with what gates"│
│  Location: keeper/formulas/                         │
│  Changes: when process shapes evolve                │
├─────────────────────────────────────────────────────┤
│  Layer 3: RIG CONFIG                                │
│  Project-specific agent directions                  │
│  "What to run for testing, linting, building"       │
│  Location: <rig>/settings/config.json               │
│  Changes: when a rig's tooling changes              │
└─────────────────────────────────────────────────────┘
```

The layers are ordered by specificity. Skills are universal (same across all rigs). Formulas are reusable (same formula, different projects). Rig config is project-specific (each rig configures its own tooling).

### Layer 1: Skills

Skills are markdown documents containing rich, specific execution knowledge. A skill teaches an agent how to perform an activity well — not generically, but with the judgment calls, red flags, and concrete criteria that separate expert execution from cargo-culted execution.

**What lives here:** How to think about testing. How to evaluate code review severity. How to investigate a problem space without premature solutioning. How to structure a PR merge. Language-agnostic, rig-agnostic knowledge that applies everywhere.

**What doesn't live here:** Rig-specific commands (`go test ./...`), project-specific conventions (branch naming), or workflow sequencing (what comes after testing). Those belong in Layer 2 or Layer 3.

**Current skills (7):**

| Skill | Purpose | Invocation |
|-------|---------|------------|
| `research.md` | Problem space investigation before design | `/seed-research` |
| `implementation.md` | Spec-to-code execution | `/seed-implementation` |
| `testing.md` | Test writing and execution | `/seed-testing` |
| `code-review.md` | Structured review with BLOCK/SHOULD/NIT | `/seed-code-review` |
| `document-review.md` | Multi-lens evaluation with gate assessment | `/seed-document-review` |
| `acceptance-testing.md` | ATDD test-first workflow | `/seed-acceptance-testing` |
| `pr-merge.md` | PR-based squash-merge procedure | `/seed-pr-merge` |

**Deployment:** Skills are symlinked from `skills/` into `.claude/commands/`, enabling native `/slash-command` invocation in Claude Code. Multi-model rigs also deploy to `.gemini/` and `.agents/` via build scripts.

**Validation:** Skills are validated before deployment using the Superpowers methodology — red test (observe failure without skill), green test (verify skill corrects failure), adversarial test (probe for rationalization), regression test (verify no over-correction). See `docs/validation.md`.

### Layer 2: Formulas

Formulas are TOML workflow templates that define the process skeleton — what steps happen, in what order, with what dependencies and gates. A formula says "design before implement, test before merge, human approval before architecture decisions proceed." Formulas reference skills by name but contain none of the skill content.

**What lives here:** Step sequencing, dependency graphs, human gates, checklist references, variable slots. The shape of the workflow.

**What doesn't live here:** How to execute each step (Layer 1), or what specific commands to run (Layer 3). A formula step says `per /seed-testing`, not `run go test ./...`.

**Current formulas (8):**

| Formula | Type | Steps | Use Case |
|---------|------|-------|----------|
| `trivial` | workflow | 2 | Config changes, typo fixes, obvious fixes |
| `standard-feature` | workflow | 5 | Well-scoped features with review gate |
| `shiny` | workflow | 6 | Design-first features (design before code) |
| `consult` | workflow | 3 | Investigation producing design document |
| `architecture` | workflow | 9 | Architecture decisions with human gates |
| `design-pipeline` | workflow | 9 | Multi-phase design with review convoy |
| `document-review` | convoy | 11 legs | Parallel multi-lens document review |
| `tea` | aspect | 2 advice | Test-first (ATDD) cross-cutting concern |

**Composition:** Formulas support `extends` (inherit steps), `compose.aspects` (weave cross-cutting concerns), and `compose.expand` (replace a step with sub-steps or a convoy). See [Formula Authoring Guide](formula-authoring.md) for full details.

### Layer 3: Rig Config

Rig config is a JSON file at `<rig>/settings/config.json` that declares a rig's project-specific tooling. It bridges the gap between universal formulas and project-specific reality.

**What lives here:** The concrete commands for testing, linting, type-checking, building, and setup. The default formula for the rig. Merge queue behavior.

**What doesn't live here:** How to think about testing (Layer 1), or the sequence of steps in a workflow (Layer 2).

**The 5 command variables:**

| Variable | JSON key | Example |
|----------|----------|---------|
| `setup_command` | `merge_queue.setup_command` | `pnpm install` |
| `typecheck_command` | `merge_queue.typecheck_command` | `tsc --noEmit` |
| `lint_command` | `merge_queue.lint_command` | `eslint . && shellcheck hooks/**/*.sh` |
| `test_command` | `merge_queue.test_command` | `bash tests/cook-all-formulas.sh` |
| `build_command` | `merge_queue.build_command` | `go build ./...` |

These values are **agent directions**, not blind exec targets. When a polecat reaches a test step, the formula tells it to run the configured command as the minimum quality gate. The agent applies its `/seed-testing` skill judgment on top of this baseline — it can add tests, investigate failures, and make decisions about what to fix.

---

## Layer Boundaries

The three-layer model works because each layer has clear boundaries. When content lands in the wrong layer, the system degrades.

### Skills never contain rig-specific commands

A skill says "write unit tests for new code, integration tests for boundary changes, run the full test suite." It does NOT say "run `go test ./...`" or "run `pytest -v`". The moment a skill contains a rig-specific command, it stops being universal. Every rig that doesn't use that command gets wrong guidance.

**Test:** If removing all mention of a specific language, framework, or tool from a skill makes it meaningless, the skill has bled into Layer 3 territory.

### Formulas reference skills, not commands

A formula step says `per /seed-testing`, not `run {{test_command}}`. The formula defines *what* happens (testing) and *when* (after implementation). The skill defines *how* (methodology, coverage expectations, red flags). The rig config defines *what tool* (the actual command).

The formula step's `description` field does include `{{test_command}}` in the operational context (so the polecat knows what to run), but the step's purpose is defined by the skill reference, not the command.

**Test:** If you could swap `/seed-testing` for a different skill and the formula still makes structural sense, the boundary is clean. The formula doesn't care *how* testing works — only that testing happens at this point.

### Rig config values are directions, not scripts

The `test_command` field doesn't contain a comprehensive test script. It contains the minimum quality gate command — the baseline the agent should run. The agent, guided by its `/seed-testing` skill, may do more: add missing tests, investigate flaky failures, run additional suites.

**Test:** If a config value requires no agent judgment to execute (just run it blindly), it's a well-formed direction. If it requires complex conditional logic, it's doing too much — move the judgment to the skill.

### Boundary summary

| Content | Correct Layer | Wrong Layer |
|---------|--------------|-------------|
| "Check for error handling, edge cases, API contract" | Skill | Formula description |
| "Test step depends on implement step" | Formula | Skill |
| `bash tests/cook-all-formulas.sh` | Rig config | Formula or skill |
| "Run test suite, fix regressions" | Formula description | Rig config |
| "Evaluate severity: BLOCK for bugs, SHOULD for style" | Skill | Formula or rig config |
| `pnpm install` | Rig config | Anywhere else |

---

## How a Rig Adopts the Pattern

A new rig gets the three-layer system working by creating one file and verifying one directory.

### Step 1: Create `settings/config.json`

Every rig that wants formulas to execute its tooling needs a config file at `<rig>/settings/config.json`:

```json
{
  "type": "rig-settings",
  "version": 1,
  "merge_queue": {
    "enabled": true,
    "test_command": "<your test command>",
    "setup_command": "<dependency install, or empty>",
    "lint_command": "<linting, or empty>",
    "typecheck_command": "<type checking, or empty>",
    "build_command": "<build step, or empty>",
    "run_tests": true,
    "delete_merged_branches": true
  },
  "workflow": {
    "default_formula": "standard-feature"
  }
}
```

**The "empty = skip" convention:** Only configure what applies. A Python project with no build step sets `build_command` to `""`. The formula will skip build-related instructions silently. There's no penalty for empty fields — they mean "not applicable to this rig."

**Location:** `~/gt/<rig-name>/settings/config.json`. This is a runtime file, not version-controlled. It lives alongside the rig's worktree but outside git.

### Step 2: Verify skill symlinks

Keeper skills are injected into a rig's working directory via symlinks in `.claude/commands/`. When a polecat enters a rig, it sees:

```
<rig>/.claude/commands/
├── research.md → ~/gt/keeper/skills/seed-research.md
├── implementation.md → ~/gt/keeper/skills/seed-implementation.md
├── testing.md → ~/gt/keeper/skills/seed-testing.md
├── code-review.md → ~/gt/keeper/skills/seed-code-review.md
├── document-review.md → ~/gt/keeper/skills/seed-document-review.md
├── acceptance-testing.md → ~/gt/keeper/skills/seed-acceptance-testing.md
├── pr-merge.md → ~/gt/keeper/skills/seed-pr-merge.md
└── handoff.md → (standalone command)
```

These symlinks enable `/skill-name` invocation in Claude Code. The skill content comes from keeper; the rig just needs the symlink directory.

### Step 3: Choose a default formula

Set `workflow.default_formula` in the config. This determines which formula is used when the dispatcher doesn't specify one. Common choices:

| Rig type | Recommended default | Why |
|----------|-------------------|-----|
| Active project codebase | `standard-feature` | Most work is well-scoped features |
| Infrastructure/ops rig | `standard-feature` | Same — config changes use `trivial` override |
| Design-heavy project | `shiny` | Front-loads design before implementation |

### What the polecat sees

When a polecat is dispatched into a rig, it operates within all three layers simultaneously:

- **Skills** arrive via `.claude/commands/` symlinks — the polecat invokes `/seed-testing`, `/seed-implementation`, etc.
- **Formulas** arrive via the dispatched molecule — the polecat follows steps from `bd mol current`
- **Rig config** arrives via variable injection — the molecule's step descriptions contain the rig's actual commands

The polecat doesn't need to know about the three-layer model. It just follows its molecule steps, which reference skills, which guide how it uses the rig's configured commands.

### Fail/warn behavior

| Condition | What happens |
|-----------|-------------|
| `config.json` missing entirely | Pre-dispatch hook warns to stderr. Dispatch proceeds. All command variables resolve to empty string. |
| Specific `*_command` field is empty | Formula step skips silently. Empty means "not configured for this rig." |
| `config.json` has invalid schema | `LoadRigSettings()` returns error. Dispatch may fail. |

---

## End-to-End Walkthrough

Trace a polecat dispatch from sling to step execution, showing how each layer contributes at each stage.

### Scenario: A `standard-feature` dispatch for keeper

A bug is filed: "Formula cook test fails on architecture.formula.toml." The crew triages it as `review` → `standard-feature` formula.

#### 1. Dispatch (sling)

The crew runs `gt sling <bead-id> <rig>`. Gas Town:

1. Reads `<rig>/settings/config.json` via `loadRigCommandVars()`
2. Extracts command variables: `test_command="bash tests/cook-all-formulas.sh"`, all others empty
3. Cooks the `standard-feature` formula into a protomolecule
4. Pours the protomolecule with variables: `bd mol pour --var issue=<id> --var test_command="bash tests/cook-all-formulas.sh" ...`
5. The molecule instantiates — 5 steps become real beads with variable-substituted descriptions
6. Wraps the formula molecule inside `mol-polecat-work` (the outer molecule providing branch setup, pre-flight, commit, review, submit steps)
7. Assigns the molecule to a polecat

**Layer 3 contributes:** The rig's `test_command` is injected into the molecule.

#### 2. Polecat starts (hook)

The polecat runs `gt hook`, finds the molecule. Runs `bd mol current`, sees the first ready step.

#### 3. Spec check step

The polecat reads the bead spec and confirms understanding. No skill reference — this is a lightweight checkpoint.

**No layer contributes beyond the formula's step definition.**

#### 4. Implement step

Step description says: `Implement the feature per /seed-implementation.`

The polecat invokes `/seed-implementation`, which loads `skills/seed-implementation.md`. The skill guides the polecat through: read the spec completely, read existing code patterns, plan changes, implement incrementally, stay in scope, verify against spec.

**Layer 1 contributes:** The `/seed-implementation` skill provides methodology. **Layer 2 contributes:** The formula placed implementation after spec-check.

#### 5. Test step

Step description says: `Write and run tests per /seed-testing.`

The polecat invokes `/seed-testing`. The skill guides test writing methodology. The molecule's context includes `test_command="bash tests/cook-all-formulas.sh"` — the polecat runs this as the minimum quality gate, then applies skill judgment on top (adding tests for the specific fix, checking edge cases).

**All three layers contribute:**
- **Layer 1 (Skill):** `/seed-testing` provides methodology — what kinds of tests to write, how to evaluate coverage, red flags for inadequate testing
- **Layer 2 (Formula):** Placed testing after implementation, references the checklist `tests-pass`
- **Layer 3 (Rig config):** Provided `test_command` — the concrete command to execute

#### 6. Review step (human gate)

Step description says: `Review the implementation per /seed-code-review. Create PR. This is a human gate.`

The polecat creates a PR, invokes `/seed-code-review` for self-review, then escalates. A human reviews and approves. The molecule's human gate blocks further progress until approval.

**Layer 1 contributes:** `/seed-code-review` skill defines review methodology. **Layer 2 contributes:** The formula encoded this as a human gate (`gate = { type = "human" }`).

#### 7. Merge step

Step description says: `Merge per /seed-pr-merge.`

The polecat follows the `/seed-pr-merge` skill to squash-merge the PR.

**Layer 1 contributes:** `/seed-pr-merge` skill. **Layer 2 contributes:** Sequencing (merge requires review).

#### Summary of layer contributions

| Step | Layer 1 (Skill) | Layer 2 (Formula) | Layer 3 (Config) |
|------|-----------------|-------------------|------------------|
| Spec check | — | Step definition | — |
| Implement | `/seed-implementation` | Sequencing, checklist | — |
| Test | `/seed-testing` | Sequencing, checklist | `test_command` |
| Review | `/seed-code-review` | Human gate | — |
| Merge | `/seed-pr-merge` | Sequencing, checklist | — |

---

## The `mol-polecat-work` Bridge

Every polecat dispatch is wrapped in `mol-polecat-work` — a system-level molecule defined in Gas Town (not in keeper). This outer molecule provides the operational steps that surround the formula's domain steps:

```
mol-polecat-work (Gas Town system molecule)
├── Load context and verify assignment
├── Set up working branch
├── Verify pre-flights pass on base branch
│   └── Uses: setup_command, typecheck_command, lint_command, test_command
├── ┌──────────────────────────────────┐
│   │  Formula steps (from keeper)     │
│   │  e.g., standard-feature:        │
│   │    spec-check → implement → test │
│   │    → review → merge              │
│   └──────────────────────────────────┘
├── Commit all implementation changes
├── Run quality checks and tests
│   └── Uses: typecheck_command, lint_command, test_command, build_command
├── Self-review changes
├── Prepare work for review
├── Submit work and self-clean
└── Clean up workspace
```

The 7 variables that `mol-polecat-work` provides to formula steps:

| Variable | Source | Description |
|----------|--------|-------------|
| `issue` | Hook bead | The assigned issue ID |
| `base_branch` | Sling vars | Branch to rebase on (default: `main`) |
| `setup_command` | Rig config | Dependency install (e.g., `pnpm install`) |
| `typecheck_command` | Rig config | Type checking (e.g., `tsc --noEmit`) |
| `lint_command` | Rig config | Linting (e.g., `eslint .`) |
| `test_command` | Rig config | Test execution |
| `build_command` | Rig config | Build step (e.g., `go build ./...`) |

**Variable injection order:** Rig config is injected first, then user `--var` flags override. A dispatch with `--var test_command="custom"` overrides the rig default.

**Empty command convention:** When a command variable is empty, `mol-polecat-work` steps that reference it skip silently. The step instructions use phrasing like "If typecheck_command is set: `{{typecheck_command}}`" — the polecat evaluates the condition and skips if empty.

---

## Known Limitations

### Only 5 command variables

Gas Town currently supports 5 command variables from rig config: `setup_command`, `typecheck_command`, `lint_command`, `test_command`, `build_command`. Anything outside this set (deploy commands, migration scripts, custom quality gates) must be handled by the agent at runtime using skill judgment or bead-level instructions.

### Commands baked at pour time

Command variables are substituted when the molecule is poured (instantiated). They're static for the molecule's lifetime. If a rig's `test_command` changes mid-execution, in-flight molecules still use the old value.

### Skills remain advisory

Skills guide agent behavior through detailed instructions and red flags, but there's no structural enforcement that an agent actually follows a skill's methodology. The agent could skip the skill invocation entirely. ks-wr884 (session-start hooks) represents the first step toward structural skill enforcement — injecting skill references into agent context at session start.

### Pre-commit checks outside the 5 variables

Some quality checks don't fit the 5 command variables — for example, commit message format validation, file size limits, or secret scanning. These currently rely on git hooks or CI, not the three-layer system.

### Convoy type workaround

Convoy formulas (like `document-review`) must use `type = "workflow"` with `[[legs]]` structure until `bd` adds convoy as a valid formula type. The semantics are correct; the type field is a workaround.

---

## Architectural Principles

These principles govern how the three layers interact and evolve.

**Formulas define what and when. Skills define how.** Keep them separate. A formula step should fit on one line. A skill can be as long as it needs to be.

**Rig config is the thinnest layer.** It should contain only what varies between rigs — tooling commands and merge behavior. Process logic (formulas) and execution knowledge (skills) are shared.

**Empty means skip, not fail.** The "empty = skip" convention lets a single formula work across rigs with different tooling. A rig without type checking leaves `typecheck_command` empty; the formula skips the type check step silently. No special-casing required.

**Skills evolve through the retro system.** Post-completion hooks file `ks` beads when actionable patterns emerge. Linked-bead counts on existing issues surface frequency. High-frequency issues become skill improvements, validated through red-green-adversarial testing.

**Structural enforcement over advisory guidance.** Where Gas Town provides structural mechanisms (bead dependencies, blocked states, human gates), use them. Where enforcement must be instructional, use skills with explicit red flags and rationalization counters.

---

## Reference Material

### Prior research that informed this architecture

| Source | Bead | What it contributed |
|--------|------|-------------------|
| Gas Town rig config mechanism verification | ks-on7br | Confirmed `settings/config.json` → `loadRigCommandVars()` → formula vars works end-to-end |
| Three-layer decision record | ks-lzsrz | Decision to populate config using existing mechanism, not redesign |
| Prior art survey (8 systems compared) | polecat/furiosa (0b23856) | Validated that separating process from config is universal industry pattern |
| Three-layer current state mapping | polecat/slit (98b5114) | End-to-end variable resolution trace, three options with comparison matrix |
| Validation review | ks-fiy4n | Three-lens review identifying gaps in the decision record |

### Key files

| File | What it contains |
|------|-----------------|
| `formulas/*.formula.toml` | All 8 workflow templates |
| `skills/*.md` | All 7 execution skills |
| `checklists/*.md` | 17 binary gate criteria |
| `settings/config.json` | Keeper's own rig config |
| `hooks/pre-dispatch/` | Pre-dispatch enforcement |
| `hooks/post-completion/` | Post-completion observation and retro bead filing |
| `docs/formula-authoring.md` | Complete formula reference (variables, types, lifecycle, composition) |
| `docs/conventions.md` | Naming, format, and structure rules |
| `docs/validation.md` | Superpowers testing methodology for skill validation |
| `docs/design/` | Bead-prefixed design artifacts, review outputs, and synthesis docs |

### Full rig config schema

From Gas Town's `config/types.go`:

```json
{
  "type": "rig-settings",
  "version": 1,
  "merge_queue": {
    "enabled": true,
    "test_command": "...",
    "setup_command": "...",
    "lint_command": "...",
    "typecheck_command": "...",
    "build_command": "...",
    "on_conflict": "assign_back",
    "run_tests": true,
    "delete_merged_branches": true,
    "retry_flaky_tests": 1,
    "poll_interval": "30s",
    "max_concurrent": 1,
    "integration_branch_polecat_enabled": true,
    "integration_branch_refinery_enabled": true,
    "integration_branch_template": "integration/{title}",
    "integration_branch_auto_land": false
  },
  "workflow": {
    "default_formula": "standard-feature"
  },
  "agent": "claude-miller",
  "agents": {},
  "role_agents": {},
  "theme": {},
  "namepool": {},
  "crew": {}
}
```

Fields relevant to the three-layer model are in `merge_queue` (command variables) and `workflow` (default formula). Other fields configure Gas Town's agent management, UI, and rig behavior — they're documented in Gas Town's reference docs.
