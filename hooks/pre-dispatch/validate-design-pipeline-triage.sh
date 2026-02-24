#!/usr/bin/env bash
# hooks/pre-dispatch/validate-design-pipeline-triage.sh
#
# Pre-dispatch hook: reject design-pipeline beads at auto/review triage levels.
#
# The design-pipeline formula includes multi-phase review, human gates, and
# parallel review convoys. Dispatching at auto/review would skip those gates,
# defeating the purpose of the pipeline. Only plan/consult triage levels
# provide the oversight this formula requires.
#
# Usage:
#   validate-design-pipeline-triage.sh <bead-id> [formula] [triage]
#
# Arguments:
#   bead-id   The bead being dispatched
#   formula   The formula being applied (overridden by BD_FORMULA env var)
#   triage    The triage level assigned (overridden by BD_TRIAGE env var)
#
# Environment variables (override positional args):
#   BD_FORMULA  Formula name (e.g. "design-pipeline")
#   BD_TRIAGE   Triage level (e.g. "plan", "consult", "review", "auto")
#
# Exit codes:
#   0  Dispatch allowed (not design-pipeline, or triage level acceptable)
#   1  Dispatch rejected (design-pipeline at auto/review triage)
#   2  Usage error (missing required arguments)

set -euo pipefail

# --- Argument Parsing ---

BEAD_ID=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --help|-h)
      sed -n '2,27p' "$0" | sed 's/^# \?//'
      exit 0
      ;;
    -*)
      echo "Unknown option: $1" >&2
      exit 2
      ;;
    *)
      if [[ -z "$BEAD_ID" ]]; then
        BEAD_ID="$1"
      elif [[ -z "${BD_FORMULA:-}" ]]; then
        BD_FORMULA="$1"
      elif [[ -z "${BD_TRIAGE:-}" ]]; then
        BD_TRIAGE="$1"
      else
        echo "Unexpected argument: $1" >&2
        exit 2
      fi
      shift
      ;;
  esac
done

if [[ -z "$BEAD_ID" ]]; then
  echo "Usage: validate-design-pipeline-triage.sh <bead-id> [formula] [triage]" >&2
  exit 2
fi

FORMULA="${BD_FORMULA:-}"
TRIAGE="${BD_TRIAGE:-}"

# --- Validation ---

# Not a design-pipeline bead — allow dispatch
if [[ "$FORMULA" != "design-pipeline" ]]; then
  exit 0
fi

# Design-pipeline with no triage set — reject (triage is required)
if [[ -z "$TRIAGE" ]]; then
  echo "REJECT: design-pipeline bead $BEAD_ID has no triage level set." >&2
  echo "Design-pipeline requires triage level 'plan' or 'consult'." >&2
  exit 1
fi

# Normalize to lowercase for comparison
TRIAGE_LOWER=$(echo "$TRIAGE" | tr '[:upper:]' '[:lower:]')

case "$TRIAGE_LOWER" in
  plan|consult)
    # Acceptable triage levels for design-pipeline
    exit 0
    ;;
  auto|review)
    echo "REJECT: design-pipeline bead $BEAD_ID has triage level '$TRIAGE'." >&2
    echo "Design-pipeline requires triage level 'plan' or 'consult'." >&2
    echo "Auto/review triage would skip the multi-phase review process." >&2
    exit 1
    ;;
  *)
    echo "REJECT: design-pipeline bead $BEAD_ID has unknown triage level '$TRIAGE'." >&2
    echo "Design-pipeline requires triage level 'plan' or 'consult'." >&2
    exit 1
    ;;
esac
