#!/usr/bin/env bash
# Cursor adapter for validate-assets.sh.
# Converts Cursor file edit payloads to Claude PostToolUse/Write payloads.

set +e

INPUT=$(cat)
SCRIPT_DIR=$(cd "$(dirname "$0")" 2>/dev/null && pwd -P)
HOOKS_DIR=$(cd "$SCRIPT_DIR/.." 2>/dev/null && pwd -P)
PROJECT_ROOT=$(cd "$SCRIPT_DIR/../../.." 2>/dev/null && pwd -P)
TARGET="$HOOKS_DIR/validate-assets.sh"

json_escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

extract_file_path() {
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$INPUT" | jq -r '
      .tool_input.file_path //
      .file_path //
      .filePath //
      .path //
      .target_file //
      .targetFile //
      .uri //
      .payload.file_path //
      .payload.filePath //
      .payload.path //
      .data.file_path //
      .data.filePath //
      .data.path //
      empty
    ' 2>/dev/null
  else
    printf '%s' "$INPUT" | grep -oE '"(file_path|filePath|path|target_file|targetFile|uri)"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/^[^:]*:[[:space:]]*"//;s/"$//'
  fi
}

FILE_PATH=$(extract_file_path)
if [ -z "$FILE_PATH" ]; then
  echo "Cursor adapter warning: could not extract file path for validate-assets.sh; allowing edit." >&2
  exit 0
fi

if [ ! -f "$TARGET" ]; then
  echo "Cursor adapter warning: missing hook script: $TARGET; allowing edit." >&2
  exit 0
fi

FILE_PATH_ESCAPED=$(json_escape "$FILE_PATH")
CLAUDE_PAYLOAD="{\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"$FILE_PATH_ESCAPED\"}}"

cd "$PROJECT_ROOT" 2>/dev/null || true
printf '%s' "$CLAUDE_PAYLOAD" | bash "$TARGET"
STATUS=$?

if [ "$STATUS" -ne 0 ]; then
  echo "Cursor adapter warning: validate-assets.sh exited with $STATUS; afterFileEdit remains non-blocking." >&2
fi

exit 0
