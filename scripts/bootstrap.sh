#!/usr/bin/env bash
set -euo pipefail

brew bundle
xcodegen generate
lefthook install

echo "Bootstrap complete. Run scripts/verify.sh before first commit."
