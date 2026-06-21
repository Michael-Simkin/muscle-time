#!/usr/bin/env bash
set -euo pipefail

input="$(cat)"
command="$(jq -r '.tool_input.command // ""' <<<"$input")"

if grep -Eiq '(^|[;&|[:space:]])(sudo|rm -rf|git push|xcrun notarytool|codesign|security|curl|wget|nc)([[:space:]]|$)' <<<"$command"; then
  jq -n \
    --arg reason "Blocked risky command: $command" \
    '{
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "deny",
        permissionDecisionReason: $reason
      }
    }'
  exit 0
fi

exit 0
