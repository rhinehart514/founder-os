#!/usr/bin/env bash
# slop-check.sh — Mechanical slop detection for web products.
# Reads anti-slop.md profile and checks product against it.
# Output: crafted | mixed | slop + evidence lines
# Usage: bash scripts/slop-check.sh [project-dir]
set -euo pipefail

PROJECT_DIR="${1:-${CLAUDE_PROJECT_DIR:-$(pwd)}}"
ANTI_SLOP="$PROJECT_DIR/.claude/cache/anti-slop.md"
PKG="$PROJECT_DIR/package.json"

SIGNALS=0
CRAFTED_SIGNALS=0
EVIDENCE=()

echo "── slop check ──"

# --- Check if anti-slop profile exists ---
if [[ -f "$ANTI_SLOP" ]]; then
    echo "  profile: $ANTI_SLOP"
    PROFILE_AGE=$(( ($(date +%s) - $(stat -f "%m" "$ANTI_SLOP" 2>/dev/null || stat -c "%Y" "$ANTI_SLOP" 2>/dev/null)) / 86400 ))
    echo "  age: ${PROFILE_AGE}d"
else
    echo "  profile: missing (using universal taxonomy only)"
    echo "  run: /calibrate anti-slop for category-specific detection"
fi

# --- Package.json dependency analysis ---
echo ""
echo "  ▸ dependency signals"
if [[ -f "$PKG" ]]; then
    # Motion libraries (crafted signal)
    MOTION=false
    for lib in "framer-motion" "react-spring" "gsap" "@formkit/auto-animate" "motion" "lenis" "@motionone"; do
        if grep -q "\"$lib" "$PKG" 2>/dev/null; then
            echo "    ✓ motion: $lib"
            MOTION=true
            CRAFTED_SIGNALS=$((CRAFTED_SIGNALS + 1))
        fi
    done
    if [[ "$MOTION" = false ]]; then
        echo "    · no motion library — static cap applies"
        SIGNALS=$((SIGNALS + 1))
        EVIDENCE+=("no-motion-library")
    fi

    # Custom visualization (crafted signal)
    for lib in "three" "@react-three" "d3" "recharts" "visx" "nivo" "lottie" "rive"; do
        if grep -q "\"$lib" "$PKG" 2>/dev/null; then
            echo "    ✓ custom viz: $lib"
            CRAFTED_SIGNALS=$((CRAFTED_SIGNALS + 1))
        fi
    done

    # UI framework defaults (slop signal if unmodified)
    SHADCN=false
    if grep -q '"@radix-ui' "$PKG" 2>/dev/null || [[ -d "$PROJECT_DIR/components/ui" ]]; then
        SHADCN=true
        echo "    · shadcn/radix detected"
    fi

    # Check if shadcn is customized
    if [[ "$SHADCN" = true ]]; then
        # Look for custom theme or tailwind extensions
        TW_CUSTOM=false
        for f in tailwind.config.ts tailwind.config.js tailwind.config.mjs; do
            if [[ -f "$PROJECT_DIR/$f" ]]; then
                # Check for meaningful theme extension (not just content paths)
                EXTEND_LINES=$(grep -A 50 'extend' "$PROJECT_DIR/$f" 2>/dev/null | grep -c '\(colors\|spacing\|borderRadius\|fontSize\|fontFamily\|boxShadow\|animation\|keyframes\)' 2>/dev/null || echo 0)
                if [[ "$EXTEND_LINES" -gt 2 ]]; then
                    echo "    ✓ tailwind customized ($EXTEND_LINES theme extensions)"
                    TW_CUSTOM=true
                    CRAFTED_SIGNALS=$((CRAFTED_SIGNALS + 1))
                fi
            fi
        done
        if [[ "$TW_CUSTOM" = false ]]; then
            echo "    · shadcn with default theme — default cap may apply"
            SIGNALS=$((SIGNALS + 1))
            EVIDENCE+=("shadcn-defaults")
        fi
    fi

    # Custom fonts (crafted signal)
    if grep -q '"next/font\|@fontsource\|typekit\|fonts.google' "$PKG" 2>/dev/null; then
        echo "    ✓ custom fonts"
        CRAFTED_SIGNALS=$((CRAFTED_SIGNALS + 1))
    fi
    # Also check source files for next/font
    if find "$PROJECT_DIR" -maxdepth 4 -name "*.ts" -o -name "*.tsx" 2>/dev/null | head -20 | xargs grep -l "next/font" 2>/dev/null | head -1 | grep -q .; then
        echo "    ✓ next/font usage"
        CRAFTED_SIGNALS=$((CRAFTED_SIGNALS + 1))
    fi
else
    echo "    no package.json — skipping web dependency analysis"
fi

# --- CLI slop detection ---
# Detect project type from founder.yml or directory structure
FOUNDER_YML="$PROJECT_DIR/config/founder.yml"
PROJECT_TYPE=""
if [[ -f "$FOUNDER_YML" ]]; then
    PROJECT_TYPE=$(grep 'project_type:' "$FOUNDER_YML" 2>/dev/null | awk '{print $2}' || true)
fi
# Fallback: if bin/ exists and no package.json, likely CLI
if [[ -z "$PROJECT_TYPE" && -d "$PROJECT_DIR/bin" && ! -f "$PKG" ]]; then
    PROJECT_TYPE="cli"
fi

if [[ "$PROJECT_TYPE" == "cli" ]]; then
    echo ""
    echo "  ▸ cli output signals"

    # Check for color/formatting usage (crafted signal)
    COLOR_USAGE=false
    for pattern in "tput" "\\\\033\[" "\\\\e\[" "\\\\x1b\[" "chalk" "kleur" "ansi"; do
        if grep -rl "$pattern" "$PROJECT_DIR/bin/" --include="*.sh" --include="*.js" --include="*.ts" 2>/dev/null | head -1 | grep -q .; then
            COLOR_USAGE=true
            break
        fi
    done
    if [[ "$COLOR_USAGE" = true ]]; then
        echo "    ✓ color/ANSI formatting in output"
        CRAFTED_SIGNALS=$((CRAFTED_SIGNALS + 1))
    else
        echo "    · no color output — wall-of-text risk"
        SIGNALS=$((SIGNALS + 1))
        EVIDENCE+=("cli-no-color")
    fi

    # Check for output hierarchy (headers, sections, bullets)
    HIERARCHY_PATTERNS=0
    for pattern in "echo.*──" "echo.*▸" "echo.*✓" "printf.*%-" "echo.*===" "echo.*---"; do
        if grep -rl "$pattern" "$PROJECT_DIR/bin/" --include="*.sh" 2>/dev/null | head -1 | grep -q .; then
            HIERARCHY_PATTERNS=$((HIERARCHY_PATTERNS + 1))
        fi
    done
    if [[ "$HIERARCHY_PATTERNS" -ge 2 ]]; then
        echo "    ✓ output hierarchy ($HIERARCHY_PATTERNS patterns)"
        CRAFTED_SIGNALS=$((CRAFTED_SIGNALS + 1))
    elif [[ "$HIERARCHY_PATTERNS" -eq 0 ]]; then
        echo "    · no output hierarchy — flag dump risk"
        SIGNALS=$((SIGNALS + 1))
        EVIDENCE+=("cli-no-hierarchy")
    fi

    # Check for helpful error messages vs raw stderr
    ERROR_HANDLING=0
    for pattern in "echo.*error:" "echo.*Error:" "echo.*failed:" ">&2.*echo"; do
        if grep -rl "$pattern" "$PROJECT_DIR/bin/" --include="*.sh" 2>/dev/null | head -1 | grep -q .; then
            ERROR_HANDLING=$((ERROR_HANDLING + 1))
        fi
    done
    if [[ "$ERROR_HANDLING" -ge 2 ]]; then
        echo "    ✓ structured error messages"
        CRAFTED_SIGNALS=$((CRAFTED_SIGNALS + 1))
    elif [[ "$ERROR_HANDLING" -eq 0 ]]; then
        echo "    · no structured errors — stack trace risk"
        SIGNALS=$((SIGNALS + 1))
        EVIDENCE+=("cli-raw-errors")
    fi

    # Check for next-action guidance in output
    NEXT_ACTIONS=$(grep -rl "run:.*\|▸\|→\|next:" "$PROJECT_DIR/bin/" --include="*.sh" 2>/dev/null | wc -l | tr -d ' ')
    if [[ "$NEXT_ACTIONS" -ge 3 ]]; then
        echo "    ✓ next-action guidance ($NEXT_ACTIONS files)"
        CRAFTED_SIGNALS=$((CRAFTED_SIGNALS + 1))
    elif [[ "$NEXT_ACTIONS" -eq 0 ]]; then
        echo "    · no next-action hints — dead-end output"
        SIGNALS=$((SIGNALS + 1))
        EVIDENCE+=("cli-no-next-actions")
    fi
fi

# --- Copy pattern check ---
echo ""
echo "  ▸ copy patterns"
# Search for common slop copy in source files
SLOP_COPY_PATTERNS=(
    "Build.*faster"
    "Supercharge your"
    "platform for modern teams"
    "Loved by.*teams"
    "Simple\. Powerful\."
    "Get started for free"
    "Powered by AI"
    "AI-powered"
    "Revolutionize"
    "Seamlessly integrate"
    "Unlock the power"
    "Take your.*next level"
)

COPY_HITS=0
SRC_DIRS=$(find "$PROJECT_DIR" -maxdepth 3 -type d \( -name "app" -o -name "pages" -o -name "src" -o -name "components" \) -not -path "*/node_modules/*" 2>/dev/null | head -5)

if [[ -n "$SRC_DIRS" ]]; then
    for pattern in "${SLOP_COPY_PATTERNS[@]}"; do
        MATCHES=$(echo "$SRC_DIRS" | xargs -I{} grep -rl "$pattern" {} --include="*.tsx" --include="*.jsx" --include="*.html" --include="*.vue" --include="*.svelte" 2>/dev/null | head -3)
        if [[ -n "$MATCHES" ]]; then
            FIRST_FILE=$(echo "$MATCHES" | head -1)
            FIRST_LINE=$(grep -m1 "$pattern" "$FIRST_FILE" 2>/dev/null | sed 's/^[ \t]*//' | head -c 80)
            echo "    · \"$FIRST_LINE\""
            COPY_HITS=$((COPY_HITS + 1))
        fi
    done
fi

if [[ "$COPY_HITS" -gt 2 ]]; then
    SIGNALS=$((SIGNALS + 2))
    EVIDENCE+=("copy-slop:$COPY_HITS-patterns")
    echo "    $COPY_HITS slop copy patterns found"
elif [[ "$COPY_HITS" -gt 0 ]]; then
    SIGNALS=$((SIGNALS + 1))
    EVIDENCE+=("copy-slop:$COPY_HITS-patterns")
    echo "    $COPY_HITS slop copy patterns found"
else
    echo "    no slop copy detected"
    CRAFTED_SIGNALS=$((CRAFTED_SIGNALS + 1))
fi

# --- Layout pattern check ---
echo ""
echo "  ▸ layout patterns"
# Check for template indicators in source
TEMPLATE_SIGNALS=0

if [[ -n "$SRC_DIRS" ]]; then
    # 3-column feature grid
    THREE_COL=$(echo "$SRC_DIRS" | xargs -I{} grep -rl "grid-cols-3\|columns.*3\|three-column\|features.*grid" {} --include="*.tsx" --include="*.jsx" 2>/dev/null | wc -l | tr -d ' ')
    if [[ "$THREE_COL" -gt 1 ]]; then
        echo "    · 3-column feature grid pattern ($THREE_COL files)"
        TEMPLATE_SIGNALS=$((TEMPLATE_SIGNALS + 1))
    fi

    # Alternating sections
    ALT_SECTIONS=$(echo "$SRC_DIRS" | xargs -I{} grep -rl "flex-row-reverse\|md:flex-row-reverse\|alternate\|even:flex-row-reverse" {} --include="*.tsx" --include="*.jsx" 2>/dev/null | wc -l | tr -d ' ')
    if [[ "$ALT_SECTIONS" -gt 0 ]]; then
        echo "    · alternating left-right sections"
        TEMPLATE_SIGNALS=$((TEMPLATE_SIGNALS + 1))
    fi
fi

if [[ "$TEMPLATE_SIGNALS" -gt 0 ]]; then
    SIGNALS=$((SIGNALS + TEMPLATE_SIGNALS))
    EVIDENCE+=("template-layout:$TEMPLATE_SIGNALS-patterns")
else
    echo "    no template layout patterns detected"
fi

# --- Verdict ---
echo ""
echo "── verdict ──"

TOTAL_SLOP=$SIGNALS
TOTAL_CRAFTED=$CRAFTED_SIGNALS

if [[ "$TOTAL_SLOP" -ge 3 ]]; then
    echo "  verdict: slop"
    echo "  cap: overall capped at 40"
    echo "  evidence: ${EVIDENCE[*]}"
elif [[ "$TOTAL_SLOP" -ge 1 ]]; then
    echo "  verdict: mixed"
    echo "  cap: none (but each pattern flagged)"
    echo "  evidence: ${EVIDENCE[*]}"
    echo "  crafted signals: $TOTAL_CRAFTED"
else
    echo "  verdict: crafted"
    echo "  cap: none"
    echo "  crafted signals: $TOTAL_CRAFTED"
fi

echo ""
echo "  slop signals: $TOTAL_SLOP · crafted signals: $TOTAL_CRAFTED"
