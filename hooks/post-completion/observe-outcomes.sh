#!/usr/bin/env bash
# hooks/post-completion/observe-outcomes.sh
#
# Post-completion hook: observe bead outcomes and file ks beads
# for actionable observations. Routine successes produce no output.
#
# Usage:
#   observe-outcomes.sh <bead-id> [--exit-status STATUS]
#
# Arguments:
#   bead-id       The completed bead ID
#   --exit-status Exit status from gt done (COMPLETED, ESCALATED, DEFERRED)
#
# Trigger conditions (files a ks bead when):
#   1. Bead was rejected or abandoned (exit status ESCALATED/DEFERRED)
#   2. Bead took more than one attempt (recycled polecat, conflict resolution)
#   3. Triage was auto but ended up needing human intervention
#   4. Agent escalated during a step that was NOT a designated human gate
#   5. Duration significantly exceeded expectations for the formula type
#   6. Tests failed on the branch
#
# Linking behavior:
#   When an observation matches an existing open ks issue, link to it
#   rather than creating a duplicate. The linked-bead count becomes the
#   frequency signal for retro triage.
#
# Reference: docs/brief.md §Hooks, §Retro Through Beads, §Frequency Through Linking

set -euo pipefail

# --- Configuration ---

# Duration thresholds in seconds (per formula archetype)
# These are generous defaults — refine through retro data
DURATION_THRESHOLD_TRIVIAL=1800       # 30 min
DURATION_THRESHOLD_STANDARD=14400     # 4 hours
DURATION_THRESHOLD_ARCHITECTURE=86400 # 24 hours
DURATION_THRESHOLD_DEFAULT=28800      # 8 hours (fallback)

# Observation label applied to all filed beads
RETRO_LABEL="retro-observation"

# --- Argument Parsing ---

BEAD_ID=""
EXIT_STATUS=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --exit-status)
      EXIT_STATUS="$2"
      shift 2
      ;;
    --help|-h)
      sed -n '2,28p' "$0" | sed 's/^# \?//'
      exit 0
      ;;
    -*)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
    *)
      if [[ -z "$BEAD_ID" ]]; then
        BEAD_ID="$1"
      else
        echo "Unexpected argument: $1" >&2
        exit 1
      fi
      shift
      ;;
  esac
done

if [[ -z "$BEAD_ID" ]]; then
  echo "Usage: observe-outcomes.sh <bead-id> [--exit-status STATUS]" >&2
  exit 1
fi

# --- Helper Functions ---

# Fetch bead JSON array. Returns empty string on failure.
fetch_bead() {
  local id="$1"
  local result
  result=$(bd show "$id" --json 2>/dev/null) || { echo ""; return; }
  # bd show returns an array on success, an object with "error" on failure
  if echo "$result" | jq -e '.[0].id' >/dev/null 2>&1; then
    echo "$result"
  else
    echo ""
  fi
}

# Extract a string field from bead JSON (expects array wrapper from bd show)
jq_field() {
  local json="$1" field="$2" default="${3:-}"
  echo "$json" | jq -r ".[0].$field // \"$default\"" 2>/dev/null || echo "$default"
}

# Extract labels as newline-separated list
jq_labels() {
  local json="$1"
  echo "$json" | jq -r '.[0].labels // [] | .[]' 2>/dev/null || true
}

# Check if a label pattern exists (case-insensitive extended grep)
has_label() {
  local labels="$1" pattern="$2"
  echo "$labels" | grep -Eqi "$pattern" 2>/dev/null
}

# Convert ISO 8601 timestamp to epoch seconds
to_epoch() {
  local ts="$1"
  if [[ -z "$ts" ]] || [[ "$ts" == "null" ]]; then
    echo "0"
    return
  fi
  date -d "$ts" +%s 2>/dev/null || echo "0"
}

# Search for an existing open ks retro issue matching a category
find_existing_retro_issue() {
  local category="$1"
  bd query "label=$RETRO_LABEL AND label=$category AND status=open" \
    --limit 1 \
    --json 2>/dev/null \
  | jq -r '.[0].id // empty' 2>/dev/null || true
}

# Link a bead to an existing retro issue
link_to_existing() {
  local source_bead="$1" target_issue="$2" detail="$3"
  bd dep relate "$source_bead" "$target_issue" 2>/dev/null || true
  bd comments add "$target_issue" \
    "Post-completion observation linked bead $source_bead: $detail" \
    2>/dev/null || true
}

# Create a new ks retro bead
create_retro_bead() {
  local category="$1" title="$2" detail="$3" source_bead="$4"
  local source_title="$5" source_labels="$6"

  local new_id
  new_id=$(bd create \
    --title "$title" \
    --type task \
    --priority 2 \
    --labels "$RETRO_LABEL,$category" \
    --description "## Post-Completion Observation

$detail

## Source Bead

- **ID:** $source_bead
- **Title:** $source_title
- **Labels:** $source_labels

## Action Needed

Review and determine if this requires:
- A skill improvement (skill gap?)
- A formula change (process gap?)
- A triage rule update (misclassification?)

Sort by linked-bead count during retro review — frequency = priority." \
    --silent 2>/dev/null) || true

  if [[ -n "$new_id" ]]; then
    # Link source bead to the new retro issue
    bd dep relate "$source_bead" "$new_id" 2>/dev/null || true
  fi
}

# File or link a retro observation
file_observation() {
  local category="$1" title="$2" detail="$3"

  local existing
  existing=$(find_existing_retro_issue "$category")

  if [[ -n "$existing" ]]; then
    link_to_existing "$BEAD_ID" "$existing" "$detail"
  else
    create_retro_bead "$category" "$title" "$detail" \
      "$BEAD_ID" "$bead_title" "$labels_flat"
  fi
}

# --- Main Logic ---

# Fetch bead metadata
bead_json=$(fetch_bead "$BEAD_ID")
if [[ -z "$bead_json" ]] || [[ "$bead_json" == "[]" ]]; then
  echo "ERROR: Cannot fetch bead $BEAD_ID" >&2
  exit 1
fi

bead_status=$(jq_field "$bead_json" "status" "unknown")
bead_title=$(jq_field "$bead_json" "title" "")
bead_created=$(jq_field "$bead_json" "created_at" "")
bead_updated=$(jq_field "$bead_json" "updated_at" "")
bead_assignee=$(jq_field "$bead_json" "assignee" "")
labels_raw=$(jq_labels "$bead_json")
labels_flat=$(echo "$labels_raw" | paste -sd',' - 2>/dev/null || echo "")

# Collect observations — each is a tuple of (category, title, detail)
observations=()

# --- Condition 1: Bead was rejected or abandoned ---
#
# Detect: exit status ESCALATED/DEFERRED, or status labels indicating rejection
if [[ "$EXIT_STATUS" == "ESCALATED" ]] || [[ "$EXIT_STATUS" == "DEFERRED" ]]; then
  observations+=("rejected-or-abandoned|Bead $EXIT_STATUS: $bead_title|Bead $BEAD_ID exited with status $EXIT_STATUS. This indicates the work was not completed as assigned. Assignee: $bead_assignee")
elif [[ "$bead_status" == "rejected" ]] || [[ "$bead_status" == "abandoned" ]]; then
  observations+=("rejected-or-abandoned|Bead $bead_status: $bead_title|Bead $BEAD_ID has status '$bead_status'. This indicates the work was not successfully completed.")
fi

# --- Condition 2: Multiple attempts ---
#
# Detect: attempt:N labels, recycled/retry labels, or multiple assignee changes
if has_label "$labels_raw" "^attempt:"; then
  attempt_label=$(echo "$labels_raw" | grep -i "^attempt:" | head -1)
  observations+=("multi-attempt|Multi-attempt bead: $bead_title|Bead $BEAD_ID has label '$attempt_label', indicating it required more than one attempt. Check for crash/recycle patterns or conflict resolution spawns.")
fi
if has_label "$labels_raw" "recycled|retry|conflict-resolution|respawned"; then
  observations+=("multi-attempt|Recycled bead: $bead_title|Bead $BEAD_ID has recycling/retry labels ($labels_flat). This suggests polecat crash, conflict resolution, or re-dispatch.")
fi

# --- Condition 3: Triage auto but needed human intervention ---
#
# Detect: triage:auto label + any signal of human involvement
if has_label "$labels_raw" "^triage:auto$"; then
  human_signals=""
  if [[ "$EXIT_STATUS" == "ESCALATED" ]]; then
    human_signals="exit status ESCALATED"
  fi
  if has_label "$labels_raw" "escalated"; then
    human_signals="${human_signals:+$human_signals, }escalated label"
  fi
  if has_label "$labels_raw" "human-intervention|needs-human|review-requested"; then
    human_signals="${human_signals:+$human_signals, }human intervention label"
  fi

  if [[ -n "$human_signals" ]]; then
    observations+=("triage-misclassification|Auto-tier bead needed human help: $bead_title|Bead $BEAD_ID was classified as triage:auto but required human intervention (signals: $human_signals). Consider updating triage heuristics for this type of work.")
  fi
fi

# --- Condition 4: Unexpected escalation ---
#
# Detect: escalation outside a consult/plan gate
# An escalation is "expected" if the bead was triage:consult or triage:plan
if [[ "$EXIT_STATUS" == "ESCALATED" ]] || has_label "$labels_raw" "escalated"; then
  is_expected_gate=false
  if has_label "$labels_raw" "^triage:consult$|^triage:plan$"; then
    is_expected_gate=true
  fi
  if has_label "$labels_raw" "human-gate"; then
    is_expected_gate=true
  fi

  if [[ "$is_expected_gate" == "false" ]]; then
    triage_level="unknown"
    triage_match=$(echo "$labels_raw" | grep -i "^triage:" | head -1 || true)
    if [[ -n "$triage_match" ]]; then
      triage_level="$triage_match"
    fi
    observations+=("unexpected-escalation|Unexpected escalation: $bead_title|Bead $BEAD_ID ($triage_level) escalated outside a designated human gate. This may indicate unclear requirements, missing skill coverage, or incorrect triage classification.")
  fi
fi

# --- Condition 5: Duration significantly exceeded expectations ---
#
# Detect: compare created_at to now (or updated_at for closed beads)
created_epoch=$(to_epoch "$bead_created")
if [[ "$created_epoch" -gt 0 ]]; then
  end_epoch=$(to_epoch "$bead_updated")
  if [[ "$end_epoch" -le 0 ]]; then
    end_epoch=$(date +%s)
  fi
  duration_secs=$((end_epoch - created_epoch))

  # Determine threshold based on formula archetype from labels
  threshold=$DURATION_THRESHOLD_DEFAULT
  if has_label "$labels_raw" "^formula:trivial$"; then
    threshold=$DURATION_THRESHOLD_TRIVIAL
  elif has_label "$labels_raw" "^formula:standard"; then
    threshold=$DURATION_THRESHOLD_STANDARD
  elif has_label "$labels_raw" "^formula:architecture$|^formula:design"; then
    threshold=$DURATION_THRESHOLD_ARCHITECTURE
  fi

  if [[ "$duration_secs" -gt "$threshold" ]]; then
    duration_hours=$(( duration_secs / 3600 ))
    threshold_hours=$(( threshold / 3600 ))
    observations+=("duration-exceeded|Duration exceeded ($duration_hours h): $bead_title|Bead $BEAD_ID took ~${duration_hours}h, exceeding the ${threshold_hours}h threshold for its formula type. This may indicate scope creep, unclear requirements, or a formula that needs decomposition.")
  fi
fi

# --- Condition 6: Tests failed on the branch ---
#
# Detect: test-failure labels or CI failure indicators
if has_label "$labels_raw" "tests-failed|ci-failed|test-failure|build-failed"; then
  observations+=("test-failure|Tests failed: $bead_title|Bead $BEAD_ID has test/CI failure labels ($labels_flat). Investigate whether failures were pre-existing or introduced by the implementation.")
fi

# --- Process observations ---

# Routine success: no observations, exit silently
if [[ ${#observations[@]} -eq 0 ]]; then
  exit 0
fi

# File or link each observation
for obs in "${observations[@]}"; do
  IFS='|' read -r category title detail <<< "$obs"
  file_observation "$category" "$title" "$detail"
done
