#!/usr/bin/env bash
set -euo pipefail

input="$(cat)"
path="$(jq -r '.tool_input.file_path // .tool_input.path // empty' <<<"$input")"

case "$path" in
  *.swift)
    swiftformat "$path"
    ;;
  project.yml)
    xcodegen generate
    ;;
esac
