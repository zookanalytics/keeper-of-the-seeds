# Red Test: Rubber Stamp Code Review

## Skill Under Test
`skills/code-review.md`

## Test Type
Red — run WITHOUT the code-review skill loaded.

## Purpose
Verify that agents without the skill rubber-stamp code changes — approving
without structured category-by-category review. Establishes the baseline
failure mode the skill is designed to correct.

## Setup

Spawn a subagent using `subagent_type: "general-purpose"` with NO skill context.

## Diff to Review

```diff
--- a/cmd/sync.go
+++ b/cmd/sync.go
@@ -45,6 +45,22 @@ func runSync(cmd *cobra.Command, args []string) error {
     if err != nil {
         return fmt.Errorf("sync failed: %w", err)
     }
+
+    // Auto-push if remote is configured
+    remote, _ := getRemoteURL()
+    if remote != "" {
+        pushCmd := exec.Command("git", "push", "origin", branch)
+        pushCmd.Env = append(os.Environ(), "GIT_TERMINAL_PROMPT=0")
+        output, err := pushCmd.CombinedOutput()
+        if err != nil {
+            log.Printf("push failed: %s", output)
+        }
+    }
+
+    // Update last-sync timestamp
+    config.Set("sync.last", time.Now().Format(time.RFC3339))
+    config.Save()
+
     return nil
 }
```

## Bead Spec (provided to reviewer)

**Bead: Add auto-push after sync when remote is configured**

After `bd sync` completes, automatically push to origin if a remote URL is
configured. Log a warning if the push fails but don't block the sync.

## Prompt (to agent, no skill loaded)

You've been asked to review the above diff for the bead "Add auto-push after
sync when remote is configured." Please review and provide your assessment.

---

## Expected Failure Behaviors (Red)

Without the skill, agents typically:

1. **No category structure** — review is a blob of prose, not organized by
   correctness/security/error handling/edge cases/API contract
2. **No classification** — findings aren't labeled BLOCK/SHOULD/NIT
3. **Miss the security issue** — `exec.Command("git", "push", ...)` uses a
   hardcoded remote name; `branch` variable may contain injection if unsanitized
4. **Miss the silent failure** — push error is logged but never returned or
   surfaced to the user; the bead says "log a warning" but not whether the
   exit code should reflect it
5. **Miss the config write** — `config.Save()` after `config.Set()` has no
   error handling; if Save fails, the timestamp is in memory but not on disk
6. **Approve overall** — "looks good" or "this is a clean implementation"
7. **No coverage statement** — don't list what was actually checked

Capture exact approval language. Common patterns:
- "The implementation looks correct and matches the spec"
- "This is a clean, minimal change"
- "No issues found, approved"

## Actual Issues a Good Review Should Catch

1. **BLOCK** — `getRemoteURL()` error is silently discarded (`_`). If the
   function errors, we may proceed with an empty string and skip the push
   when we should have pushed — or worse, the error indicates a corrupt config.
2. **BLOCK** — No error handling on `config.Save()`. If save fails, the
   timestamp is lost and subsequent syncs may re-push unnecessarily.
3. **SHOULD** — `branch` variable is used unsanitized in `exec.Command`. While
   cobra args are generally safe, the branch name comes from git and should be
   validated or shell-quoted as defense in depth.
4. **SHOULD** — Push failure is only logged, not returned. The bead says "don't
   block the sync" but should the exit code reflect a partial failure?
5. **NIT** — The `time.Now().Format(time.RFC3339)` could use `time.RFC3339Nano`
   for consistency if other timestamps in the config use nanosecond precision.

## Pass/Fail Criteria

**FAIL (expected for RED test):** Agent approves the diff without catching the
silent error discard, missing `config.Save()` error handling, or unsanitized
branch in exec.Command. No BLOCK/SHOULD/NIT classification.

**PASS (unexpected):** Agent spontaneously applies structured review with
classification and catches the key issues.
