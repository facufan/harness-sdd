#!/usr/bin/env bash
# PreToolUse(Edit|Write) — bloquea la edición directa de backlog.json.
# La lógica vive en protect-backlog.js (MSYS corrompe backslashes en node -e).
exec node "$(dirname "$0")/protect-backlog.js"
