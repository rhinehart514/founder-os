#!/usr/bin/env bash
# sync-version.sh — Update version in marketplace.json and plugin.json
# Usage: bash bin/sync-version.sh 2.0.1
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

VERSION="${1:-}"
if [[ -z "$VERSION" ]]; then
    echo "Usage: bash bin/sync-version.sh <version>"
    echo "Example: bash bin/sync-version.sh 2.0.1"
    exit 1
fi

# Strip leading 'v' if present
VERSION="${VERSION#v}"

MARKETPLACE="$PROJECT_DIR/.claude-plugin/marketplace.json"
PLUGIN="$PROJECT_DIR/.claude-plugin/plugin.json"

updated=0

for file in "$MARKETPLACE" "$PLUGIN"; do
    if [[ -f "$file" ]]; then
        if command -v jq &>/dev/null; then
            # Use jq for precise updates
            tmp=$(mktemp)
            jq --arg v "$VERSION" '
                if .version then .version = $v else . end |
                if .metadata.version then .metadata.version = $v else . end |
                if .plugins then .plugins = [.plugins[] | .version = $v] else . end
            ' "$file" > "$tmp" && mv "$tmp" "$file"
        else
            # Fallback: sed replacement for "version": "X.Y.Z" patterns
            sed -i '' -E "s/\"version\": *\"[0-9]+\.[0-9]+\.[0-9]+\"/\"version\": \"$VERSION\"/" "$file"
        fi
        echo "  ✓ $(basename "$file") → $VERSION"
        updated=$((updated + 1))
    fi
done

echo "  $updated file(s) updated to v$VERSION"
