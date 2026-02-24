#!/usr/bin/env bash
# scripts/build-codex-skills.sh
#
# Generate Codex-compatible skill files from canonical skills/*.md sources.
#
# Produces:
#   .agents/skills/<name>/SKILL.md — Agent Skills (implicit/explicit invocation)
#
# Codex discovers skills in .agents/skills/ at the repo root. Each skill is a
# directory containing a SKILL.md file with name and description fields.
#
# The canonical source is always skills/<name>.md. Generated files are runtime
# artifacts (gitignored) and should never be hand-edited.
#
# Usage:
#   scripts/build-codex-skills.sh [--keeper-root PATH] [--clean]
#
# Options:
#   --keeper-root PATH   Keeper root directory (default: auto-detect)
#   --clean              Remove generated files before rebuilding
#   --dry-run            Show what would be generated without writing files
#   --help               Show this help
#
# Exit codes:
#   0  Success
#   1  Keeper root not found or no skills to process

set -euo pipefail

# --- Argument Parsing ---

KEEPER_ROOT=""
CLEAN=false
DRY_RUN=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --keeper-root)
      KEEPER_ROOT="${2:-}"
      shift 2
      ;;
    --clean)
      CLEAN=true
      shift
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --help|-h)
      sed -n '2,27p' "$0" | sed 's/^# \?//'
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

# --- Discover keeper root ---

find_keeper_root() {
  if [[ -n "$KEEPER_ROOT" ]] && [[ -d "$KEEPER_ROOT/skills" ]]; then
    echo "$KEEPER_ROOT"
    return
  fi

  # Try script's own location
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  local candidate="${script_dir%/scripts}"

  if [[ -d "$candidate/skills" ]]; then
    echo "$candidate"
    return
  fi

  # Try git root
  local git_root
  git_root=$(git rev-parse --show-toplevel 2>/dev/null || true)
  if [[ -n "$git_root" ]] && [[ -d "$git_root/skills" ]]; then
    echo "$git_root"
    return
  fi

  echo ""
}

KEEPER_ROOT=$(find_keeper_root)

if [[ -z "$KEEPER_ROOT" ]]; then
  echo "Error: Cannot find keeper root (no skills/ directory found)" >&2
  exit 1
fi

SKILLS_DIR="$KEEPER_ROOT/skills"
CODEX_SKILLS_DIR="$KEEPER_ROOT/.agents/skills"

# --- Clean if requested ---

if $CLEAN; then
  if $DRY_RUN; then
    echo "[dry-run] Would remove: $CODEX_SKILLS_DIR"
  else
    rm -rf "$CODEX_SKILLS_DIR"
  fi
fi

# --- YAML frontmatter parser ---

# Extract a frontmatter field value from a skill file.
# Usage: get_frontmatter_field <file> <field>
get_frontmatter_field() {
  local file="$1"
  local field="$2"

  sed -n '/^---$/,/^---$/p' "$file" \
    | (grep "^${field}:" || true) \
    | sed "s/^${field}: *//" \
    | sed 's/^"\(.*\)"$/\1/' \
    | sed "s/^'\(.*\)'$/\1/"
}

# Extract the body (everything after the second ---) from a skill file.
get_body() {
  local file="$1"
  awk 'BEGIN{n=0} /^---$/{n++; if(n==2){found=1; next}} found{print}' "$file"
}

# --- Generate Codex agent skill (SKILL.md) ---

generate_skill() {
  local skill_file="$1"
  local name
  name=$(basename "$skill_file" .md)

  local description
  description=$(get_frontmatter_field "$skill_file" "description")
  local expert
  expert=$(get_frontmatter_field "$skill_file" "expert")

  local body
  body=$(get_body "$skill_file")

  local skill_dir="$CODEX_SKILLS_DIR/$name"
  local output_file="$skill_dir/SKILL.md"

  if $DRY_RUN; then
    echo "[dry-run] Would generate: $output_file"
    return
  fi

  mkdir -p "$skill_dir"

  # SKILL.md format: name + description for Codex discovery.
  # Expert context is folded into the body as a blockquote.
  {
    echo "---"
    echo "name: $name"
    echo "description: $description"
    echo "---"
    if [[ -n "$expert" ]]; then
      echo ""
      echo "> $expert"
    fi
    echo "$body"
  } > "$output_file"
}

# --- Generate Codex handoff skill ---

generate_handoff() {
  local skill_dir="$CODEX_SKILLS_DIR/handoff"
  local output_file="$skill_dir/SKILL.md"

  if $DRY_RUN; then
    echo "[dry-run] Would generate: $output_file"
    return
  fi

  mkdir -p "$skill_dir"

  cat > "$output_file" <<'SKILL'
---
name: handoff
description: Hand off to fresh session, work continues from hook
---

# Handoff

Hand off to a fresh session.

Execute these steps in order:

1. If the user provided a handoff message, run:
   `gt handoff -s "HANDOFF: Session cycling" -m "<user message>"`

2. If no message was provided, run:
   `gt handoff`

Note: The new session will auto-prime via the SessionStart hook and find your handoff mail.
End watch. A new session takes over, picking up any molecule on the hook.
SKILL
}

# --- Main ---

# Ensure output directory exists
if ! $DRY_RUN; then
  mkdir -p "$CODEX_SKILLS_DIR"
fi

# Count skills processed
count=0

for skill_file in "$SKILLS_DIR"/*.md; do
  [[ -f "$skill_file" ]] || continue

  generate_skill "$skill_file"

  count=$((count + 1))
done

# Generate the handoff skill (Codex-native, not from skills/)
generate_handoff

if $DRY_RUN; then
  echo "[dry-run] Would generate $count skills + 1 handoff skill"
else
  echo "Generated Codex skill files from $count canonical skills"
  echo "  Skills: $CODEX_SKILLS_DIR/"
fi
