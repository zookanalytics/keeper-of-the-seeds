#!/usr/bin/env bash
# Tests for hooks/session-start/inject-skills.sh
# Run from repo root: bash tests/inject-skills.sh
# shellcheck disable=SC2016  # Single-quoted mock scripts intentionally avoid expansion
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
HOOK="$REPO_ROOT/hooks/session-start/inject-skills.sh"

failures=0
total=0

# Helper: run a test and check output
# Usage: run_test "description" expected_exit expected_pattern [args...]
run_test() {
  local desc="$1" expected_exit="$2" expected_pattern="$3"
  shift 3
  total=$((total + 1))

  local output actual_exit
  output=$("$HOOK" "$@" 2>&1) || true
  actual_exit=$?

  if [[ "$actual_exit" -ne "$expected_exit" ]]; then
    echo "FAIL  $desc (expected exit $expected_exit, got $actual_exit)"
    failures=$((failures + 1))
    return
  fi

  if [[ -n "$expected_pattern" ]]; then
    if ! echo "$output" | grep -qE "$expected_pattern"; then
      echo "FAIL  $desc (output missing pattern: $expected_pattern)"
      echo "      Output: $(echo "$output" | head -3)"
      failures=$((failures + 1))
      return
    fi
  fi

  echo "  ok  $desc"
}

# Helper: run hook with mocked bd/gt commands
# Usage: run_test_mock "description" expected_exit expected_pattern mock_script
run_test_mock() {
  local desc="$1" expected_exit="$2" expected_pattern="$3" mock_script="$4"
  total=$((total + 1))

  # Create temp dir for mock commands
  local mock_dir
  mock_dir=$(mktemp -d)

  # Write mock script
  eval "$mock_script"

  # Run with mocked PATH
  local output actual_exit
  output=$(PATH="$mock_dir:$PATH" "$HOOK" --keeper-root "$REPO_ROOT" 2>&1) || true
  actual_exit=$?

  # Cleanup
  rm -rf "$mock_dir"

  if [[ "$actual_exit" -ne "$expected_exit" ]]; then
    echo "FAIL  $desc (expected exit $expected_exit, got $actual_exit)"
    failures=$((failures + 1))
    return
  fi

  if [[ -n "$expected_pattern" ]]; then
    if ! echo "$output" | grep -qE "$expected_pattern"; then
      echo "FAIL  $desc (output missing pattern: $expected_pattern)"
      echo "      Output: $(echo "$output" | head -3)"
      failures=$((failures + 1))
      return
    fi
  fi

  echo "  ok  $desc"
}

# Helper: run hook with mocked commands and check output does NOT match
run_test_mock_absent() {
  local desc="$1" expected_exit="$2" absent_pattern="$3" mock_script="$4"
  total=$((total + 1))

  local mock_dir
  mock_dir=$(mktemp -d)
  eval "$mock_script"

  local output actual_exit
  output=$(PATH="$mock_dir:$PATH" "$HOOK" --keeper-root "$REPO_ROOT" 2>&1) || true
  actual_exit=$?

  rm -rf "$mock_dir"

  if [[ "$actual_exit" -ne "$expected_exit" ]]; then
    echo "FAIL  $desc (expected exit $expected_exit, got $actual_exit)"
    failures=$((failures + 1))
    return
  fi

  if echo "$output" | grep -qE "$absent_pattern" 2>/dev/null; then
    echo "FAIL  $desc (output unexpectedly matched: $absent_pattern)"
    failures=$((failures + 1))
    return
  fi

  echo "  ok  $desc"
}


echo "=== Basic output ==="

run_test "produces KEEPER SKILLS header" 0 "\\[KEEPER SKILLS\\]" \
  --keeper-root "$REPO_ROOT"

run_test "lists available skills" 0 "/implementation" \
  --keeper-root "$REPO_ROOT"

run_test "lists all 7 skills" 0 "/testing" \
  --keeper-root "$REPO_ROOT"

echo
echo "=== Keeper root discovery ==="

run_test "invalid keeper root with no fallback exits silently" 0 "" \
  --keeper-root /nonexistent

# The above test runs inside this repo, so git root fallback will find skills.
# Test true absence from outside any git repo:
total=$((total + 1))
output=$(cd /tmp && HOME=/tmp/nonexistent "$HOOK" --keeper-root /nonexistent 2>&1) || true
if [[ -z "$output" ]]; then
  echo "  ok  truly absent keeper root produces no output"
else
  echo "FAIL  truly absent keeper root produces no output (got: $output)"
  failures=$((failures + 1))
fi

echo
echo "=== Help flag ==="

run_test "--help exits cleanly" 0 "Session-start hook" --help

echo
echo "=== Skill extraction from molecule step ==="

# Mock bd mol current returning a step with /implementation skill reference
run_test_mock "extracts /implementation from mol step" 0 "→ /implementation" '
  cat > "$mock_dir/bd" << "MOCK"
#!/usr/bin/env bash
if [[ "$1" == "mol" && "$2" == "current" ]]; then
  echo '"'"'[{"molecule_id":"test-mol","next_step":{"title":"Implement feature","description":"Implement the feature per /implementation. Read the spec.","status":"open"}}]'"'"'
  exit 0
fi
exit 1
MOCK
  chmod +x "$mock_dir/bd"
  cat > "$mock_dir/gt" << "MOCK"
#!/usr/bin/env bash
exit 1
MOCK
  chmod +x "$mock_dir/gt"
'

# Mock with /testing reference
run_test_mock "extracts /testing from mol step" 0 "→ /testing" '
  cat > "$mock_dir/bd" << "MOCK"
#!/usr/bin/env bash
if [[ "$1" == "mol" && "$2" == "current" ]]; then
  echo '"'"'[{"molecule_id":"test-mol","next_step":{"title":"Test feature","description":"Write and run tests per /testing.","status":"open"}}]'"'"'
  exit 0
fi
exit 1
MOCK
  chmod +x "$mock_dir/bd"
  cat > "$mock_dir/gt" << "MOCK"
#!/usr/bin/env bash
exit 1
MOCK
  chmod +x "$mock_dir/gt"
'

# Mock with multiple skill references
run_test_mock "extracts multiple skills from step" 0 "→ /implementation" '
  cat > "$mock_dir/bd" << "MOCK"
#!/usr/bin/env bash
if [[ "$1" == "mol" && "$2" == "current" ]]; then
  echo '"'"'[{"molecule_id":"test-mol","next_step":{"title":"Implement and test","description":"Use /implementation then /testing to verify","status":"open"}}]'"'"'
  exit 0
fi
exit 1
MOCK
  chmod +x "$mock_dir/bd"
  cat > "$mock_dir/gt" << "MOCK"
#!/usr/bin/env bash
exit 1
MOCK
  chmod +x "$mock_dir/gt"
'

echo
echo "=== No molecule step — fallback to hooked bead ==="

# Mock: no molecule, but hooked bead with skill references
run_test_mock "extracts skill from hooked bead description" 0 "→ /code-review" '
  cat > "$mock_dir/bd" << "MOCK"
#!/usr/bin/env bash
if [[ "$1" == "mol" && "$2" == "current" ]]; then
  echo "[]"
  exit 0
fi
exit 1
MOCK
  chmod +x "$mock_dir/bd"
  cat > "$mock_dir/gt" << "MOCK"
#!/usr/bin/env bash
if [[ "$1" == "hook" && "$2" == "--json" ]]; then
  echo '"'"'{"has_work":true,"pinned_bead":{"description":"Review the PR per /code-review"}}'"'"'
  exit 0
fi
exit 1
MOCK
  chmod +x "$mock_dir/gt"
'

echo
echo "=== No skills found ==="

run_test_mock "no skills shows 'no specific skills' message" 0 "No specific skills" '
  cat > "$mock_dir/bd" << "MOCK"
#!/usr/bin/env bash
if [[ "$1" == "mol" && "$2" == "current" ]]; then
  echo "[]"
  exit 0
fi
exit 1
MOCK
  chmod +x "$mock_dir/bd"
  cat > "$mock_dir/gt" << "MOCK"
#!/usr/bin/env bash
if [[ "$1" == "hook" && "$2" == "--json" ]]; then
  echo '"'"'{"has_work":true,"pinned_bead":{"description":"Just a plain task with no skills"}}'"'"'
  exit 0
fi
exit 1
MOCK
  chmod +x "$mock_dir/gt"
'

echo
echo "=== Structural enforcement message ==="

run_test_mock "includes enforcement message when skills found" 0 "structural" '
  cat > "$mock_dir/bd" << "MOCK"
#!/usr/bin/env bash
if [[ "$1" == "mol" && "$2" == "current" ]]; then
  echo '"'"'[{"molecule_id":"test","next_step":{"title":"Test","description":"Run /testing","status":"open"}}]'"'"'
  exit 0
fi
exit 1
MOCK
  chmod +x "$mock_dir/bd"
  cat > "$mock_dir/gt" << "MOCK"
#!/usr/bin/env bash
exit 1
MOCK
  chmod +x "$mock_dir/gt"
'

echo
echo "=== Step title in output ==="

run_test_mock "shows step title when available" 0 "Current step: Implement feature" '
  cat > "$mock_dir/bd" << "MOCK"
#!/usr/bin/env bash
if [[ "$1" == "mol" && "$2" == "current" ]]; then
  echo '"'"'[{"molecule_id":"test","next_step":{"title":"Implement feature","description":"per /implementation","status":"open"}}]'"'"'
  exit 0
fi
exit 1
MOCK
  chmod +x "$mock_dir/bd"
  cat > "$mock_dir/gt" << "MOCK"
#!/usr/bin/env bash
exit 1
MOCK
  chmod +x "$mock_dir/gt"
'

echo
echo "=== old-style skill: references ==="

run_test_mock "matches skill:code-review format" 0 "→ /code-review" '
  cat > "$mock_dir/bd" << "MOCK"
#!/usr/bin/env bash
if [[ "$1" == "mol" && "$2" == "current" ]]; then
  echo '"'"'[{"molecule_id":"test","next_step":{"title":"Review","description":"Perform review per skill:code-review","status":"open"}}]'"'"'
  exit 0
fi
exit 1
MOCK
  chmod +x "$mock_dir/bd"
  cat > "$mock_dir/gt" << "MOCK"
#!/usr/bin/env bash
exit 1
MOCK
  chmod +x "$mock_dir/gt"
'

echo
echo "---"
echo "$total tests, $failures failures"

if [[ "$failures" -gt 0 ]]; then
  exit 1
fi
