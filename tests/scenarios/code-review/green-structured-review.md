# Green Test: Structured Code Review

## Skill Under Test
`skills/code-review.md`

## Test Type
Green — run WITH the code-review skill loaded.

## Purpose
Verify that the code-review skill corrects the rubber-stamp behavior identified
in the red test. The agent should review category-by-category, classify findings,
and catch the key issues.

## Setup

Spawn a subagent using `subagent_type: "general-purpose"` WITH the full text
of `skills/code-review.md` prepended to the prompt.

## Diff to Review

(Same diff as `red-rubber-stamp.md` — the auto-push sync change.)

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

## Bead Spec

**Bead: Add auto-push after sync when remote is configured**

After `bd sync` completes, automatically push to origin if a remote URL is
configured. Log a warning if the push fails but don't block the sync.

## Prompt

[Prepend full contents of `skills/code-review.md` here before running]

---

You've been asked to review the above diff for the bead "Add auto-push after
sync when remote is configured." Please review and provide your assessment.

---

## Expected Green Behaviors

With the skill loaded, the agent should:

1. **Read the bead spec first** — understand what was asked before reviewing code
2. **Review by category** — correctness, security, error handling, edge cases,
   API contract — in that order
3. **Classify findings** — each issue labeled BLOCK, SHOULD, or NIT
4. **Catch the silent error discard** — `getRemoteURL()` error ignored (BLOCK)
5. **Catch missing Save error handling** — `config.Save()` unchecked (BLOCK)
6. **Flag the unsanitized branch** — defense-in-depth concern (SHOULD)
7. **Note push failure semantics** — log-only vs. exit code (SHOULD)
8. **State what was checked** — explicit coverage summary

## Pass/Fail Criteria

**PASS:** Review is structured by category. Findings are classified. At minimum,
catches the two BLOCKs (error discard, unchecked Save). States what was checked.

**FAIL:** Agent still rubber-stamps or omits classification despite having the
skill loaded. If so, run meta-testing.

## Comparison Points

Compare against the red test output. The green output should demonstrate:

- Category-by-category structure instead of prose blob
- BLOCK/SHOULD/NIT classification on each finding
- Specific issues caught that were missed in the red test
- Explicit coverage statement listing what was reviewed
