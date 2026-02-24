# Decision: Populate Keeper's Rig Config

**Bead:** ks-lzsrz | **Date:** 2026-02-23 | **Revised:** 2026-02-24
**Prior research:** polecat/slit (98b5114), polecat/furiosa (0b23856), polecat/nux (synthesis), polecat/rictus (ks-on7br research)
**Validation review:** ks-fiy4n (6 BLOCKs addressed in this revision)

---

## Decision

**Populate keeper's `settings/config.json`** using Gas Town's existing rig config mechanism. No code changes, no schema changes, no new formats.

## Context

Gas Town has a fully implemented rig config mechanism — `settings/config.json` → `loadRigCommandVars()` → formula variable injection — but keeper has never created its config file. All command variables resolve to empty strings, causing test/lint/build steps to be silently skipped across every polecat dispatch.

The infrastructure exists and works (confirmed by ks-on7br research). The problem is data, not architecture.

### Evidence

| Failure | Bead | Root Cause |
|---------|------|-----------|
| `go test ./...` on non-Go repo | ks-58cnr (P1, fixed) | Formula default had rig-specific command |
| Refinery skips all tests | ks-4217r (P2, open) | `test_command` is empty — no config file |
| Polecats skip testing entirely | Pattern across dispatches | No rig config → empty commands → silent skip |

### Why Not Redesign?

We evaluated an alternative (repo-level config with skill shadowing via CLAUDE.md). It offered more flexibility but at the cost of determinism, breaking changes to formulas, and days-to-weeks of effort. Gas Town's existing mechanism is sufficient — every other multi-agent system we surveyed uses the same pattern of separating process logic from project config, and Gas Town already implements it.

## Keeper Config

```json
{
  "type": "rig-settings",
  "version": 1,
  "merge_queue": {
    "enabled": true,
    "test_command": "bash tests/cook-all-formulas.sh && shellcheck hooks/**/*.sh",
    "setup_command": "",
    "build_command": "",
    "lint_command": "",
    "typecheck_command": "",
    "run_tests": true
  },
  "workflow": {
    "default_formula": "standard-feature"
  }
}
```

These values are agent directions: when a polecat reaches a test step, the formula tells it to run the configured command as the minimum quality gate. The agent applies its `/testing` skill judgment on top of this baseline.

**Location:** `~/gt/keeper/settings/config.json` (rig-level runtime file, not version-controlled)

## Fail/Warn Behavior

| Condition | Behavior | Mechanism |
|-----------|----------|-----------|
| `config.json` missing entirely | **Warn at dispatch time** | Pre-dispatch hook checks existence; logs warning to stderr. Dispatch proceeds. |
| Specific `*_command` field is empty string | **Formula skips silently** | Gas Town's existing behavior, by design. Empty = "not configured for this rig." |

## Resolved Questions

| # | Question | Resolution |
|---|----------|------------|
| 1 | Config location | `~/gt/keeper/settings/config.json` — Gas Town's existing, documented path |
| 2 | Schema naming | Use `merge_queue.*_command` keys as-is — compiled into Go structs, renaming breaks things for no benefit |
| 3 | Fail/warn behavior | Two-tier: warn on missing file, skip silently on empty command |
| 4 | Scope | Separate implementation beads for config file creation and pre-dispatch hook |
| 5 | Skill-as-config hybrid | Defer — updating `/testing` to discover commands from CLAUDE.md is additive but orthogonal |

## Next Steps

1. **Create `~/gt/keeper/settings/config.json`** with the schema above
2. **Add pre-dispatch hook** that warns when target rig has no `settings/config.json`
3. **Unblock ks-wr884** (session-start hook can reference config for context)

## Scope Note

This document records the decision to populate keeper's rig config. It does not define the three-layer architecture itself — that architectural guide (layer boundaries, how rigs adopt the pattern, formula authoring guidance) is a separate deliverable.

---

## Appendix: Prior Research Sources

- **ks-on7br** (polecat/rictus): Verified Gas Town's rig config mechanism exists, documented schema, confirmed only data population needed
- **polecat/slit** (98b5114): End-to-end variable resolution trace, three options with comparison matrix
- **polecat/furiosa** (0b23856): Prior art survey (8 systems), three-layer current state mapping
- **ks-fiy4n** (polecat/rictus): Validation review — verdict NOT READY, 6 BLOCKs all addressed in this revision
