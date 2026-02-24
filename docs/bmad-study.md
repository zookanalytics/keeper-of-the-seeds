# BMAD-METHOD Study: Deep Dive

Study of https://github.com/bmad-code-org/BMAD-METHOD for keeper adoption.
Bead: ks-n8z4

## Repo Overview

BMAD-METHOD (37k+ stars) is a multi-agent workflow framework organized into modules:

```
src/
├── core/           # Shared infrastructure (workflow engine, party mode, utilities)
├── bmm/            # BMad Method (agile dev: analyst → architect → pm → sm → dev)
└── utility/
    └── agent-components/  # Reusable agent building primitives
```

Related: `github.com/bmad-code-org/bmad-builder` — separate npm module for creating custom agents/workflows.

---

## Part 1: Party Mode (Multi-Agent Collaboration in One Session)

### What It Is

Party mode loads a roster of all available agents and simulates multi-expert collaborative discussion within a **single LLM context window**. The LLM orchestrates between agent personas, selecting 2-3 agents per response round based on topic relevance.

### File Structure

```
src/core/workflows/party-mode/
├── workflow.md                           # Entry point / orchestrator definition
└── steps/
    ├── step-01-agent-loading.md          # Loads agent manifest, builds roster
    ├── step-02-discussion-orchestration.md   # Manages conversation rounds
    └── step-03-graceful-exit.md          # Farewell and session close
```

Teams enable party mode via their YAML config:
```yaml
# src/bmm/teams/team-fullstack.yaml
bundle:
  name: Team Plan and Architect
  agents: [analyst, architect, pm, sm, ux-designer]
party: "./default-party.csv"
```

### How It Works

**Step 1 - Agent Loading**: Reads `_bmad/_config/agent-manifest.csv` with fields:
```
name, displayName, title, icon, role, identity, communicationStyle, principles, module, path
```
All persona data is loaded into working memory. A hard gate blocks until loading is complete:
> "FORBIDDEN to start conversation until all agents are loaded"

Frontmatter is written after completion:
```
stepsCompleted: [1]
agents_loaded: true
party_active: true
```

**Step 2 - Discussion Orchestration**: Per user message, the LLM selects 2-3 agents:
- **Primary**: best expertise match for the core topic
- **Secondary**: complementary perspective
- **Tertiary**: cross-domain or devil's advocate (if beneficial)
- If user names a specific agent by name, that agent is prioritized

Response format per agent:
```
[Icon Emoji] **[Agent Name]**: [Authentic in-character response]
```

Cross-talk patterns (agents reference each other):
- "As [Another Agent] mentioned..."
- "I see it differently than [Another Agent]..."
- Follow-up questions between agents within the same round

**Pause protocol**: When any agent asks the user a direct question, the round ends immediately with `[Awaiting user response...]`.

### Critical Insight: Party Mode is Pure Prompt Engineering

There is **no inter-process communication, no shared memory outside the context window, no IPC**. Party mode works entirely within a single LLM session:

1. All agent persona data is injected into the system context at session start
2. The LLM plays all roles simultaneously, simulating perspectives from persona definitions
3. "Collaboration" = the LLM juggling multiple in-character voices guided by persona data

**Implication for keeper**: Party mode cannot be implemented across separate polecats or sessions. It only applies to single-session multi-perspective tasks. The keeper analog would be a "council" formula step where one agent embodies multiple reviewer personas sequentially (similar to what keeper already does in review convoys but as a single-pass multi-voice step).

### Exit Triggers

`*exit`, `goodbye`, `end party`, `quit`, or user selects `[E]`.

---

## Part 2: Agent Persona YAML Definitions

### File Naming

All agents use `*.agent.yaml` naming under `src/<module>/agents/`. Runtime installed at `_bmad/<module>/agents/*.md`.

### Complete Schema

```yaml
agent:
  webskip: true                    # Optional: skip in web-mode deployments

  metadata:
    id: "_bmad/bmm/agents/pm.md"   # Runtime install path
    name: John                     # Display name
    title: Product Manager         # Role title
    icon: 📋                       # Emoji icon
    module: bmm                    # Module membership
    capabilities: "PRD creation, requirements discovery, ..."  # Capability summary
    hasSidecar: false              # Whether agent has persistent memory folder

  persona:
    role: "..."           # WHAT: expertise domain only, no personality
    identity: "..."       # WHO: personality, worldview, no job function
    communication_style: "..."  # HOW: tone, formality, no expertise references
    principles: |         # WHY: Principle 1 MUST be an "expert activator"
      - Activate expert thinking: draw upon deep knowledge of [domain]...
      - Operational principle
      - ...

  critical_actions:        # Optional: high-priority actions always executed
    - "Always verify X before proceeding"

  discussion: true         # Optional: enables party-mode capability
  conversational_knowledge:  # Optional: knowledge loaded in party mode
    - domain: "{project-root}/_bmad/module/docs/kb.csv"

  memories: []             # Persistent context/preferences across sessions

  menu:
    - trigger: "CP or fuzzy match on create-prd"
      exec: "{project-root}/_bmad/bmm/workflows/.../workflow.md"
      description: "[CP] Create PRD: ..."

    - trigger: "CA or fuzzy match on create-architecture"
      workflow: "{project-root}/_bmad/bmm/workflows/.../workflow.yaml"
      description: "[CA] Create Architecture: ..."

    - trigger: "inline action"
      action: "perform this action directly"
      description: "..."

  prompts:                 # Reusable named templates
    - id: "template-name"
      content: "..."

  install:                 # Optional compile-time setup questions
    - prompt: "Question text"
      type: text | dropdown
      default: "value"
      result: "{variable-name}"
```

### The Four-Field Persona Purity System

The persona is enforced to have strict field separation with **no cross-contamination**:

| Field | Contains | FORBIDDEN |
|-------|----------|-----------|
| `role` | Expertise domain, what agent does professionally | Personality traits |
| `identity` | Character, personality, worldview | Job function, capabilities |
| `communication_style` | Tone, formality, linguistic patterns | Expertise references |
| `principles` | Motivations, heuristics; P1 MUST be "expert activator" | Procedural steps |

**Expert activator pattern** (Principle 1): "Channel expert [X] thinking: draw upon deep knowledge of [specific frameworks/methods]..." This pattern is validated and enforced — it's what causes the LLM to adopt expert-level reasoning rather than surface-level responses.

### Menu Handler Types

Five handler types for menu items:

| Handler | Syntax | Behavior |
|---------|--------|----------|
| `exec` | `exec: "path/to/file.md"` | Load file fully, follow all instructions as prose |
| `workflow` | `workflow: "path/to/workflow.yaml"` | Load yaml config into workflow.xml execution engine |
| `action` | `action: "do this"` | Inline direct action, no file |
| `validate-workflow` | `validate-workflow: "path"` | Load validate-workflow.xml engine |
| Multi | `type: multi` with sub-handlers | Nested menu item with sub-routing |

### Activation Protocol

When agent YAML is loaded, LLM follows these steps (blocking):
1. Load agent file context
2. Read `config.yaml` — extract `user_name`, `communication_language`, `output_folder` (BLOCKING: must succeed)
3. Greet user by name in configured language
4. Display numbered menu
5. Inform about `/bmad-help` availability
6. Wait for user input — NO auto-execution
7. Accept: numeric, text substring (case-insensitive), or clarification
8. Execute handler for matched menu item

### Concrete Example: PM Agent

```yaml
persona:
  role: Product Manager specializing in collaborative PRD creation through user interviews,
        requirement discovery, and stakeholder alignment.
  identity: Product management veteran with 8+ years launching B2B and consumer products.
            Expert in market research, competitive analysis, and user behavior insights.
  communication_style: "Asks 'WHY?' relentlessly like a detective on a case.
                        Direct and data-sharp, cuts through fluff to what actually matters."
  principles: |
    - Channel expert product manager thinking: draw upon deep knowledge of user-centered
      design, Jobs-to-be-Done framework, opportunity scoring, and what separates great
      products from mediocre ones
    - PRDs emerge from user interviews, not template filling — discover what users need
    - Ship the smallest thing that validates the assumption — iteration over perfection
    - Technical feasibility is a constraint, not the driver — user value first
```

**Takeaway for keeper**: The persona YAML format maps well to how keeper skills are written. The "expert activator" principle pattern is the key mechanism that produces high-quality agent behavior. Keeper's skill frontmatter descriptions already follow a similar "Use when X" pattern, but the principle-as-expert-activator approach is worth adopting explicitly.

---

## Part 3: Phase-Gate Mechanisms

### Architecture: Five Gate Layers

1. **Workflow engine gates** — `workflow.xml` execution engine enforces step ordering
2. **Step prerequisites** — Each step validates required artifacts exist before beginning
3. **`[C] Continue` user gates** — Explicit confirmation required at every phase boundary
4. **Quality checklists** — READY/NOT READY binary status per criterion
5. **DoD (Definition of Done) checklists** — Attached to workflows as `checklist.md`

### The `[C] Continue` Universal Gate

The most pervasive pattern: after completing any meaningful step, the agent presents findings and shows `[C] Continue` as the explicit progression trigger. **Never auto-advance.**

Three mandatory stop points in `workflow.xml`:
- **`template-output` gate**: "NEVER proceed until the user indicates to proceed" (bypass with `#yolo`)
- **`ask` tag gate**: "ALWAYS wait for response before continuing"
- **Step completion**: "Continue to next step? (y/n/edit)"

Override: `#yolo` mode skips all confirmations and simulates expert user responses automatically.

### Phase Gate: Implementation Readiness Check

The primary cross-phase gate between Solutioning (Phase 3) and Implementation (Phase 4):

```
step-01-document-discovery.md     # Locate PRD, Architecture, Epics, UX Design
step-02-prd-analysis.md           # Extract all FRs and NFRs
step-03-epic-coverage-validation.md
step-04-ux-alignment.md
step-05-epic-quality-review.md    # BDD format, independence, forward deps
step-06-final-assessment.md       # Issues READY / NEEDS WORK / NOT READY
```

Step 5 quality criteria:
- Epics must have user-centric titles (reject: "Setup Database")
- Epics must be independently completable (no future-epic dependencies)
- Acceptance criteria must use BDD: Given/When/Then
- Violations classified: **Critical / Major / Minor**

Step 6 output: `implementation-readiness-report-{{date}}.md`
Status: `READY` | `NEEDS WORK` | `NOT READY`

### READY/NOT READY Binary Vocabulary

BMAD gates use binary status per criterion — not qualitative scoring:

```
FR Coverage:
  READY:     Every FR appears in at least one story
  NOT READY: Any FR lacks story coverage

Story Quality:
  READY:     Each story completable by single developer
  READY:     Clear acceptance criteria present
  NOT READY: Story awaits future story completion

Dependency Validation (CRITICAL):
  READY:     Each epic independently functional
  NOT READY: Epic requires future epic features
  NOT READY: Circular or backward dependencies detected
```

**Key pattern**: Binary per-criterion makes gate state machine-readable. The LLM evaluates each criterion independently and produces an unambiguous verdict.

### Definition of Done Checklist Pattern

`checklist.md` files attached to workflows define the gate before status transitions:

```
dev-story/checklist.md gate before "review" transition:
- Context: dev notes contain technical requirements, architecture patterns
- Implementation: all tasks complete, acceptance criteria satisfied, edge cases handled
- Quality: unit + integration + e2e test coverage, tests address AC, edge cases, regressions
- Documentation: every modified/new file logged, dev agent notes recorded
- Status: transitions to "review" ONLY after all gates pass with no blocking issues
```

### Frontmatter State Tracking

Output documents carry frontmatter tracking phase progress:
```
stepsCompleted: [1, 2, 3]
agents_loaded: true
inputDocuments: [prd.md, architecture.md]
```

This allows resuming mid-workflow without re-doing completed steps.

### Takeaway for Keeper

Keeper's `gate = { type = "human" }` in formulas is the direct equivalent of BMAD's `[C] Continue` gate. Key BMAD additions that keeper lacks:

1. **Binary READY/NOT READY vocabulary** — keeper quality checks use prose; BMAD uses explicit binary status per criterion. More machine-readable.
2. **Checklist.md pattern** — separate file attached to formula step, defines DoD criteria. Keeper currently embeds criteria in gate steps.
3. **#yolo override** — bypass mode for automated testing. Keeper has no equivalent.
4. **Per-step frontmatter** — state written to document after each `[C]`. Keeper tracks state in beads (mol steps), not output documents.

---

## Part 4: BMad Builder Module

### What It Is

BMad Builder is a separate npm module (`bmad-builder`, code: `bmb`) at `github.com/bmad-code-org/bmad-builder`. Not included in default BMAD installation. Provides specialized agents and workflows for creating new BMAD content.

```yaml
# From external-official-modules.yaml
bmad-builder:
  url: https://github.com/bmad-code-org/bmad-builder
  module-definition: src/module.yaml
  code: bmb
  name: "BMad Builder"
  description: "Agent, Workflow and Module Builder"
  defaultSelected: false
  type: bmad-org
  npmPackage: bmad-builder
```

Custom creations output to: `_bmad-output/bmb-creations/` by default.

### Three Builder Agents

| Agent | Persona | Builds |
|-------|---------|--------|
| Bond 🤖 | Agent Building Expert | New agent YAML files |
| Wendy 🔄 | Workflow Building Master | Workflow YAML/MD files |
| Morgan 🏗️ | Module Creation Master | Complete BMAD modules |

All three have `discussion: true` — they support party mode for collaborative ideation during creation.

### Create-Agent Workflow (Bond)

The agent creation workflow uses step-file architecture:

```
workflow-create-agent.md    # Entry point
steps-c/
  step-01-brainstorm.md     # Optional ideation; supports Party Mode invocation
  step-02-discovery.md      # Comprehensive single capture step
  step-03-sidecar-metadata.md  # Determines hasSidecar: true/false
  step-04-persona.md        # Builds 4-field persona with purity enforcement
  step-05-commands-menu.md  # Designs trigger codes and menu structure
  step-06-activation.md     # Configures activation rules
  step-07-build-agent.md    # Assembles final YAML from plan
  step-08-celebrate.md      # Completion
templates/
  agent-plan.template.md    # Intermediate plan document
  agent-template.md         # Handlebars YAML template for final output
```

**Step 2 Design Principle**: "This is the only discovery step. Capture everything now." Covers: problem domain, success metrics, capabilities, deployment context, target user profiles. Out of scope: implementation details, exact persona traits, command structures.

**Step 4 Persona Purity Enforcement**: The builder explicitly validates cross-field contamination:
- Runs purity check after draft
- Flags any `role` text that contains personality traits
- Flags any `identity` text that mentions job function
- Requires revision before continuing

**Output paths**:
- `hasSidecar: false` → Single YAML file (~250 lines)
- `hasSidecar: true` → YAML file + persistent memory sidecar folder

### Validation System

Each builder agent includes a validate command (`VA`, `VW`, `VM`). Schema validation enforces:
- Required metadata fields: `id`, `name`, `title`, `icon`, `hasSidecar`
- Trigger format: kebab-case, no duplicates within agent
- Each menu item must have exactly one command target type
- When `discussion: true`, `conversational_knowledge` is recommended

### Takeaway for Keeper

BMAD Builder is a high-investment workflow for teams that will create many custom agents. For keeper's current scale (handful of polecats, formulas, skills), the main value is the **creation patterns** it encodes, not the tool itself.

Keeper analogs:
- Keeper's skills are simpler than BMAD agents (no menu system, no YAML)
- The "expert activator" principle pattern is directly adoptable
- The step-file architecture for builder workflows matches keeper's formula structure

---

## Cross-Cutting Patterns and Keeper Implications

### Pattern 1: Step-File Architecture

Every BMAD workflow decomposes into numbered sequential step files. Each step is fully self-contained with explicit entry criteria, work scope, and exit criteria. `workflow.md` is a lightweight entry point delegating to steps.

**Keeper current**: formula TOML with `[[steps]]` blocks. Similar but inline. For long workflows, extracting to step files would improve readability.

### Pattern 2: `{project-root}` Variable Interpolation

All file references use runtime variables resolved at session start. Makes the entire system relocatable.

**Keeper current**: Uses `~/gt/` paths in some places. The `{project-root}` pattern is worth adopting for any future relocatable components.

### Pattern 3: Two-Mode Instruction Execution

`exec` (load .md, follow as prose) vs `workflow` (load .yaml, process with declarative engine). The distinction maps exactly to keeper's skill references vs formula steps:
- `skill:research` = exec mode (prose instructions in a file)
- Formula `[[steps]]` = workflow mode (declarative structure processed by mol engine)

### Pattern 4: Party Mode as Single-LLM Multi-Persona

Not a multi-process or multi-session pattern. Party mode = multiple agent personas loaded into one context, LLM simulates all of them.

**Keeper implication**: The keeper "review convoy" pattern (multiple reviewers, one per session) differs from BMAD party mode. Both approaches have merit. Keeper's multi-session convoy produces independent reviews (no anchoring bias). BMAD's single-session party allows agents to build on each other in real-time.

### Pattern 5: Binary Gate Vocabulary

BMAD gates use explicit `READY` / `NOT READY` / `NEEDS WORK` per criterion. This is more machine-readable than keeper's current prose-based gate descriptions.

**Adoption opportunity**: Keeper quality checklists in skills (research.md, code-review.md) could adopt binary per-criterion format for clearer output.

---

## Open Questions for Keeper

1. **Party mode analog**: Should keeper have a "council step" formula primitive where a single polecat embodies 2-3 reviewer personas simultaneously? Faster than convoy but with anchoring risk.

2. **Expert activator pattern**: Should keeper skill `principles` sections adopt the explicit "activate expert X thinking: draw upon knowledge of [frameworks]..." pattern from BMAD? This is the key mechanism behind BMAD's high-quality output.

3. **Binary gate vocabulary**: Should keeper refactor quality checklists to use explicit READY/NOT READY per criterion? Reduces ambiguity in polecat-generated review outputs.

4. **Checklist.md attachment pattern**: Should keeper formulas reference external checklist files for DoD criteria rather than embedding them inline? Allows checklist reuse across formulas.

5. **#yolo equivalent**: Should keeper add a `GT_AUTO_CONFIRM=true` bypass for automated test runs against formula workflows?
