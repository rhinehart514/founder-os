#!/usr/bin/env bash
# check-deps.sh — Dependency checker for founder-os scripts.
# Source this file, then call require_cmd for each dependency.
#
# Usage (from any script):
#   source "$(dirname "$0")/lib/check-deps.sh"  # or adjust path
#   require_cmd jq "brew install jq"
#   require_cmd python3 "brew install python3"
#
# On missing dependency: prints warning to stderr and sets FOUNDER_MISSING_DEPS=1.
# Scripts can check FOUNDER_MISSING_DEPS to degrade gracefully.

FOUNDER_MISSING_DEPS=0

require_cmd() {
    local cmd="$1"
    local install_hint="${2:-}"

    if ! command -v "$cmd" &>/dev/null; then
        FOUNDER_MISSING_DEPS=1
        if [[ -n "$install_hint" ]]; then
            echo "WARNING: '$cmd' not found. Install: $install_hint" >&2
        else
            echo "WARNING: '$cmd' not found." >&2
        fi
        return 1
    fi
    return 0
}
