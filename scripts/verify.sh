#!/usr/bin/env bash
set -euo pipefail

xcodegen generate

swiftformat Sources Tests --lint
swiftlint --strict
actionlint

xcodebuild test \
  -scheme StretchBlocker \
  -destination 'platform=macOS' \
  -derivedDataPath .build/DerivedData \
  | xcbeautify
