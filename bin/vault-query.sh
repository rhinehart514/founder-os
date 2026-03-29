#!/usr/bin/env bash
# vault-query.sh — Query the Obsidian vault for relevant notes
# Usage:
#   bash bin/vault-query.sh "search terms"              # search all
#   bash bin/vault-query.sh "search terms" --project X   # search project X
#   bash bin/vault-query.sh --project-context X          # get full project context
#   bash bin/vault-query.sh --cross-project "keywords"   # find related across ALL projects
# Falls back to grep if Smart-Connections MCP unavailable.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(pwd)"

# --- Resolve vault path ---
FOUNDER_YML="$PROJECT_DIR/config/founder.yml"
VAULT_PATH=""
if [[ -f "$FOUNDER_YML" ]]; then
    VAULT_PATH=$(grep -A5 'vault:' "$FOUNDER_YML" 2>/dev/null | grep 'path:' | sed 's/.*path:\s*//' | sed 's/#.*//' | xargs || true)
fi
VAULT_PATH="${VAULT_PATH/#\~/$HOME}"
[[ -z "$VAULT_PATH" ]] && VAULT_PATH="$HOME/obsidian-vault"

[[ ! -d "$VAULT_PATH" ]] && { echo "No vault at $VAULT_PATH" >&2; exit 0; }

# --- Parse args ---
MODE="search"
QUERY=""
PROJECT_FILTER=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --project-context)
            MODE="project-context"
            PROJECT_FILTER="${2:-}"
            shift 2 || shift
            ;;
        --cross-project)
            MODE="cross-project"
            QUERY="${2:-}"
            shift 2 || shift
            ;;
        --project)
            PROJECT_FILTER="${2:-}"
            shift 2 || shift
            ;;
        *)
            [[ -z "$QUERY" ]] && QUERY="$1" || QUERY="$QUERY $1"
            shift
            ;;
    esac
done

# --- Project context mode: dump everything we know about a project ---
if [[ "$MODE" == "project-context" && -n "$PROJECT_FILTER" ]]; then
    PROJ_DIR="$VAULT_PATH/Projects/$PROJECT_FILTER"
    if [[ ! -d "$PROJ_DIR" ]]; then
        echo "No vault data for project: $PROJECT_FILTER"
        exit 0
    fi
    echo "## Project Context: $PROJECT_FILTER"
    echo ""
    for f in "$PROJ_DIR"/*.md "$PROJ_DIR"/**/*.md; do
        [[ -f "$f" ]] || continue
        REL="${f#$PROJ_DIR/}"
        echo "### $REL"
        cat "$f"
        echo ""
        echo "---"
        echo ""
    done
    exit 0
fi

# --- Cross-project mode: search across all projects for related learnings ---
if [[ "$MODE" == "cross-project" && -n "$QUERY" ]]; then
    echo "## Cross-Project Intelligence (matching: $QUERY)"
    echo ""

    # Search Knowledge/ (global learnings, predictions, patterns)
    for word in $QUERY; do
        [[ ${#word} -lt 3 ]] && continue
        grep -rl --include="*.md" -i "$word" "$VAULT_PATH/Knowledge" 2>/dev/null | while read -r f; do
            REL="${f#$VAULT_PATH/}"
            echo "### $REL"
            grep -i -B1 -A2 "$word" "$f" 2>/dev/null | head -10
            echo ""
        done
    done

    # Search ALL project dirs (not just current)
    for proj_dir in "$VAULT_PATH/Projects"/*/; do
        [[ -d "$proj_dir" ]] || continue
        PROJ_NAME=$(basename "$proj_dir")
        for word in $QUERY; do
            [[ ${#word} -lt 3 ]] && continue
            HITS=$(grep -rl --include="*.md" -i "$word" "$proj_dir" 2>/dev/null | head -3 || true)
            if [[ -n "$HITS" ]]; then
                while read -r f; do
                    [[ -z "$f" ]] && continue
                    REL="${f#$VAULT_PATH/}"
                    echo "### $REL"
                    grep -i -B1 -A2 "$word" "$f" 2>/dev/null | head -8
                    echo ""
                done <<< "$HITS"
            fi
        done
    done | sort -u
    exit 0
fi

# --- Standard search mode ---
[[ -z "$QUERY" ]] && { echo "Usage: vault-query.sh \"search terms\"" >&2; exit 1; }

# Narrow search scope if project filter set
SEARCH_DIR="$VAULT_PATH"
[[ -n "$PROJECT_FILTER" ]] && SEARCH_DIR="$VAULT_PATH/Projects/$PROJECT_FILTER"

RESULTS=""
for word in $QUERY; do
    [[ ${#word} -lt 3 ]] && continue
    MATCHES=$(grep -rl --include="*.md" -i "$word" "$SEARCH_DIR" 2>/dev/null | head -5 || true)
    [[ -n "$MATCHES" ]] && RESULTS="${RESULTS}${MATCHES}"$'\n'
done

UNIQUE_FILES=$(echo "$RESULTS" | sort -u | head -5)

if [[ -z "$UNIQUE_FILES" ]]; then
    echo "No vault notes matched: $QUERY"
    exit 0
fi

echo "## Vault Notes (matching: $QUERY)"
echo ""
while IFS= read -r filepath; do
    [[ -z "$filepath" ]] && continue
    REL_PATH="${filepath#$VAULT_PATH/}"
    echo "### $REL_PATH"
    head -20 "$filepath"
    echo ""
    echo "---"
    echo ""
done <<< "$UNIQUE_FILES"
