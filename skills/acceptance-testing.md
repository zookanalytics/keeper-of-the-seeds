---
name: acceptance-testing
description: Use when writing acceptance tests before implementation as part of a TEA/ATDD workflow, when a formula step references skill:acceptance-testing
---

# Acceptance Testing (ATDD)

## Overview

Write executable acceptance tests that encode the bead spec's acceptance criteria BEFORE writing implementation code. The tests define "done" in executable form — implementation is complete when they pass.

## When to Use

- Formula step references `skill:acceptance-testing`
- TEA aspect injected a "write acceptance tests" step before implementation
- **When NOT to use:** After implementation is written (that's regular testing, use skill:testing)

## How to Execute

1. **Extract acceptance criteria.** Read the bead spec. List every acceptance criterion, requirement, or "should" statement. Each becomes a test target.

2. **Choose the right test level.** Acceptance tests verify behavior from the outside:
   - CLI tool → test command output and exit codes
   - API → test request/response contracts
   - Library → test public interface behavior
   - Config/formula → test that the artifact is valid and produces expected structure

3. **Write one test per criterion.** Name each test to mirror the criterion it verifies. The test name should read as a specification: `test_rejects_invalid_input_with_400`, not `test_validation`.

4. **Run all tests — confirm they fail.** Every acceptance test MUST fail before implementation. A passing test means either:
   - The behavior already exists (criterion is already met — remove it)
   - The test doesn't actually verify the criterion (fix the test)

5. **Commit failing tests.** Commit with message: `test: add failing acceptance tests for <feature> (<bead-id>)`. The red test commit is the evidence that tests were written first.

## Red Flags

- Writing tests that pass before implementation (they're not testing new behavior)
- Testing implementation details instead of acceptance criteria
- Writing vague tests that would pass with any implementation
- Skipping the "run and verify they fail" step
- Writing tests after implementation and claiming they were first

## Examples

**Without skill:** Agent reads spec, jumps straight to implementation, writes tests afterward that happen to pass. No evidence of test-first. Tests only cover what was implemented, not what was specified.

**With skill:** Agent extracts 4 acceptance criteria from spec, writes 4 tests, runs them (all fail), commits the red tests, then implements. After implementation, all 4 pass. Traceability is trivially verifiable from the git log.
