# Cursor Hooks Migration Report

## Source

- Claude settings read from `settings.json`.
- Claude hook scripts read from `hooks/`.
- Existing `.cursor/` structure: none found before migration.

The workspace root for this run is already the Claude configuration directory, so the source paths are `settings.json` and `hooks/` rather than a nested `.claude/settings.json` and `.claude/hooks/`.

## Claude Hooks Found

| Claude event | Matcher | Script |
| --- | --- | --- |
| `SessionStart` | empty | `session-start.sh` |
| `SessionStart` | empty | `detect-gaps.sh` |
| `PreToolUse` | `Bash` | `validate-commit.sh` |
| `PreToolUse` | `Bash` | `validate-push.sh` |
| `PostToolUse` | `Write|Edit` | `validate-assets.sh` |
| `PostToolUse` | `Write|Edit` | `validate-skill-change.sh` |
| `Notification` | empty | `notify.sh` |
| `PreCompact` | empty | `pre-compact.sh` |
| `PostCompact` | empty | `post-compact.sh` |
| `Stop` | empty | `session-stop.sh` |
| `SubagentStart` | empty | `log-agent.sh` |
| `SubagentStop` | empty | `log-agent-stop.sh` |

Total hook command entries found: 12.

## Scripts Copied

All scripts from `hooks/` were copied to `.cursor/hooks/`:

- `detect-gaps.sh`
- `log-agent-stop.sh`
- `log-agent.sh`
- `notify.sh`
- `post-compact.sh`
- `pre-compact.sh`
- `session-start.sh`
- `session-stop.sh`
- `validate-assets.sh`
- `validate-commit.sh`
- `validate-push.sh`
- `validate-skill-change.sh`

The original `hooks/` directory was not modified or deleted.

## Event Mapping

| Claude event and matcher | Cursor event | Status |
| --- | --- | --- |
| `PreToolUse` with matcher `Bash` | `beforeShellExecution` | Migrated through adapters. |
| `PostToolUse` with matcher `Write|Edit` | `afterFileEdit` | Migrated through adapters in warning-only mode. |
| `Stop` | `stop` | Migrated through adapter in warning-only mode. |

No `UserPromptSubmit`, `PreToolUse` `Read`, `PreToolUse` MCP, or `PostToolUse` `MultiEdit` hook entries were present in `settings.json`.

## Cursor Hooks Created

`.cursor/hooks.json` was created with `version: 1` and these entries:

- `beforeShellExecution`
  - `hooks/adapters/validate-commit-cursor-adapter.sh`
  - `hooks/adapters/validate-push-cursor-adapter.sh`
- `afterFileEdit`
  - `hooks/adapters/validate-assets-cursor-adapter.sh`
  - `hooks/adapters/validate-skill-change-cursor-adapter.sh`
- `stop`
  - `hooks/adapters/session-stop-cursor-adapter.sh`

All command paths are relative to `.cursor/hooks.json`.

## Directly Connected Hooks

None.

The migrated hooks are connected through adapters because the original scripts either expect Claude-style JSON payloads or benefit from explicit fail-open behavior for Cursor. This keeps the original hook logic intact while adapting event payloads at the boundary.

## Adapters Created

- `.cursor/hooks/adapters/validate-commit-cursor-adapter.sh`
  - Reads Cursor shell execution JSON.
  - Extracts a shell command from common fields such as `command`, `shellCommand`, `shell_command`, and nested `payload` or `data` fields.
  - Calls copied `validate-commit.sh` with Claude-like `PreToolUse/Bash` JSON.
  - Preserves exit code `2` as blocking because it runs under `beforeShellExecution`.

- `.cursor/hooks/adapters/validate-push-cursor-adapter.sh`
  - Reads Cursor shell execution JSON.
  - Extracts a shell command from common command fields.
  - Calls copied `validate-push.sh` with Claude-like `PreToolUse/Bash` JSON.
  - Preserves exit code `2` as blocking because it runs under `beforeShellExecution`.

- `.cursor/hooks/adapters/validate-assets-cursor-adapter.sh`
  - Reads Cursor file edit JSON.
  - Extracts a file path from common fields such as `file_path`, `filePath`, `path`, `target_file`, `targetFile`, `uri`, and nested `payload` or `data` fields.
  - Calls copied `validate-assets.sh` with Claude-like `PostToolUse/Write` JSON.
  - Always exits `0` so `afterFileEdit` remains warning-only.

- `.cursor/hooks/adapters/validate-skill-change-cursor-adapter.sh`
  - Reads Cursor file edit JSON.
  - Extracts a file path from common file path fields.
  - Calls copied `validate-skill-change.sh` with Claude-like `PostToolUse/Edit` JSON.
  - Always exits `0` so `afterFileEdit` remains warning-only.

- `.cursor/hooks/adapters/session-stop-cursor-adapter.sh`
  - Discards Cursor stop payload.
  - Calls copied `session-stop.sh`.
  - Always exits `0` so `stop` remains non-blocking.

## Unsupported Hooks

Unsupported hooks are documented in `.cursor/hooks/unsupported/README.md`.

Unsupported count: 7.

Reasons:

- `SessionStart` has no requested Cursor equivalent for session startup context injection.
- `Notification` has no requested Cursor equivalent.
- `PreCompact` and `PostCompact` are Claude context compaction lifecycle events.
- `SubagentStart` and `SubagentStop` are Claude subagent lifecycle events.

## Manual Verification in Cursor

1. Open the project in Cursor and confirm `.cursor/hooks.json` is detected.
2. Run a shell command that is not a git commit or push, for example `git status`; it should pass.
3. Run a shell command shaped like `git commit ...`; the `beforeShellExecution` adapters should invoke commit validation.
4. Run a shell command shaped like `git push ...`; the push validator should warn for protected branches but not block by default.
5. Edit a file under `assets/` and confirm asset validation warnings appear without blocking the edit.
6. Edit a file under `.claude/skills/` and confirm the skill-change advisory appears without blocking the edit.
7. End the Cursor agent/session and confirm `production/session-logs/session-log.md` is updated when applicable.

## Final Checks

- `.cursor/hooks.json` is valid JSON.
- `.cursor/hooks.json` contains `"version": 1`.
- All `.cursor/hooks.json` command paths are relative and point to existing adapter scripts.
- `settings.json` was not modified.
- `hooks/` was not deleted.
- `.cursor/hooks/unsupported/README.md` was created.
