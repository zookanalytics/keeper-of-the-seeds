#!/usr/bin/env bash
# hooks/session-start/inject-skills.sh
#
# Session-start hook: inject skill references into agent context.
#
# Determines which keeper skills are relevant for the agent's current
# molecule step and outputs structured skill injection text. This makes
# skills structural (injected into context) rather than advisory
# (available but not invoked).
#
# The hook parses formula step descriptions for skill references
# (patterns like /implementation, /testing, skill:code-review) and
# outputs a context block that tells the agent which skills to invoke.
#
# Usage:
#   inject-skills.sh [--keeper-root PATH]
#
# Integration (add to .claude/settings.json SessionStart hooks):
#   {
#     "type": "command",
#     "command": "~/gt/keeper/hooks/session-start/inject-skills.sh"
#   }
#
# Output:
#   Structured text for the agent's context window. Includes:
#     - Which skills are required for the current molecule step
#     - Full list of available keeper skills as slash commands
#   Produces no output when keeper root cannot be found.
#
# Exit codes:
#   0  Always (hook failures should not block session start)
#
# Reference: docs/brief.md §Hooks (Session-start hooks)

set -euo pipefail

# --- Configuration ---

# Known keeper skills available as slash commands.
# Maintained in sync with skills/*.md and .claude/commands/*.md
KEEPER_SKILLS=(
  "acceptance-testing"
  "code-review"
  "document-review"
  "implementation"
  "pr-merge"
  "research"
  "testing"
)

# --- Argument Parsing ---

KEEPER_ROOT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --keeper-root)
      KEEPER_ROOT="${2:-}"
      shift 2
      ;;
    --help|-h)
      sed -n '2,35p' "$0" | sed 's/^# \?//'
      exit 0
      ;;
    *)
      shift
      ;;
  esac
done

# --- Functions ---

# Discover keeper root from known locations.
# Returns the path or empty string if not found.
find_keeper_root() {
  if [[ -n "$KEEPER_ROOT" ]] && [[ -d "$KEEPER_ROOT/skills" ]]; then
    echo "$KEEPER_ROOT"
    return
  fi

  local git_root
  git_root=$(git rev-parse --show-toplevel 2>/dev/null || true)

  for candidate in \
    "$HOME/gt/keeper" \
    "$git_root"; do
    if [[ -n "$candidate" ]] && [[ -d "$candidate/skills" ]]; then
      echo "$candidate"
      return
    fi
  done

  echo ""
}

# Get current molecule step info as JSON.
# Returns JSON array from bd mol current, or empty string.
get_current_mol_json() {
  local json
  json=$(bd mol current --json 2>/dev/null) || { echo ""; return; }

  if [[ -z "$json" ]] || [[ "$json" == "[]" ]] || [[ "$json" == "null" ]]; then
    echo ""
    return
  fi

  echo "$json"
}

# Get hooked bead info as JSON.
# Returns JSON from gt hook, or empty string.
get_hook_json() {
  local json
  json=$(gt hook --json 2>/dev/null) || { echo ""; return; }

  if [[ -z "$json" ]] || [[ "$json" == "null" ]]; then
    echo ""
    return
  fi

  echo "$json"
}

# Extract skill references from text.
# Matches: /implementation, /testing, skill:code-review, etc.
# Outputs one skill name per line.
extract_skills_from_text() {
  local text="$1"

  for skill in "${KEEPER_SKILLS[@]}"; do
    if echo "$text" | grep -qE "(/$skill|skill:$skill)" 2>/dev/null; then
      echo "$skill"
    fi
  done
}

# Discover available skills from the keeper skills directory.
# Falls back to the hardcoded list if directory not found.
discover_available_skills() {
  local keeper_root="$1"

  if [[ -n "$keeper_root" ]] && [[ -d "$keeper_root/skills" ]]; then
    for f in "$keeper_root/skills"/*.md; do
      [[ -f "$f" ]] || continue
      basename "$f" .md
    done
  else
    printf '%s\n' "${KEEPER_SKILLS[@]}"
  fi
}

# --- Main ---

keeper_root=$(find_keeper_root)

if [[ -z "$keeper_root" ]]; then
  # Keeper not found — silently exit. Agent may not be in a keeper-managed rig.
  exit 0
fi

# --- Determine current step and extract skill references ---

step_title=""
step_skills=()

# Priority 1: Current molecule step (most specific)
mol_json=$(get_current_mol_json)
if [[ -n "$mol_json" ]]; then
  step_title=$(echo "$mol_json" | jq -r '.[0].next_step.title // empty' 2>/dev/null || true)
  step_desc=$(echo "$mol_json" | jq -r '.[0].next_step.description // empty' 2>/dev/null || true)

  if [[ -n "$step_desc" ]]; then
    while IFS= read -r skill; do
      [[ -n "$skill" ]] && step_skills+=("$skill")
    done < <(extract_skills_from_text "$step_desc")
  fi
fi

# Priority 2: Hooked bead description (fallback when no molecule step)
if [[ ${#step_skills[@]} -eq 0 ]]; then
  hook_json=$(get_hook_json)
  if [[ -n "$hook_json" ]]; then
    hook_desc=$(echo "$hook_json" | jq -r '.pinned_bead.description // empty' 2>/dev/null || true)
    if [[ -n "$hook_desc" ]]; then
      while IFS= read -r skill; do
        [[ -n "$skill" ]] && step_skills+=("$skill")
      done < <(extract_skills_from_text "$hook_desc")
    fi
  fi
fi

# --- Output skill injection ---

echo "[KEEPER SKILLS]"

if [[ ${#step_skills[@]} -gt 0 ]]; then
  if [[ -n "$step_title" ]]; then
    echo "Current step: $step_title"
  fi
  echo "Required skills for this step:"
  for skill in "${step_skills[@]}"; do
    echo "  → /$skill"
  done
  echo ""
  echo "Invoke these skills before proceeding. Skills are structural — the formula requires their use."
else
  echo "No specific skills required for the current step."
fi

echo ""
echo "Available keeper skills:"
while IFS= read -r skill; do
  [[ -n "$skill" ]] && echo "  /$skill"
done < <(discover_available_skills "$keeper_root")
