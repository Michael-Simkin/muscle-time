#!/usr/bin/env bash
set -euo pipefail

shellcheck scripts/*.sh .claude/hooks/*.sh
