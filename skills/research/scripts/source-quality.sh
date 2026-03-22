#!/usr/bin/env bash
# Rates research sources by reliability tier
# Usage:
#   bash scripts/source-quality.sh rate "<url-or-source>"   — classify a source
#   bash scripts/source-quality.sh tiers                     — show the hierarchy
#   bash scripts/source-quality.sh audit                     — audit research-log sources
set -euo pipefail

CMD="${1:-tiers}"

# Source reliability tiers (highest to lowest)
# T1: First-party official docs, API references, source code
# T2: Peer-reviewed, official blog posts, context7 docs
# T3: Practitioner blog posts, conference talks, detailed tutorials
# T4: Forum posts (SO, Reddit, HN), community wikis
# T5: LLM-generated content, undated/unattributed posts, SEO content farms

case "$CMD" in
    tiers)
        cat <<'TIERS'
── source reliability tiers ──

  T1 (highest)  First-party docs, API references, source code, codebase grep
                Signal: authored by maintainers, versioned, testable
                Tools: context7, Grep/Glob/Read

  T2            Official blog posts, changelogs, release notes, RFCs
                Signal: authored by known practitioners, dated, specific
                Tools: context7, WebFetch (official domains)

  T3            Practitioner blogs, conference talks, detailed tutorials
                Signal: author has credentials, shows working code, dated
                Tools: WebSearch → WebFetch

  T4            Forum posts (SO, Reddit, HN), community wikis, GitHub issues
                Signal: community-validated (upvotes), but may be outdated
                Tools: WebSearch

  T5 (lowest)   LLM-generated content, undated posts, SEO farms, "Top 10" listicles
                Signal: no author, no date, generic advice, keyword-stuffed
                Tools: WebSearch (avoid these results)

── usage rules ──
  · Always prefer T1-T2 over T3-T5
  · If only T4-T5 available, flag findings as low-confidence
  · Cross-reference T3+ findings against T1-T2 sources
  · context7 is T1/T2 by default — prefer it for library questions
  · Codebase (Grep/Glob) is always T1 — the code is the truth
TIERS
        ;;
    rate)
        SOURCE="${2:-}"
        [[ -z "$SOURCE" ]] && { echo "usage: source-quality.sh rate <url-or-source>"; exit 1; }
        # Simple heuristic classification
        SRC_LOWER=$(echo "$SOURCE" | tr '[:upper:]' '[:lower:]')
        if echo "$SRC_LOWER" | grep -qE '(github\.com/.*/blob|docs\.|api\.|codebase|grep|context7)'; then
            echo "T1  $SOURCE  (first-party/source code)"
        elif echo "$SRC_LOWER" | grep -qE '(blog\.(.*\.com|.*\.dev)|changelog|release-notes|rfc)'; then
            echo "T2  $SOURCE  (official content)"
        elif echo "$SRC_LOWER" | grep -qE '(medium\.com|dev\.to|.*\.substack|youtube\.com|conference)'; then
            echo "T3  $SOURCE  (practitioner content)"
        elif echo "$SRC_LOWER" | grep -qE '(stackoverflow|reddit|news\.ycombinator|github\.com.*issues|wiki)'; then
            echo "T4  $SOURCE  (community/forum)"
        else
            echo "T?  $SOURCE  (unclassified — verify manually)"
        fi
        ;;
    audit)
        DATA_DIR="${CLAUDE_PLUGIN_DATA:-$HOME/.claude/data/research}"
        LOG="$DATA_DIR/research-log.json"
        if [[ ! -f "$LOG" ]]; then
            echo "no research log found"
            exit 0
        fi
        echo "── source audit ──"
        echo "  (source quality tracking requires structured source data in research-log.json)"
        echo "  tip: when logging research, include source URLs for quality auditing"
        ;;
    *)
        echo "usage: source-quality.sh [tiers|rate <source>|audit]"
        ;;
esac
