---
name: ask
description: 'Process-first advisor routing for Codex, Gemini, Grok, or Cursor via `omc ask`, with artifact capture and no raw CLI assembly'
---

# Ask

## Cursor Compatibility

This skill is formatted for Cursor Agent Skills. Use Cursor's available tools for file edits, shell commands, search, web access, user questions, and any supported delegation. Treat legacy provider, agent, or workflow-tool examples as workflow guidance; if a named tool is unavailable in Cursor, perform the step with available Cursor capabilities or ask the user before substituting behavior.

Use the canonical advisor workflow to route a prompt through the local Codex, Gemini, Grok, or Cursor CLI and persist the result as an ask artifact.

## Usage

```bash
/ask <codex|gemini|grok|cursor> <question or task>
```

Examples:

```bash
/ask codex "review this patch from a security perspective"
/ask gemini "suggest UX improvements for this flow"
/ask cursor "draft an implementation plan for issue #123"
/ask cursor "apply this implementation plan"
```

## Routing

**Required execution path — always use this command:**

```bash
omc ask {{ARGUMENTS}}
```

**Do NOT manually construct raw provider CLI commands.** Never run `codex`, `gemini`, `grok`, or `cursor-agent` directly to fulfill this skill. The `omc ask` wrapper handles correct flag selection, artifact persistence, and provider-version compatibility automatically. Manually assembling provider CLI flags will produce incorrect or outdated invocations.

## Requirements

- The selected local CLI must be installed and authenticated.
- Verify availability with the matching command:

```bash
codex --version
gemini --version
grok --version
cursor-agent --version
```

## Artifacts

`omc ask` writes artifacts to:

```text
.workflow/artifacts/ask/<provider>-<slug>-<timestamp>.md
```

Task: {{ARGUMENTS}}
