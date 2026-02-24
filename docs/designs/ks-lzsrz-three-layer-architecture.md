# Architecture Review: Where Should Logic Live?

**Bead:** ks-lzsrz | **Date:** 2026-02-23
**Prior research:** polecat/slit (98b5114), polecat/furiosa (0b23856), polecat/nux (synthesis)

---

## Executive Summary

Gas Town operates across three conceptual layers — **skills** (universal execution knowledge), **formulas** (workflow process), and **rig config** (project-specific commands) — but the boundaries between them are tangled. Rig-specific concerns leak into formula templates, skills teach judgment but can't resolve to concrete commands, and no mechanism exists for rigs to declare their tooling. This caused a P1 production failure (ks-58cnr: `go test ./...` on a non-Go repo) and leaves test/lint/build steps silently skipped across all rigs.

Three options are evaluated. **Recommendation: Option A (extend current config) now, evolve toward Option C (structured manifest) as rig count grows.**

---

## The Three-Layer Model

| Layer | Contains | Example | Lives In |
|-------|----------|---------|----------|
| **1. Skills** | Universal execution knowledge — how to think about testing, code review judgment, research methodology | "Check coverage for edge cases, boundary conditions, error paths" | `keeper/skills/*.md` |
| **2. Formulas** | Workflow sequencing — what steps happen, in what order, with what gates | "Test after implement, human gate before merge" | `keeper/formulas/*.toml` |
| **3. Rig Config** | Project-specific commands and tooling — what concrete commands to run | `bash tests/cook-all-formulas.sh && shellcheck hooks/**/*.sh` | **Gap: nowhere today** |

### Current State

**Layer 1 (Skills):** Clean. All 7 keeper skills contain zero rig-specific commands. They teach *how to think about testing*, not *what command to run*. Injected via `.claude/commands/` symlinks to `skills/`.

**Layer 2 (Formulas):** Clean in keeper. Keeper's 8 formulas (`standard-feature`, `architecture`, etc.) reference only human-facing variables (`{{feature}}`, `{{topic}}`). However, Gas Town's built-in `mol-polecat-work` has Layer 3 variable slots (`test_command`, `build_command`, etc.) documented as "Source: rig config" — a mechanism that doesn't exist.

**Layer 3 (Rig Config):** Missing entirely. Keeper has no `settings/config.json`. All command variables default to empty string, causing test/lint/build steps to be silently skipped. The variable resolution pipeline exists in Gas Town's Go code (`loadRigCommandVars()`) but finds nothing to load.

---

## The Problem: Evidence

| Failure | Bead | Root Cause | Layer Violation |
|---------|------|-----------|-----------------|
| `go test ./...` on non-Go repo | ks-58cnr (P1, fixed) | Formula default had rig-specific command | Rig config leaked into formula |
| Refinery skips all tests | ks-4217r (P2, open) | `test_command` is empty — no rig config exists | Missing Layer 3 |
| OAuth push failures for .github/workflows | Referenced in ks-lzsrz | Polecat didn't know repo push requirements | Rig infra concern leaked into polecat scope |
| Polecats skip testing entirely | Pattern across dispatches | No rig config → empty commands → silent skip | Missing Layer 3 |
| Skills advisory not structural | ks-wr884 (P1, blocked) | No session-start hook to inject/enforce skills | Enforcement gap |

### End-to-End Trace: Polecat Hits "Test" Step Today

```
gt sling <bead-id> <rig>
  → sling_dispatch.go: executeSling()
    → loadRigCommandVars(townRoot, rigName)
      → Reads: <rig>/settings/config.json    ← FILE DOES NOT EXIST for keeper
      → Returns: []                           ← No variables injected
    → InstantiateFormulaOnBead(formulaName, ..., allVars)
      → bd mol pour: {{test_command}} → ""    ← Empty = skip
  → Polecat sees step description with empty command
  → Polecat skips testing entirely             ← SILENT FAILURE
```

**Result:** Every polecat dispatch in keeper skips all quality checks. The formula infrastructure works correctly — it just has nothing to work with.

---

## Prior Art Survey

| System | Config Resolution | Rig-Specific Mechanism |
|--------|-------------------|----------------------|
| **BMAD-METHOD** | Compile-time overlay (`*.customize.yaml`) | Module manifest + override files |
| **obra/superpowers** | Runtime shadowing (project > personal > core) | Project `.claude/skills/` shadows core skills |
| **Claude Code** | Hierarchical CLAUDE.md discovery | Repo-root config, recursive up tree |
| **OpenHands** | Three-tier microagents (global/user/workspace) | Workspace microagents always active |
| **Cursor** | Rule types with activation modes | File glob patterns, keyword triggers |
| **Devin** | Global vs repo-pinned knowledge | Auto-imports CLAUDE.md, .rules, etc. |
| **SWE-agent** | `EnvironmentConfig.post_startup_commands` | Per-repo setup commands |
| **CrewAI** | YAML config separation | Task-level tool overrides |

**Common pattern:** Every system separates process logic (what/when) from domain knowledge (how) from project config (what commands). The separation point differs — compile-time, pour-time, or runtime — but the three layers exist everywhere.

---

## Options

### Option A: Extend Current Config (Low effort, immediate)

Formalize the existing `settings/config.json` approach. Every rig gets a config file. Gas Town's `loadRigCommandVars()` already reads this at sling time.

**What changes:**
- Create `keeper/settings/config.json` with test_command
- Document the config schema for new rigs
- Add pre-dispatch validation warning when rig has no config
- Session-start hook (ks-wr884) nudges skill invocation

**Keeper config:**
```json
{
  "merge_queue": {
    "test_command": "bash tests/cook-all-formulas.sh && shellcheck hooks/**/*.sh",
    "setup_command": "",
    "build_command": "",
    "lint_command": "",
    "typecheck_command": ""
  }
}
```

| Pro | Con |
|-----|-----|
| Minimal changes — uses existing Go infrastructure | Commands baked at pour time (static) |
| `loadRigCommandVars()` already works end-to-end | Config locked inside `merge_queue` — poor naming for polecat work |
| No Go code changes needed | Single test_command per rig — can't vary per context |
| Easy to validate (hook checks for file existence) | Skills remain advisory — no structural skill enforcement |
| Trivial migration (just add files) | Schema additions require Go changes |

**Effort:** Hours. Create config files, document schema, add validation hook.

### Option B: Repo-Level Config + Skill Shadowing (Medium effort, runtime)

Move rig config into repo-native locations (`CLAUDE.md`). Skills become the resolution mechanism — `/testing` discovers and runs the right command rather than receiving a pre-baked variable. Adopt superpowers-style shadowing for project-specific skill overrides.

**What changes:**
- Each repo's CLAUDE.md includes a "Commands" section
- Formulas reference generic step names, not `{{test_command}}`
- Skills discover commands from repo config at runtime
- Project `.claude/commands/testing.md` can shadow keeper's version

**Skill shadowing hierarchy:**
1. Project repo `.claude/commands/` (repo-specific) — highest priority
2. Keeper `.claude/commands/` → `skills/` (universal) — fallback

| Pro | Con |
|-----|-----|
| Config lives where developers expect it (repo root) | LLM parses CLAUDE.md — less deterministic than JSON |
| Runtime discovery adapts to repo changes | Skills must handle "no command found" — more complex |
| Skill shadowing enables project-specific overrides | Breaking change: formulas with `{{test_command}}` need migration |
| Multi-model friendly (CLAUDE.md readable by any LLM) | Two sources of truth risk if both CLAUDE.md and config.json exist |
| Skills become structural (resolve commands, not just advise) | Agent may misinterpret CLAUDE.md commands section |

**Effort:** Days to weeks. Update formulas, rewrite skills with command discovery, update all rigs' CLAUDE.md, test shadowing in worktrees.

### Option C: Structured Rig Manifest (High effort, future-proof)

New `rig.toml` file per repo with rich schema: per-context commands, explicit skill overrides, context file declarations. Gas Town reads this at dispatch time. Purpose-built, not overloaded from `merge_queue`.

**What changes:**
- New `rig.toml` schema designed and documented
- Gas Town's `loadRigCommandVars()` expanded to read rig.toml
- Per-context commands (e.g., `test.quick` vs `test.thorough`)
- Skill overrides declared in manifest
- Session-start hook reads manifest for injection

**Example (keeper):**
```toml
[rig]
name = "keeper"
type = "operational"

[commands.test]
default = "bash tests/cook-all-formulas.sh && shellcheck hooks/**/*.sh"
quick = "bash tests/cook-all-formulas.sh"
thorough = "bash tests/cook-all-formulas.sh && shellcheck hooks/**/*.sh"

[context]
files = ["docs/conventions.md"]
```

**Example (TypeScript project):**
```toml
[rig]
name = "webapp"
type = "project"

[commands.setup]
default = "pnpm install"

[commands.test]
default = "pnpm test"
quick = "pnpm test --bail"
thorough = "pnpm test -- --coverage"

[commands.lint]
default = "pnpm lint"

[commands.typecheck]
default = "tsc --noEmit"

[commands.build]
default = "pnpm build"

[skills]
testing = ".claude/skills/testing.md"
```

| Pro | Con |
|-----|-----|
| Deterministic (structured data, not LLM parsing) | New file format to design and maintain |
| Per-context commands (quick vs thorough) | Requires Go changes to loadRigCommandVars() |
| Explicit skill override mechanism | Every rig needs a new file |
| Extensible schema | Schema design decisions become constraints |
| Session-start hook has structured data to work with | TOML parsing in shell hooks is non-trivial |

**Effort:** Days to weeks. Schema design, Go reader, rig.toml per rig, formula/skill updates, validation, documentation.

---

## Comparison Matrix

| Dimension | Option A | Option B | Option C |
|-----------|----------|----------|----------|
| **Determinism** | High (JSON → vars) | Low (LLM parses CLAUDE.md) | High (TOML → vars) |
| **Effort** | Low | Medium | High |
| **Flexibility** | Low (single command/concern) | High (runtime discovery) | High (per-context commands) |
| **Skill enforcement** | Advisory (hook nudge) | Structural (skills resolve) | Structural (hook + manifest) |
| **Multi-model** | Neutral | Good | Good |
| **Migration** | Trivial (add config files) | Breaking (rewrite formulas) | Medium (add rig.toml) |
| **Future-proofing** | Low (schema locked in Go) | Medium (conventions evolve) | High (extensible schema) |
| **Failure mode** | Silent skip (empty command) | Wrong command (LLM misparse) | Missing file (clear error) |

---

## Recommendation

**Option A now, evolve toward C when rig count demands it.**

### Rationale

1. **The immediate problem is trivial:** Keeper has no `settings/config.json`. Creating one takes minutes and immediately un-silences all quality check steps across every polecat dispatch.

2. **We lack the data for schema design:** Option C's `rig.toml` schema should emerge from real usage across multiple rigs. Designing it now, with only keeper as a reference, risks schema decisions that don't survive contact with actual project rigs.

3. **Option A unblocks three P1/P2 beads:** ks-wr884 (session-start hook), ks-5xgve (pre-merge hook), and ks-rqave (classification validator) are all blocked on this decision. Option A resolves the blocking question without requiring Go changes.

4. **No work is wasted:** Option A config files become seed data for Option C's `rig.toml` when the time comes. The migration path is: extract `merge_queue.*_command` values from config.json into rig.toml fields.

5. **Option B's insight is valuable regardless:** Skills should check CLAUDE.md as a fallback even with Option A. Update the testing skill to: (a) use the pre-baked `{{test_command}}` if set, (b) check repo CLAUDE.md for commands section as fallback, (c) inspect repo structure as last resort. This is additive, not breaking.

### Concrete Next Steps (if Option A approved)

1. **Create `keeper/settings/config.json`** with test_command
2. **Document the config schema** in `docs/conventions.md` (new "Rig Config" section)
3. **Add a "Repository Commands" section to CLAUDE.md** (Option B insight, for agent fallback)
4. **File ks bead for pre-dispatch config validation** (warn when rig has no config.json)
5. **Unblock ks-wr884** (session-start hook can now reference config.json for skill injection context)

---

## Open Questions for Human Direction

1. **Config location:** Is `settings/config.json` (current) the right path, or should it be `rig-config.json` at repo root for visibility?

2. **Schema naming:** Should we rename `merge_queue.test_command` to something rig-neutral now, or accept the naming debt and fix it in Option C?

3. **Silent skip behavior:** When a command is empty/missing, should the step be skipped silently (current), skip with a warning, or fail? This affects how aggressively we require rig config.

4. **Scope of this bead:** Should the Option A implementation (creating config.json, documenting schema) happen as part of this bead's decomposition step, or should it be filed as separate standard-feature beads?

5. **Option B hybrid:** Should the testing skill be updated now to check CLAUDE.md as fallback, or defer until a separate bead?

---

## Appendix: Verified Assumptions

| Assumption | Status | Evidence |
|------------|--------|----------|
| Rig config flows through `settings/config.json` at sling time | Confirmed | `sling_helpers.go:loadRigCommandVars()` reads this path |
| Empty command variables cause steps to skip, not fail | Confirmed | Formula defaults are `""`, step instructions say "if command set" |
| Keeper has no rig config for commands | Confirmed | `keeper/settings/` exists but is empty |
| Skills are loaded via slash commands | Confirmed | 7 symlinks in `.claude/commands/` → `skills/` |
| Formula step descriptions are the only mechanism triggering skill use | Confirmed | No hook or structural mechanism forces skill loading |
| Variable substitution is static (pour-time, not runtime) | Confirmed | `InstantiateFormulaOnBead()` substitutes all vars at molecule creation |
| Keeper's formulas are clean Layer 2 | Confirmed | All 8 formulas have zero rig-specific commands |
| mol-polecat-work expects rig config | Confirmed | Variable table says "Source: rig config" — mechanism doesn't exist |
| `bd mol pour` supports `--var KEY=VALUE` | Confirmed | Pour-time variable injection works |
| Claude Code `.claude/commands/` shadowing in worktrees | Unverified | Needs testing — superpowers uses this pattern |

## Appendix: Prior Research Sources

- **polecat/slit** (98b5114): End-to-end variable resolution trace, BMAD/superpowers deep dive, three options with comparison matrix
- **polecat/furiosa** (0b23856): Broad prior art survey (8 systems), three-layer current state mapping, 8 open questions
- **keeper docs**: `brief.md` (product brief), `conventions.md` (format rules), `bmad-study.md`, `superpowers-study.md`, `formula-audit.md`
