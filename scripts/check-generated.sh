#!/usr/bin/env bash
set -euo pipefail

generated_paths=(
  Config/Info.plist
  Config/MuscleTime.entitlements
  MuscleTime.xcodeproj
)

before="$(git diff -- "${generated_paths[@]}" | shasum -a 256)"

xcodegen generate

after="$(git diff -- "${generated_paths[@]}" | shasum -a 256)"

if [[ "$before" != "$after" ]]; then
  echo "Generated files changed after xcodegen generate. Review and include generated output."
  git diff --name-only -- "${generated_paths[@]}"
  exit 1
fi
