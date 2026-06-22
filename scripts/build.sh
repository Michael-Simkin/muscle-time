#!/usr/bin/env bash
set -euo pipefail

xcodegen generate

xcodebuild build \
  -scheme MuscleTime \
  -destination 'platform=macOS' \
  -derivedDataPath .build/DerivedData \
  | xcbeautify
