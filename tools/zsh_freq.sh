#!/usr/bin/env bash
# zsh history frequency analysis -> alias/function candidates.
# Handles both plain history and zsh EXTENDED_HISTORY ": <ts>:<dur>;<cmd>".
# Read-only. Usage: bash tools/zsh_freq.sh [histfile]
set -euo pipefail

HIST="${1:-$HOME/.zsh_history}"
[ -f "$HIST" ] || { echo "history file not found: $HIST" >&2; exit 1; }

# Strip the extended-history prefix if present; tolerate invalid bytes.
clean() { sed -E 's/^: [0-9]+:[0-9]+;//' "$HIST" 2>/dev/null | tr -d '\000' ; }

TOTAL=$(clean | grep -cve '^[[:space:]]*$' || true)
echo "history file : $HIST"
echo "total lines  : $TOTAL"
echo

echo "=== Top 25 commands (first word) ==="
clean | awk 'NF{print $1}' | sort | uniq -c | sort -rn | head -25
echo

echo "=== Top 25 full command lines ==="
clean | grep -ve '^[[:space:]]*$' | sort | uniq -c | sort -rn | head -25
echo

echo "=== 15 longest distinct commands (alias candidates) ==="
clean | grep -ve '^[[:space:]]*$' | sort -u \
  | awk '{ print length, $0 }' | sort -rn | head -15 | cut -d' ' -f2-
