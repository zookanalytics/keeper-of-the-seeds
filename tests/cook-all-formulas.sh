#!/usr/bin/env bash
# Structural test: verify all keeper formulas cook without errors.
# Run from repo root: bash tests/cook-all-formulas.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
FORMULA_DIR="$REPO_ROOT/formulas"

failures=0
total=0

for f in "$FORMULA_DIR"/*.formula.toml; do
  name="$(basename "$f")"
  total=$((total + 1))
  if output=$(bd cook "$f" --dry-run --search-path "$FORMULA_DIR" 2>&1); then
    echo "  ok  $name"
  else
    echo "FAIL  $name"
    echo "      $output" | head -5
    failures=$((failures + 1))
  fi
done

echo
echo "$total formulas tested, $failures failures"

if [ "$failures" -gt 0 ]; then
  exit 1
fi
