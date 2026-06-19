#!/usr/bin/env bash
# Cursor adapter for validate-push.sh.
# Converts Cursor shell execution payloads to Claude PreToolUse/Bash payloads.

set +e

INPUT=$(cat)
SCRIPT_DIR=$(cd "$(dirname "$0")" 2>/dev/null && pwd -P)
HOOKS_DIR=$(cd "$SCRIPT_DIR/.." 2>/dev/null && pwd -P)
PROJECT_ROOT=$(cd "$SCRIPT_DIR/../../.." 2>/dev/null && pwd -P)
TARGET="$HOOKS_DIR/validate-push.sh"

json_escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

extract_command() {
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$INPUT" | jq -r '
      .tool_input.command //
      .command //
      .shellCommand //
      .shell_command //
      .execution.command //
      .payload.command //
      .data.command //
      .args.command //
      empty
    ' 2>/dev/null
  else
    printf '%s' "$INPUT" | grep -oE '"(command|shellCommand|shell_command)"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/^[^:]*:[[:space:]]*"//;s/"$//'
  fi
}

COMMAND=$(extract_command)
if [ -z "$COMMAND" ]; then
  echo "Cursor adapter warning: could not extract shell command for validate-push.sh; allowing execution." >&2
  exit 0
fi

if [ ! -f "$TARGET" ]; then
  echo "Cursor adapter warning: missing hook script: $TARGET; allowing execution." >&2
  exit 0
fi

COMMAND_ESCAPED=$(json_escape "$COMMAND")
CLAUDE_PAYLOAD="{\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"$COMMAND_ESCAPED\"}}"

cd "$PROJECT_ROOT" 2>/dev/null || true
printf '%s' "$CLAUDE_PAYLOAD" | bash "$TARGET"
STATUS=$?

if [ "$STATUS" -eq 2 ]; then
  exit 2
fi

if [ "$STATUS" -ne 0 ]; then
  echo "Cursor adapter warning: validate-push.sh exited with $STATUS; allowing execution." >&2
fi

exit 0
