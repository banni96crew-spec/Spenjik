#!/usr/bin/env bash
# Cursor adapter for session-stop.sh.
# Runs the copied Stop hook in warning-only mode.

set +e

cat >/dev/null
SCRIPT_DIR=$(cd "$(dirname "$0")" 2>/dev/null && pwd -P)
HOOKS_DIR=$(cd "$SCRIPT_DIR/.." 2>/dev/null && pwd -P)
PROJECT_ROOT=$(cd "$SCRIPT_DIR/../../.." 2>/dev/null && pwd -P)
TARGET="$HOOKS_DIR/session-stop.sh"

if [ ! -f "$TARGET" ]; then
  echo "Cursor adapter warning: missing hook script: $TARGET; allowing stop." >&2
  exit 0
fi

cd "$PROJECT_ROOT" 2>/dev/null || true
bash "$TARGET"
STATUS=$?

if [ "$STATUS" -ne 0 ]; then
  echo "Cursor adapter warning: session-stop.sh exited with $STATUS; stop remains non-blocking." >&2
fi

exit 0
