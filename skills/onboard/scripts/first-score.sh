#!/usr/bin/env bash
# Run first score and explain what each number means for a new user.
# Designed for onboarding — adds context that founder score . alone doesn't.
set -euo pipefail
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
FOUNDER_DIR="${FOUNDER_DIR:-$(cd "$(dirname "$0")/../../.." && pwd)}"

echo "── first score ──"
echo ""

# Run the actual score
if [[ -f "$FOUNDER_DIR/bin/score.sh" ]]; then
    SCORE_OUTPUT=$(bash "$FOUNDER_DIR/bin/score.sh" "$PROJECT_DIR" 2>&1) || true
    echo "$SCORE_OUTPUT"
else
    echo "  score.sh not found at $FOUNDER_DIR/bin/score.sh"
    echo "  trying: founder score ."
    SCORE_OUTPUT=$(founder score . 2>&1) || true
    echo "$SCORE_OUTPUT"
fi

echo ""
echo "── what the numbers mean ──"
echo ""
echo "  score (0-100)      overall product health. combines structure + hygiene."
echo "  structure          does the project have the files and organization it needs?"
echo "  hygiene            code cleanliness — unused imports, console.logs, lint overrides."
echo "  assertions         beliefs about your product that are mechanically tested."
echo "                     passing = the product does what you think it does."
echo "                     failing = gap between intent and reality."
echo ""
echo "  30-50  normal for a fresh onboard. the score finds real gaps."
echo "  50-70  solid foundation. features are defined and mostly working."
echo "  70-90  polished. assertions passing, code clean, features delivering."
echo "  90+    exceptional. rare for any product, let alone a new one."
echo ""
echo "  the score is a thermometer, not a thermostat."
echo "  fix the product, not the score."
