#!/usr/bin/env bash
set -euo pipefail

plutil -lint Config/Info.plist Config/StretchBlocker.entitlements >/dev/null

assert_plist_value() {
  local file="$1"
  local key="$2"
  local expected="$3"
  local actual

  actual="$(/usr/libexec/PlistBuddy -c "Print :$key" "$file")"

  if [[ "$actual" != "$expected" ]]; then
    echo "$file:$key must be $expected, got $actual."
    exit 1
  fi
}

assert_project_setting() {
  local setting="$1"

  if ! grep -Fq "$setting" project.yml; then
    echo "project.yml must contain: $setting"
    exit 1
  fi
}

assert_plist_value Config/Info.plist LSUIElement true
assert_plist_value Config/Info.plist NSSupportsAutomaticTermination false
assert_plist_value Config/Info.plist NSSupportsSuddenTermination false

assert_plist_value Config/StretchBlocker.entitlements com.apple.security.app-sandbox true
assert_plist_value Config/StretchBlocker.entitlements com.apple.security.files.user-selected.read-only false
assert_plist_value Config/StretchBlocker.entitlements com.apple.security.network.client false

assert_project_setting "SWIFT_STRICT_CONCURRENCY: complete"
assert_project_setting "SWIFT_TREAT_WARNINGS_AS_ERRORS: YES"
assert_project_setting "SWIFT_DEFAULT_ACTOR_ISOLATION: MainActor"
assert_project_setting "ENABLE_HARDENED_RUNTIME: YES"
