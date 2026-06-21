#!/usr/bin/env bash
set -euo pipefail

scripts/check-generated.sh

scripts/lint.sh
scripts/analyze.sh

xcodebuild test \
  -scheme StretchBlocker \
  -destination 'platform=macOS' \
  -derivedDataPath .build/DerivedData \
  | xcbeautify
