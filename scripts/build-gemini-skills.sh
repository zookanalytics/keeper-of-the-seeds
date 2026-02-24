#!/usr/bin/env bash
# scripts/build-gemini-skills.sh
#
# Generate Gemini-compatible skill files from canonical skills/*.md sources.
#
# Produces two output formats:
#   .gemini/commands/<name>.toml  — Slash command equivalents (user-invoked)
#   .gemini/skills/<name>/SKILL.md — Agent Skills (model-invoked with user consent)
#
# The canonical source is always skills/<name>.md. Generated files are runtime
# artifacts (gitignored) and should never be hand-edited.
#
# Usage:
#   scripts/build-gemini-skills.sh [--keeper-root PATH] [--clean]
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
GEMINI_COMMANDS_DIR="$KEEPER_ROOT/.gemini/commands"
GEMINI_SKILLS_DIR="$KEEPER_ROOT/.gemini/skills"

# --- Clean if requested ---

if $CLEAN; then
  if $DRY_RUN; then
    echo "[dry-run] Would remove: $GEMINI_COMMANDS_DIR"
    echo "[dry-run] Would remove: $GEMINI_SKILLS_DIR"
  else
    rm -rf "$GEMINI_COMMANDS_DIR" "$GEMINI_SKILLS_DIR"
  fi
fi

# --- YAML frontmatter parser ---

# Extract a frontmatter field value from a skill file.
# Usage: get_frontmatter_field <file> <field>
get_frontmatter_field() {
  local file="$1"
  local field="$2"

  # Read between --- markers, find field, strip key and quotes.
  # grep may return 1 (no match) — suppress with || true.
  sed -n '/^---$/,/^---$/p' "$file" \
    | (grep "^${field}:" || true) \
    | sed "s/^${field}: *//" \
    | sed 's/^"\(.*\)"$/\1/' \
    | sed "s/^'\(.*\)'$/\1/"
}

# Extract the body (everything after the second ---) from a skill file.
get_body() {
  local file="$1"
  # Skip everything up to and including the second ---
  awk 'BEGIN{n=0} /^---$/{n++; if(n==2){found=1; next}} found{print}' "$file"
}

# --- TOML escaping ---

# Escape a string for TOML multi-line basic string (triple-quoted).
# In TOML """...""", we only need to escape sequences of 3+ quotes.
toml_escape_multiline() {
  # Replace any sequence of """ with ""\", which breaks the triple-quote
  sed 's/"""/""\\"/g'
}

# Escape a string for a TOML basic string (single-line, double-quoted).
toml_escape_string() {
  local s="$1"
  # Escape backslashes first, then double quotes
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  echo "$s"
}

# --- Generate Gemini command (TOML) ---

generate_command() {
  local skill_file="$1"
  local name
  name=$(basename "$skill_file" .md)

  local description
  description=$(get_frontmatter_field "$skill_file" "description")
  local expert
  expert=$(get_frontmatter_field "$skill_file" "expert")

  local body
  body=$(get_body "$skill_file")

  local output_file="$GEMINI_COMMANDS_DIR/${name}.toml"

  if $DRY_RUN; then
    echo "[dry-run] Would generate: $output_file"
    return
  fi

  local escaped_desc
  escaped_desc=$(toml_escape_string "$description")

  # Build the prompt: expert context (if present) + full skill body
  local prompt_content=""
  if [[ -n "$expert" ]]; then
    prompt_content="$expert"$'\n\n'"$body"
  else
    prompt_content="$body"
  fi

  local escaped_prompt
  escaped_prompt=$(echo "$prompt_content" | toml_escape_multiline)

  cat > "$output_file" <<TOML
# Generated from skills/${name}.md — do not edit directly.
# Regenerate with: scripts/build-gemini-skills.sh

description = "${escaped_desc}"

prompt = """
${escaped_prompt}
"""
TOML
}

# --- Generate Gemini agent skill (SKILL.md) ---

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

  local skill_dir="$GEMINI_SKILLS_DIR/$name"
  local output_file="$skill_dir/SKILL.md"

  if $DRY_RUN; then
    echo "[dry-run] Would generate: $output_file"
    return
  fi

  mkdir -p "$skill_dir"

  # SKILL.md uses the same YAML frontmatter format but Gemini expects
  # name + description for discovery. The expert field is folded into the body.
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

# --- Generate Gemini handoff command ---

generate_handoff() {
  local output_file="$GEMINI_COMMANDS_DIR/handoff.toml"

  if $DRY_RUN; then
    echo "[dry-run] Would generate: $output_file"
    return
  fi

  cat > "$output_file" <<'TOML'
# Generated — Gemini equivalent of .claude/commands/handoff.md
# Regenerate with: scripts/build-gemini-skills.sh

description = "Hand off to fresh session, work continues from hook"

prompt = """
Hand off to a fresh session.

User's handoff message (if any): {{args}}

Execute these steps in order:

1. If user provided a message, run the handoff command with a subject and message.
   Example: `gt handoff -s "HANDOFF: Session cycling" -m "USER_MESSAGE_HERE"`

2. If no message was provided, run the handoff command:
   `gt handoff`

Note: The new session will auto-prime via the SessionStart hook and find your handoff mail.
End watch. A new session takes over, picking up any molecule on the hook.
"""
TOML
}

# --- Main ---

# Ensure output directories exist
if ! $DRY_RUN; then
  mkdir -p "$GEMINI_COMMANDS_DIR" "$GEMINI_SKILLS_DIR"
fi

# Count skills processed
count=0

for skill_file in "$SKILLS_DIR"/*.md; do
  [[ -f "$skill_file" ]] || continue

  name=$(basename "$skill_file" .md)

  generate_command "$skill_file"
  generate_skill "$skill_file"

  count=$((count + 1))
done

# Generate the handoff command (Gemini-native, not from skills/)
generate_handoff

if $DRY_RUN; then
  echo "[dry-run] Would generate $count skills + 1 handoff command"
else
  echo "Generated Gemini skill files from $count canonical skills"
  echo "  Commands: $GEMINI_COMMANDS_DIR/"
  echo "  Skills:   $GEMINI_SKILLS_DIR/"
fi
