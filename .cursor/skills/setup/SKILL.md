---
name: setup
description: 'Use first for install/update routing — sends setup, doctor, or MCP requests to the correct omc setup flow'
---

# Setup

## Cursor Compatibility

This skill is formatted for Cursor Agent Skills. Use Cursor's available tools for file edits, shell commands, search, web access, user questions, and any supported delegation. Treat legacy provider, agent, or workflow-tool examples as workflow guidance; if a named tool is unavailable in Cursor, perform the step with available Cursor capabilities or ask the user before substituting behavior.

Use `/setup` as the unified setup/configuration entrypoint.

## Usage

```bash
/setup                # full setup wizard
/setup doctor         # installation diagnostics
/setup mcp            # MCP server configuration
/setup wizard --local # explicit wizard path
```

## Routing

Process the request by the **first argument only** so install/setup questions land on the right flow immediately:

- No argument, `wizard`, `local`, `global`, or `--force` -> route to `/omc-setup` with the same remaining args
- `doctor` -> route to `/omc-doctor` with everything after the `doctor` token
- `mcp` -> route to `/mcp-setup` with everything after the `mcp` token

Examples:

```bash
/setup --local          # => /omc-setup --local
/setup doctor --json    # => /omc-doctor --json
/setup mcp github       # => /mcp-setup github
```

## Notes

- `/omc-setup`, `/omc-doctor`, and `/mcp-setup` remain valid compatibility entrypoints.
- Prefer `/setup` in new documentation and user guidance.

Task: {{ARGUMENTS}}
