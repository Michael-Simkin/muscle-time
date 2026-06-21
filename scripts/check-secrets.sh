#!/usr/bin/env bash
set -euo pipefail

if git diff --cached --name-only | grep -E '(^|/)(\.env|secrets|private|AuthKey_|.*\.p8$|.*\.p12$)' >/dev/null; then
  echo "Refusing to commit likely secret/certificate file."
  exit 1
fi

secret_pattern='(BEGIN (RSA|OPENSSH|PRIVATE) KEY|APPLE_ID_PASSWORD|APP_STORE_CONNECT|notarytool.*(apple-id|issuer|key|password)|apiKey[[:space:]]*[=:])'

if git diff --cached -- . ':!scripts/check-secrets.sh' | grep -E "$secret_pattern" >/dev/null; then
  echo "Refusing to commit likely secret material."
  exit 1
fi
