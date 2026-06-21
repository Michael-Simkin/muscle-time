#!/usr/bin/env bash
set -euo pipefail

swiftformat Sources Tests --lint
swiftlint --strict
actionlint
scripts/lint-shell.sh
scripts/check-app-config.sh
