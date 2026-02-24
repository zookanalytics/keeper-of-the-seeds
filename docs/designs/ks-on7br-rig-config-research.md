# Research: Gas Town Rig Config Mechanism

**Bead:** ks-on7br | **Date:** 2026-02-23
**Context:** Architecture review (ks-lzsrz) claimed rig config "doesn't exist." This research verifies what Gas Town actually provides.

---

## Executive Summary

The architecture review was **partially wrong**. Gas Town has a fully implemented, documented, and tested rig config mechanism via `settings/config.json` + `loadRigCommandVars()`. The mechanism works end-to-end — keeper simply hasn't created its config file yet. The infrastructure is not missing; only keeper's config data is missing.

---

## Research Question 1: Does `settings/config.json` work end-to-end?

**Answer: Yes.** The mechanism is fully functional.

### Path resolution

```
<town_root>/<rig_name>/settings/config.json
```

For keeper: `~/gt/keeper/settings/config.json`

### Schema

The file must have `"type": "rig-settings"` and `"version": 1`. Full `RigSettings` schema from `config/types.go`:

```json
{
  "type": "rig-settings",
  "version": 1,
  "merge_queue": {
    "enabled": true,
    "test_command": "...",
    "lint_command": "...",
    "build_command": "...",
    "setup_command": "...",
    "typecheck_command": "...",
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

### Validation

`LoadRigSettings()` in `config/loader.go` validates:
- Type must be `"rig-settings"` (or empty)
- Version must be `<= CurrentRigSettingsVersion` (currently 1)
- MergeQueue sub-struct validated if present
- Deprecated keys produce stderr warnings

### Error handling

If the file doesn't exist, `loadRigCommandVars()` returns `nil` (empty slice). No error is raised. All command variables default to empty string, which formulas treat as "skip."

---

## Research Question 2: What does `loadRigCommandVars()` do exactly?

**Answer:** It reads `<rig>/settings/config.json`, extracts `merge_queue.*_command` fields, and returns them as `--var key=value` strings for formula variable injection.

### Source: `sling_helpers.go:975-1005`

```go
func loadRigCommandVars(townRoot, rig string) []string {
    settingsPath := filepath.Join(townRoot, rig, "settings", "config.json")
    settings, err := config.LoadRigSettings(settingsPath)
    if err != nil || settings == nil || settings.MergeQueue == nil {
        return nil  // Silent return — no error logged
    }
    mq := settings.MergeQueue
    var vars []string
    // Only non-empty commands included; empty = "skip" in formula
    if mq.SetupCommand != "" {
        vars = append(vars, fmt.Sprintf("setup_command=%s", mq.SetupCommand))
    }
    if mq.TypecheckCommand != "" { ... }
    if mq.LintCommand != "" { ... }
    if mq.TestCommand != "" { ... }
    if mq.BuildCommand != "" { ... }
    return vars
}
```

### Call sites (2 paths into the same function)

| Caller | File | Line | Context |
|--------|------|------|---------|
| `executeSling()` | `sling.go:796` | Manual `gt sling` | User-initiated dispatch |
| `dispatchBead()` | `sling_dispatch.go:247` | Auto dispatch | Crew/witness-initiated dispatch |

### Variable injection order

```
rigCmdVars := loadRigCommandVars(townRoot, rigName)
allVars := append(rigCmdVars, params.Vars...)  // user --var flags OVERRIDE rig config
```

Rig config is injected first, then user `--var` flags override. This means a polecat dispatched with `--var test_command="custom"` overrides the rig default.

### Formula consumption

Variables are passed to `InstantiateFormulaOnBead()` → `bd mol pour --var key=value`. The formula template uses `{{test_command}}` etc. Empty string = step instruction says "if command set" → polecat skips.

---

## Research Question 3: Do other rigs have `config.json` populated?

**Answer: No.** No rig in the current workspace has a `settings/config.json`.

| Rig | `settings/` dir exists? | `settings/config.json` exists? |
|-----|------------------------|-------------------------------|
| keeper | Yes (empty) | No |
| events | Yes (empty) | No |
| daemon | No | No |
| deacon | No | No |
| mayor | No | No |
| plugins | No | No |
| warrants | No | No |

**Town-level** `~/gt/settings/config.json` exists and is populated (type `"town-settings"`). This is a different schema — it configures agents and role mappings, not rig-level commands.

### Why no rigs have config

The gastown repo itself (the Go project) uses this mechanism — the reference docs show `"test_command": "go test ./..."` as the example. But the current workspace only has operational/infrastructure rigs (keeper, events), not project rigs with codebases to test/lint/build.

---

## Research Question 4: Is there documentation or convention?

**Answer: Yes, documented in multiple places.**

### Gas Town reference docs (`docs/reference.md`)

- **Line 82-128**: Full schema documentation for `settings/config.json` with field types, defaults, and descriptions
- **Line 517-530**: Rig-level agent override example using `settings/config.json`
- **Line 135-141**: Layered configuration hierarchy

### Integration branches doc (`docs/concepts/integration-branches.md`)

- **Lines 543-558**: "How Commands Flow Into Formulas" — explicitly documents the `loadRigCommandVars()` → formula variable injection pipeline
- Documents the "empty = skip" convention

### Git history

- **847d0b9b**: `feat(config): add LintCommand/BuildCommand fields and parameterize formulas` — the commit that generalized from just `test_command` to 5 command fields
- **6016f15d**: `feat(formula): add default formula configuration at rig level` — added `WorkflowConfig.DefaultFormula`
- **00a59dec**: `feat: Add rig-level custom agent support` — added per-rig agent overrides

### Property layers design doc (`docs/design/property-layers.md`)

Documents a 4-layer configuration resolution hierarchy:
1. Wisp layer (local, ephemeral)
2. Rig identity bead labels (persistent)
3. Town defaults (`~/gt/settings/config.json`)
4. System defaults (compiled-in)

Plus `gt rig config` commands for managing these layers.

---

## Research Question 5: Gas Town's intended direction for rig config?

**Answer:** The current `settings/config.json` mechanism IS the intended mechanism. Gas Town is actively developing richer rig configuration, not planning to replace it.

### Evidence of active investment

| Feature | Commit/PR | Status |
|---------|-----------|--------|
| 5 command fields (setup/typecheck/lint/test/build) | 847d0b9b | Shipped |
| Per-rig agent override | 00a59dec (#12) | Shipped |
| Default formula per rig | 6016f15d (#297) | Shipped |
| Rig config CLI (`gt rig config`) | 29aed4b4 | Shipped |
| Property layers (wisp/bead/town/system) | design doc | Designed |

### Design direction signals

1. **RigSettings keeps growing**: The struct has 10 top-level fields (type, version, merge_queue, theme, namepool, crew, workflow, runtime, agent, agents, role_agents). New fields are being added regularly.

2. **No competing mechanism**: There's no `rig.toml`, no CLAUDE.md-based config, no alternative approach in the codebase. `settings/config.json` is the single, canonical location.

3. **The `gt rig config` CLI exists**: Purpose-built commands for managing rig configuration, with layered resolution. This is a mature subsystem, not a placeholder.

4. **Integration branches doc explicitly documents the flow**: This isn't hidden infrastructure — it's documented as the intended way commands reach formulas.

---

## Correction to Architecture Review (ks-lzsrz)

The architecture review doc makes several claims that need correction:

| Claim in ks-lzsrz | Correction |
|-------------------|------------|
| "no mechanism exists for rigs to declare their tooling" | Mechanism exists: `settings/config.json` → `loadRigCommandVars()` → formula vars |
| "Layer 3 (Rig Config): Missing entirely" | The *data* is missing (keeper has no config file). The *infrastructure* is complete. |
| "a mechanism that doesn't exist" (re: mol-polecat-work variable slots) | The mechanism exists and is documented. It just needs a config file to read. |
| Option A is "extend current config" | More accurately: "populate the existing config" — no extension needed |

### What the arch review got RIGHT

- The three-layer model is accurate and useful
- Keeper specifically lacks config (true)
- The silent-skip failure mode is real and impactful
- Option A (use `settings/config.json`) is the correct recommendation
- The "no work is wasted" migration path reasoning is sound

---

## Implications for Option A Implementation

Since the mechanism already exists and is documented, "Option A" from the architecture review is even simpler than described:

1. **No Go changes needed** — confirmed, as the review stated
2. **No schema documentation needed** — Gas Town's `docs/reference.md` already documents it
3. **No validation hook needed** — the mechanism silently handles missing files by design

The only action required is:

```bash
# Create keeper/settings/config.json with test commands
```

Everything else — variable injection, formula consumption, refinery integration — already works.

### Recommended keeper config

```json
{
  "type": "rig-settings",
  "version": 1,
  "merge_queue": {
    "enabled": true,
    "test_command": "bash tests/cook-all-formulas.sh && shellcheck hooks/**/*.sh",
    "setup_command": "",
    "lint_command": "",
    "typecheck_command": "",
    "build_command": "",
    "on_conflict": "assign_back",
    "run_tests": true,
    "delete_merged_branches": true
  },
  "workflow": {
    "default_formula": "standard-feature"
  }
}
```

---

## Appendix: RigSettings Full Field Reference

From `config/types.go` (Gas Town v0.7.0):

| Field | Type | Purpose |
|-------|------|---------|
| `type` | string | Must be `"rig-settings"` |
| `version` | int | Schema version (current: 1) |
| `merge_queue` | MergeQueueConfig | Build pipeline commands + merge behavior |
| `theme` | ThemeConfig | Tmux status bar theme |
| `namepool` | NamepoolConfig | Polecat name generation |
| `crew` | CrewConfig | Crew auto-start behavior |
| `workflow` | WorkflowConfig | Default formula selection |
| `runtime` | RuntimeConfig | LLM runtime (deprecated, use `agent`) |
| `agent` | string | Agent preset name |
| `agents` | map[string]*RuntimeConfig | Custom agent definitions |
| `role_agents` | map[string]string | Per-role agent overrides |

### MergeQueueConfig command fields

| Field | JSON key | Purpose |
|-------|----------|---------|
| SetupCommand | `setup_command` | Dependency install (e.g., `pnpm install`) |
| TypecheckCommand | `typecheck_command` | Type checking (e.g., `tsc --noEmit`) |
| LintCommand | `lint_command` | Linting (e.g., `eslint .`) |
| TestCommand | `test_command` | Test execution |
| BuildCommand | `build_command` | Build step (e.g., `go build ./...`) |
