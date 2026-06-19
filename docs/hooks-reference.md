# Cursor Automation Reference

This project previously described legacy hook events. Cursor has its own Hooks system, but event names and configuration must come from the current Cursor documentation. Convert each automation intent to the narrowest Cursor-native mechanism below.

| Former automation intent | Cursor-native replacement |
|--------------------------|-------------------------------|
| Validate commits before push | Git hooks, CI workflow, or Cursor Hook that runs a deterministic script |
| Validate assets after edits | CI job, repository script, Cursor Hook, or asset-audit skill |
| Detect missing project docs at session start | help or project-stage-detect skill |
| Restore state after compaction | Read `production/session-state/active.md` at the start of a resumed workflow |
| Log specialist activity | Append to `production/session-logs/` when the active skill requires audit trail |
| Validate skill changes | Run the `skill-test` skill after editing `.cursor/skills/` |

## Recommended Replacement Pattern

1. Put deterministic checks in scripts, CI, or narrowly scoped Cursor Hooks.
2. Put path-specific guidance in `.cursor/rules/`.
3. Put reusable agent workflows in `.cursor/skills/`, and use `.cursor/agents/` only when separate context or parallel delegation is needed.
4. Put long-running state in files under `production/session-state/`.

## Migration Note

If a document still mentions legacy hook event names such as tool-use, session-start, compaction, or task-start/task-stop events, treat that language as obsolete and rewrite it to one of the mechanisms above.
