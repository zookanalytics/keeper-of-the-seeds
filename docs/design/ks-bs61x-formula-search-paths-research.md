# Research: formula.search_paths Config for Persistent Custom Formula Directories

**Bead:** ks-bs61x | **Date:** 2026-02-24
**Context:** Keeper formulas require per-formula symlinks into `$GT_ROOT/.beads/formulas/` to be discoverable from project rigs. A config key would eliminate symlink maintenance.

---

## Executive Summary

The `bd` CLI hardcodes three formula search paths. Keeper formulas are currently made discoverable through symlinks from `$GT_ROOT/.beads/formulas/` into keeper subdirectories. The `--search-path` flag on `bd cook` proves the parser already supports additional paths — it just doesn't persist them. Adding `formula.search_paths` as a YAML config key is a small, well-scoped change (~20 lines of Go) that would eliminate per-formula symlink maintenance.

**Recommendation:** File this as a beads issue. The change touches 3 files in the beads codebase. No keeper-side changes needed once implemented.

---

## Current State

### Hardcoded search paths (checked in order)

1. `<cwd>/.beads/formulas/` — Project level
2. `~/.beads/formulas/` — User level
3. `$GT_ROOT/.beads/formulas/` — Orchestrator level (only if GT_ROOT set)

Source: `internal/formula/parser.go:57-76` (`defaultSearchPaths()`)

### How keeper formulas are discovered today

Symlinks from `$GT_ROOT/.beads/formulas/` into keeper rig subdirectories:

```
~/gt/.beads/formulas/
├── architecture.formula.toml -> ~/gt/keeper/mayor/rig/formulas/architecture.formula.toml
├── consult.formula.toml -> ~/gt/keeper/crew/scout/formulas/consult.formula.toml
├── design-pipeline.formula.toml -> ~/gt/keeper/crew/scout/formulas/design-pipeline.formula.toml
├── beads-release.formula.toml   (direct file, not symlink)
├── code-review.formula.toml     (direct file, not symlink)
└── ...
```

**Problem:** Each new formula in keeper requires a new symlink. This doesn't scale as keeper grows and other rigs start defining formulas.

### Existing `--search-path` flag

`bd cook` already accepts `--search-path` for ad-hoc additional directories:

```bash
bd cook my-formula --search-path /path/to/extra/formulas
```

This creates a `formula.NewParser(searchPaths...)` that **replaces** (not appends to) the defaults when non-empty. The plumbing works — it just isn't persistent.

---

## Proposed Implementation

### Change 1: Add config key to YAML-only keys

**File:** `internal/config/yaml_config.go`

Add `"formula.search_paths": true` to `YamlOnlyKeys` map. This ensures the config is stored in `config.yaml` (readable at startup before database is opened), matching how formula loading occurs early in the lifecycle.

Also add `"formula."` to the prefix list in `IsYamlOnlyKey()` so future `formula.*` keys route correctly.

### Change 2: Read config in `defaultSearchPaths()`

**File:** `internal/formula/parser.go`

After project-level paths and before user-level paths, insert config-sourced paths:

```go
func defaultSearchPaths() []string {
    var paths []string

    // Project-level formulas
    if cwd, err := os.Getwd(); err == nil {
        paths = append(paths, filepath.Join(cwd, ".beads", "formulas"))
    }

    // Config-level formulas (formula.search_paths)
    if configPaths := config.GetStringSlice("formula.search_paths"); len(configPaths) > 0 {
        paths = append(paths, configPaths...)
    }

    // User-level formulas
    if home, err := os.UserHomeDir(); err == nil {
        paths = append(paths, filepath.Join(home, ".beads", "formulas"))
    }

    // Orchestrator formulas (via GT_ROOT)
    if gtRoot := os.Getenv("GT_ROOT"); gtRoot != "" {
        paths = append(paths, filepath.Join(gtRoot, ".beads", "formulas"))
    }

    return paths
}
```

**Import required:** `"github.com/zookanalytics/beads/internal/config"` (circular dependency check needed — parser.go is in `internal/formula`, config is in `internal/config`; no existing dependency from formula→config, so this is a new edge in the import graph).

**Alternative if circular dependency is a concern:** Accept a `ConfigReader` interface or pass config paths as a parameter to `defaultSearchPaths()`, keeping the formula package decoupled from config.

### Change 3: Update `getFormulaSearchPaths()` in formula command

**File:** `cmd/bd/formula.go`

The `getFormulaSearchPaths()` helper (used by `bd formula list`, `bd formula show`, `bd mol seed`) duplicates the same hardcoded logic. It should also read config paths for consistency. Alternatively, both this function and `defaultSearchPaths()` could call a shared helper.

### Config format

In `.beads/config.yaml`:

```yaml
formula:
  search_paths:
    - /home/zook/gt/keeper/formulas
    - /home/zook/gt/keeper/crew/scout/formulas
    - /home/zook/gt/keeper/mayor/rig/formulas
```

Or via CLI:

```bash
bd config set formula.search_paths "/path/to/formulas1,/path/to/formulas2"
```

---

## Verification

### Test 1: Config key is NOT currently read by bd

```bash
bd config set formula.search_paths "/tmp/test-formula-path"
# Created a formula file at /tmp/test-formula-path/test-search-config.formula.toml
bd cook test-search-config --dry-run
# Result: Error: formula not found (only checks hardcoded paths)
```

### Test 2: `--search-path` flag proves parser supports extra paths

The `--search-path` flag on `bd cook` passes paths directly to `formula.NewParser()`. The parser correctly searches additional directories. The mechanism is proven; only persistence is missing.

---

## Scope and Risk

- **~20 lines of Go** across 3 files
- **No breaking changes** — config is additive; existing paths still searched
- **Circular dependency risk** is the main design consideration; interface injection avoids it
- **No keeper changes needed** — once `bd` reads the config, keeper sets `formula.search_paths` in its `.beads/config.yaml` and removes symlinks

---

## Filing Note

This feature belongs to the **beads** codebase (`bd` CLI, Go). The beads rig is not yet available in Gas Town routing. When a beads rig exists, this bead should be filed there. In the meantime, this research doc captures the full context needed for implementation.
