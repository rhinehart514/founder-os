#!/bin/bash
# Check text for slop words and copy quality issues
# Usage: bash scripts/slop-check.sh <file>
# Or: echo "your copy text" | bash scripts/slop-check.sh
# Output: slop detection report

set -euo pipefail

# Read from file argument or stdin
if [ -n "${1:-}" ] && [ -f "$1" ]; then
  TEXT=$(cat "$1")
else
  TEXT=$(cat)
fi

echo "── slop check ──"

# Slop word list (case-insensitive)
SLOP_WORDS=(
  "revolutionary" "cutting-edge" "seamlessly" "leverage" "unlock"
  "empower" "transform" "supercharge" "game-changing" "next-generation"
  "elevate" "robust" "holistic" "synergy" "scalable"
  "streamline" "innovate" "disrupt" "paradigm" "ecosystem"
  "best-in-class" "world-class" "state-of-the-art" "bleeding-edge"
  "actionable insights" "deep dive" "move the needle" "low-hanging fruit"
  "circle back" "touch base" "at the end of the day"
  # 2026-specific dead language
  "ai-powered" "ai co-pilot" "copilot" "10x productivity"
  "powered by gpt" "powered by claude" "powered by llama"
  "we use ai" "agentic" "disruptive"
)

# 2026 dead phrases (multi-word, checked separately)
DEAD_PHRASES=(
  "ai-powered" "ai co-pilot" "10x productivity"
  "powered by gpt" "powered by claude"
  "we use ai to" "our ai can"
)

FOUND=0
for word in "${SLOP_WORDS[@]}"; do
  COUNT=$(echo "$TEXT" | grep -oi "$word" | wc -l | tr -d ' ')
  if [ "$COUNT" -gt 0 ]; then
    echo "  ✗ \"$word\" × $COUNT"
    FOUND=$((FOUND + COUNT))
  fi
done

# Check 2026 dead phrases
for phrase in "${DEAD_PHRASES[@]}"; do
  COUNT=$(echo "$TEXT" | grep -oi "$phrase" | wc -l | tr -d ' ')
  if [ "$COUNT" -gt 0 ]; then
    echo "  ✗ \"$phrase\" × $COUNT (2026 dead language)"
    FOUND=$((FOUND + COUNT))
  fi
done

if [ "$FOUND" -eq 0 ]; then
  echo "  ✓ slop-free"
fi

echo ""

# Quality checks
echo "── quality checks ──"

# Word count
WORDS=$(echo "$TEXT" | wc -w | tr -d ' ')
echo "  words: $WORDS"

# Sentence length (rough check for sentences > 25 words)
LONG_SENTENCES=$(echo "$TEXT" | tr '.' '\n' | awk 'NF > 25 { count++ } END { print count+0 }')
if [ "$LONG_SENTENCES" -gt 0 ]; then
  echo "  ⚠ $LONG_SENTENCES sentences over 25 words"
else
  echo "  ✓ sentence length ok"
fi

# Passive voice indicators (rough)
PASSIVE=$(echo "$TEXT" | grep -oiE '\b(is|are|was|were|been|being)\s+(being\s+)?\w+ed\b' | wc -l | tr -d ' ')
if [ "$PASSIVE" -gt 2 ]; then
  echo "  ⚠ $PASSIVE passive constructions — prefer active voice"
else
  echo "  ✓ active voice"
fi

# Generic value prop check
GENERIC=$(echo "$TEXT" | grep -oiE '(save time|increase productivity|improve workflow|boost efficiency|better results)' | wc -l | tr -d ' ')
if [ "$GENERIC" -gt 0 ]; then
  echo "  ⚠ $GENERIC generic value props — be specific about what changes"
else
  echo "  ✓ no generic value props detected"
fi

echo ""
echo "  total slop: $FOUND words"
if [ "$FOUND" -gt 0 ]; then
  echo "  verdict: REWRITE"
  exit 1
else
  echo "  verdict: CLEAN"
  exit 0
fi
