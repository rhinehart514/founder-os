#!/usr/bin/env bash
# demand-from-readme.sh — Extract product context from README and generate
# a stub demand-cache.json with [inferred] evidence labels.
# Output: structured JSON to stdout.
#
# Usage: bash demand-from-readme.sh [project-dir]
set -euo pipefail

PROJECT_DIR="${1:-.}"

# --- Dependency check ---
if ! command -v jq &>/dev/null; then
    echo '{"error": "jq required: brew install jq"}' >&2
    exit 1
fi

# --- Extract project identity ---
PROJECT_NAME=""
DESCRIPTION=""
WHO=""

# Try package.json first (structured data)
if [[ -f "$PROJECT_DIR/package.json" ]]; then
    PROJECT_NAME=$(jq -r '.name // empty' "$PROJECT_DIR/package.json" 2>/dev/null || true)
    DESCRIPTION=$(jq -r '.description // empty' "$PROJECT_DIR/package.json" 2>/dev/null || true)
fi

# Try pyproject.toml
if [[ -z "$DESCRIPTION" && -f "$PROJECT_DIR/pyproject.toml" ]]; then
    DESCRIPTION=$(grep -m1 'description' "$PROJECT_DIR/pyproject.toml" 2>/dev/null |
                  sed 's/.*= *"//' | sed 's/".*//' || true)
fi

# Try Cargo.toml
if [[ -z "$DESCRIPTION" && -f "$PROJECT_DIR/Cargo.toml" ]]; then
    DESCRIPTION=$(grep -m1 'description' "$PROJECT_DIR/Cargo.toml" 2>/dev/null |
                  sed 's/.*= *"//' | sed 's/".*//' || true)
fi

# Read README.md for context
README_CONTENT=""
if [[ -f "$PROJECT_DIR/README.md" ]]; then
    README_CONTENT=$(head -30 "$PROJECT_DIR/README.md" 2>/dev/null || true)

    # Extract title (first # heading or first non-empty line)
    if [[ -z "$PROJECT_NAME" ]]; then
        PROJECT_NAME=$(echo "$README_CONTENT" | grep -m1 '^# ' | sed 's/^# //' |
                       sed 's/ *[—].*//' | sed 's/[[:space:]]*$//' || true)
    fi

    # Extract description (first paragraph after title)
    if [[ -z "$DESCRIPTION" ]]; then
        DESCRIPTION=$(echo "$README_CONTENT" | awk '
            /^# / { found_title=1; next }
            found_title && /^$/ { if (got_blank) exit; got_blank=1; next }
            found_title && /^[^#\[]/ && !/^$/ { print; found_desc=1 }
            found_desc && /^$/ { exit }
        ' | head -3 | tr '\n' ' ' | sed 's/  */ /g; s/^ *//; s/ *$//')
    fi
fi

# Final fallback for project name
if [[ -z "$PROJECT_NAME" ]]; then
    PROJECT_NAME=$(basename "$(cd "$PROJECT_DIR" && pwd)")
fi

# --- Detect who this is for ---
if [[ -n "$README_CONTENT" ]]; then
    WHO=$(echo "$README_CONTENT" | grep -iE '(for |designed for |built for |helps )' |
          head -1 | sed 's/.*[Ff]or //' | sed 's/\..*//' | head -c 100 || true)
fi
[[ -z "$WHO" ]] && WHO="users of $PROJECT_NAME"

# --- Generate stub demand-cache.json ---
GENERATED_DATE=$(date +%Y-%m-%d)

jq -n \
  --arg idea "$PROJECT_NAME" \
  --arg date "$GENERATED_DATE" \
  --arg desc "${DESCRIPTION:-"$PROJECT_NAME project"}" \
  --arg who "$WHO" \
'{
  idea: $idea,
  generated: $date,
  source: "demand-from-readme.sh",
  demand_tier: "stub",
  jobs: [
    {
      type: "functional",
      statement: ("When I need " + $desc + ", I want a tool that handles it reliably, so I can focus on what matters"),
      importance: 7,
      satisfaction: 5,
      opportunity_score: 9,
      evidence_class: "inferred"
    },
    {
      type: "emotional",
      statement: ("When choosing " + $idea + ", I want to feel confident it works, so I can trust it and move on"),
      importance: 6,
      satisfaction: 5,
      opportunity_score: 7,
      evidence_class: "inferred"
    }
  ],
  forces: {
    push: { description: "[inferred] Problem exists based on project description", strength: 5 },
    pull: { description: ("[inferred] " + $idea + " addresses: " + $desc), strength: 5 },
    anxiety: { description: "[inferred] Unknown switching costs — stub needs real validation", strength: 5 },
    habit: { description: "[inferred] Current solution unknown — run /demand for real analysis", strength: 5 },
    net_switching_energy: 0
  },
  packages: [],
  evidence: {
    observed: [],
    stated: [],
    market: [],
    inferred: [
      ("[inferred] Project description: " + $desc),
      ("[inferred] Target user: " + $who),
      "[inferred] Cold-start stub — run /demand new for real JTBD validation"
    ]
  },
  next_step: "Run /demand new for real JTBD analysis with evidence"
}'
