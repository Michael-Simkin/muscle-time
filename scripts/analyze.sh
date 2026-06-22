#!/usr/bin/env bash
set -euo pipefail

xcodegen generate
mkdir -p .build/logs

xcodebuild clean analyze \
  -scheme MuscleTime \
  -destination 'platform=macOS' \
  -derivedDataPath .build/DerivedData \
  2>&1 \
  | tee .build/logs/xcodebuild-analyze.log \
  | xcbeautify

swiftlint analyze --strict --compiler-log-path .build/logs/xcodebuild-analyze.log
