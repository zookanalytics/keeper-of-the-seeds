# Keeper

Operational system definitions for Gas Town. Formulas, skills, hooks, and checklists.

This is NOT a project codebase. It defines *how work gets done* across all rigs.

## Key paths

- `formulas/` — TOML workflow templates (`bd cook`)
- `skills/` — Markdown execution guides (source of truth)
- `.claude/commands/` — Symlinks to skills (enables slash command invocation)
- `checklists/` — Binary READY/NOT READY gate criteria
- `docs/conventions.md` — Naming and format rules

## Available skills (slash commands)

- `/research` — Problem space investigation before design
- `/implementation` — Spec-to-code execution
- `/testing` — Test writing and execution
- `/code-review` — Structured code review
- `/document-review` — Multi-lens document review
- `/acceptance-testing` — ATDD test-first workflow
- `/pr-merge` — PR-based squash-merge procedure
- `/handoff` — Session handoff to fresh context
