#!/usr/bin/env bash
# Tests for hooks/pre-dispatch/validate-design-pipeline-triage.sh
# Run from repo root: bash tests/validate-design-pipeline-triage.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
HOOK="$REPO_ROOT/hooks/pre-dispatch/validate-design-pipeline-triage.sh"

failures=0
total=0

# Helper: run a test case
# Usage: run_test "description" expected_exit_code [args...] [env_prefix]
run_test() {
  local desc="$1" expected="$2"
  shift 2
  total=$((total + 1))

  local actual
  if "$HOOK" "$@" >/dev/null 2>&1; then
    actual=0
  else
    actual=$?
  fi

  if [[ "$actual" -eq "$expected" ]]; then
    echo "  ok  $desc"
  else
    echo "FAIL  $desc (expected exit $expected, got $actual)"
    failures=$((failures + 1))
  fi
}

# Helper: run a test with env vars
run_test_env() {
  local desc="$1" expected="$2"
  shift 2
  local env_args=()
  local cmd_args=()

  # Split: KEY=VALUE go to env, rest go to cmd_args
  while [[ $# -gt 0 ]]; do
    case "$1" in
      *=*) env_args+=("$1") ;;
      *)   cmd_args+=("$1") ;;
    esac
    shift
  done

  total=$((total + 1))

  local actual
  if env "${env_args[@]}" "$HOOK" "${cmd_args[@]}" >/dev/null 2>&1; then
    actual=0
  else
    actual=$?
  fi

  if [[ "$actual" -eq "$expected" ]]; then
    echo "  ok  $desc"
  else
    echo "FAIL  $desc (expected exit $expected, got $actual)"
    failures=$((failures + 1))
  fi
}

echo "=== Allow: non-design-pipeline formulas ==="

run_test "standard-feature at auto triage passes" 0 \
  test-bead standard-feature auto

run_test "trivial at review triage passes" 0 \
  test-bead trivial review

run_test "architecture at plan triage passes" 0 \
  test-bead architecture plan

run_test "empty formula passes" 0 \
  test-bead "" auto

echo
echo "=== Allow: design-pipeline at acceptable triage levels ==="

run_test "design-pipeline at plan triage passes" 0 \
  test-bead design-pipeline plan

run_test "design-pipeline at consult triage passes" 0 \
  test-bead design-pipeline consult

echo
echo "=== Reject: design-pipeline at insufficient triage levels ==="

run_test "design-pipeline at auto triage rejected" 1 \
  test-bead design-pipeline auto

run_test "design-pipeline at review triage rejected" 1 \
  test-bead design-pipeline review

echo
echo "=== Reject: design-pipeline with missing/unknown triage ==="

run_test "design-pipeline with no triage rejected" 1 \
  test-bead design-pipeline

run_test "design-pipeline with unknown triage rejected" 1 \
  test-bead design-pipeline bogus

echo
echo "=== Case insensitivity ==="

run_test "design-pipeline at PLAN (uppercase) passes" 0 \
  test-bead design-pipeline PLAN

run_test "design-pipeline at Consult (mixed case) passes" 0 \
  test-bead design-pipeline Consult

run_test "design-pipeline at AUTO (uppercase) rejected" 1 \
  test-bead design-pipeline AUTO

run_test "design-pipeline at Review (mixed case) rejected" 1 \
  test-bead design-pipeline Review

echo
echo "=== Environment variable override ==="

run_test_env "BD_FORMULA env overrides positional formula" 1 \
  BD_FORMULA=design-pipeline BD_TRIAGE=auto test-bead

run_test_env "BD_TRIAGE env overrides positional triage" 0 \
  BD_FORMULA=design-pipeline BD_TRIAGE=plan test-bead

echo
echo "=== Usage errors ==="

run_test "no arguments gives usage error" 2

echo
echo "=== Help flag ==="

# --help should exit 0
run_test "--help exits cleanly" 0 --help

echo
echo "---"
echo "$total tests, $failures failures"

if [[ "$failures" -gt 0 ]]; then
  exit 1
fi
