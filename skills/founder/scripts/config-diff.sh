#!/usr/bin/env bash
# Show what's configured vs defaults, highlight non-default values.
# Reads preferences.yml and founder.yml, compares against hardcoded defaults.
set -euo pipefail
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
PREFS_FILE="$HOME/.claude/preferences.yml"
FOUNDER_FILE="$PROJECT_DIR/config/founder.yml"

echo "── config diff ──"
echo ""

# Defaults
DEFAULT_COST="balanced"
DEFAULT_AUTONOMY="supervised"
DEFAULT_VERBOSITY="normal"
DEFAULT_HARD_GATE="true"
DEFAULT_PLATEAU="3"

# Read current values (yq or grep fallback)
read_yaml() {
    local file="$1" key="$2" default="$3"
    if command -v yq &>/dev/null; then
        val=$(yq -r "$key // \"\"" "$file" 2>/dev/null)
        [[ -n "$val" && "$val" != "null" ]] && echo "$val" || echo "$default"
    else
        # Grep fallback — fragile but works for flat keys
        local leaf="${key##*.}"
        val=$(grep -m1 "^\s*$leaf:" "$file" 2>/dev/null | sed 's/.*: *//' | tr -d '"' | tr -d "'" || true)
        [[ -n "$val" ]] && echo "$val" || echo "$default"
    fi
}

# Source: preferences.yml
if [[ -f "$PREFS_FILE" ]]; then
    echo "  source: $PREFS_FILE"
    COST=$(read_yaml "$PREFS_FILE" ".agents.cost" "$DEFAULT_COST")
    AUTONOMY=$(read_yaml "$PREFS_FILE" ".agents.autonomy" "$DEFAULT_AUTONOMY")
    VERBOSITY=$(read_yaml "$PREFS_FILE" ".output.verbosity" "$DEFAULT_VERBOSITY")
    HARD_GATE=$(read_yaml "$PREFS_FILE" ".go.hard_gate" "$DEFAULT_HARD_GATE")
    PLATEAU=$(read_yaml "$PREFS_FILE" ".go.plateau_threshold" "$DEFAULT_PLATEAU")
else
    echo "  source: defaults (no preferences.yml)"
    COST="$DEFAULT_COST"
    AUTONOMY="$DEFAULT_AUTONOMY"
    VERBOSITY="$DEFAULT_VERBOSITY"
    HARD_GATE="$DEFAULT_HARD_GATE"
    PLATEAU="$DEFAULT_PLATEAU"
fi

# Source: founder.yml
echo ""
if [[ -f "$FOUNDER_FILE" ]]; then
    echo "  project: $FOUNDER_FILE"
    STAGE=$(read_yaml "$FOUNDER_FILE" ".project.stage" "unknown")
    MODE=$(read_yaml "$FOUNDER_FILE" ".project.mode" "build")
    PROJECT_NAME=$(read_yaml "$FOUNDER_FILE" ".project.name" "unnamed")
    echo "    name: $PROJECT_NAME  stage: $STAGE  mode: $MODE"
else
    echo "  project: no founder.yml found"
fi

# Display with diff markers
echo ""
echo "  ▾ agents"
if [[ "$COST" != "$DEFAULT_COST" ]]; then
    echo "    cost: $COST  ← override (default: $DEFAULT_COST)"
else
    echo "    cost: $COST"
fi
if [[ "$AUTONOMY" != "$DEFAULT_AUTONOMY" ]]; then
    echo "    autonomy: $AUTONOMY  ← override (default: $DEFAULT_AUTONOMY)"
else
    echo "    autonomy: $AUTONOMY"
fi

echo ""
echo "  ▾ output"
if [[ "$VERBOSITY" != "$DEFAULT_VERBOSITY" ]]; then
    echo "    verbosity: $VERBOSITY  ← override (default: $DEFAULT_VERBOSITY)"
else
    echo "    verbosity: $VERBOSITY"
fi

echo ""
echo "  ▾ go"
if [[ "$HARD_GATE" != "$DEFAULT_HARD_GATE" ]]; then
    echo "    hard_gate: $HARD_GATE  ← override (default: $DEFAULT_HARD_GATE)"
else
    echo "    hard_gate: $HARD_GATE"
fi
if [[ "$PLATEAU" != "$DEFAULT_PLATEAU" ]]; then
    echo "    plateau_threshold: $PLATEAU  ← override (default: $DEFAULT_PLATEAU)"
else
    echo "    plateau_threshold: $PLATEAU"
fi

# Count overrides
OVERRIDES=0
[[ "$COST" != "$DEFAULT_COST" ]] && OVERRIDES=$((OVERRIDES + 1))
[[ "$AUTONOMY" != "$DEFAULT_AUTONOMY" ]] && OVERRIDES=$((OVERRIDES + 1))
[[ "$VERBOSITY" != "$DEFAULT_VERBOSITY" ]] && OVERRIDES=$((OVERRIDES + 1))
[[ "$HARD_GATE" != "$DEFAULT_HARD_GATE" ]] && OVERRIDES=$((OVERRIDES + 1))
[[ "$PLATEAU" != "$DEFAULT_PLATEAU" ]] && OVERRIDES=$((OVERRIDES + 1))

echo ""
echo "  overrides: $OVERRIDES/5"
if [[ "$OVERRIDES" -ge 4 ]]; then
    echo "  ⚠ 4+ overrides — consider whether the defaults should change instead"
fi
