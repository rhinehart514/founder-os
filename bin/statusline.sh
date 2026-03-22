#!/usr/bin/env bash
# founder-os status line v8.1
# Line 1: project · branch · score (anchor)
# Line 2: session-aware — surfaces the most relevant signal right now

input=$(cat)
model=$(echo "$input" | jq -r '.model.display_name // "?"')
current_dir=$(echo "$input" | jq -r '.workspace.current_dir // empty')
project=$(basename "$current_dir" 2>/dev/null || echo "?")

# Git
git_branch=$(cd "$current_dir" 2>/dev/null && GIT_OPTIONAL_LOCKS=0 git rev-parse --abbrev-ref HEAD 2>/dev/null || true)
dirty=$(cd "$current_dir" 2>/dev/null && GIT_OPTIONAL_LOCKS=0 git diff --quiet 2>/dev/null || echo "·")

# Colors
G='\033[32m'   # green
Y='\033[33m'   # yellow
R='\033[31m'   # red
C='\033[36m'   # cyan
M='\033[35m'   # magenta
B='\033[1m'    # bold
D='\033[2m'    # dim
N='\033[0m'    # reset

# --- Read state (fast — all from cached files, no CLI calls) ---

cache="$current_dir/.claude/cache/score-cache.json"
eval_cache="$current_dir/.claude/cache/eval-cache.json"
predictions="$HOME/.claude/knowledge/predictions.tsv"
[ -f "$current_dir/.claude/knowledge/predictions.tsv" ] && predictions="$current_dir/.claude/knowledge/predictions.tsv"
todos="$current_dir/.claude/plans/todos.yml"
roadmap="$current_dir/.claude/plans/roadmap.yml"
sessions_dir="$current_dir/.claude/sessions"

score=""
if [ -f "$cache" ]; then
    score=$(jq -r '.score // empty' "$cache" 2>/dev/null)
fi

# Product completion (the real number — eval scores × feature weights)
completion=""
founder_yml="$current_dir/config/founder.yml"
if [ -f "$eval_cache" ] && [ -f "$founder_yml" ]; then
    completion=$(python3 -c "
import json, re
try:
    with open('$eval_cache') as f: ec = json.load(f)
    with open('$founder_yml') as f: lines = f.readlines()
    # Parse features: name → {weight, status}
    features = {}
    cur = None
    for line in lines:
        m = re.match(r'^  (\w[\w-]*):\s*$', line)
        if m and cur is None:
            pass  # skip non-feature sections
        fm = re.match(r'^  (\w[\w-]*):\s*$', line)
        if fm:
            cur = fm.group(1)
            features[cur] = {'weight': 1, 'status': 'active'}
        elif cur:
            wm = re.match(r'\s+weight:\s*(\d+)', line)
            if wm: features[cur]['weight'] = int(wm.group(1))
            sm = re.match(r'\s+status:\s*(\w+)', line)
            if sm: features[cur]['status'] = sm.group(1)
            if re.match(r'^  \w', line) and not re.match(r'^\s{4,}', line):
                cur = None
    total_w, total_s = 0, 0
    for name, data in ec.items():
        s = data.get('score')
        if s is None: continue
        f = features.get(name, {})
        if f.get('status') == 'killed': continue
        w = f.get('weight', 1)
        total_w += w
        total_s += s * w
    if total_w > 0: print(int(total_s / (total_w * 100) * 100))
except: pass
" 2>/dev/null)
fi

# Bottleneck + weakest dimension from eval cache
bottleneck="" weakest_dim="" weakest_val=""
if [ -f "$eval_cache" ] && command -v jq &>/dev/null; then
    # Find lowest-scoring feature
    bottleneck=$(jq -r 'to_entries | sort_by(.value.score // 999) | .[0].key // empty' "$eval_cache" 2>/dev/null)
    if [ -n "$bottleneck" ]; then
        vs=$(jq -r ".\"$bottleneck\".value_score // empty" "$eval_cache" 2>/dev/null)
        qs=$(jq -r ".\"$bottleneck\".quality_score // empty" "$eval_cache" 2>/dev/null)
        us=$(jq -r ".\"$bottleneck\".ux_score // empty" "$eval_cache" 2>/dev/null)
        # Find weakest
        if [ -n "$vs" ] && [ -n "$qs" ] && [ -n "$us" ]; then
            weakest_val=$vs; weakest_dim="v"
            [ "$qs" -lt "$weakest_val" ] 2>/dev/null && weakest_val=$qs && weakest_dim="q"
            [ "$us" -lt "$weakest_val" ] 2>/dev/null && weakest_val=$us && weakest_dim="u"
        fi
    fi
fi

# Ungraded predictions
ungraded=0
if [ -f "$predictions" ]; then
    ungraded=$(awk -F'\t' 'NR>1 && $5 == "" { c++ } END { print c+0 }' "$predictions" 2>/dev/null)
fi

# Stale todos (>14 days)
stale_todos=0
active_todos=0
if [ -f "$todos" ]; then
    active_todos=$(grep -c 'status: active' "$todos" 2>/dev/null || echo 0)
    # Approximate stale: count backlog items (proper decay needs date parsing)
    stale_todos=$(grep -c 'status: backlog' "$todos" 2>/dev/null || echo 0)
fi

# Last session ROI
session_roi=""
if [ -d "$sessions_dir" ]; then
    latest=$(ls -t "$sessions_dir"/*.yml 2>/dev/null | head -1)
    if [ -f "$latest" ]; then
        s_moves=$(grep 'moves:' "$latest" 2>/dev/null | head -1 | sed 's/[^0-9]//g')
        s_delta=$(grep 'delta:' "$latest" 2>/dev/null | head -1 | sed 's/[^0-9+-]//g')
        [ -n "$s_moves" ] && [ -n "$s_delta" ] && [ "$s_moves" -gt 0 ] 2>/dev/null && session_roi="${s_delta}/${s_moves}m"
    fi
fi

# Thesis progress
thesis_pct=""
if [ -f "$roadmap" ]; then
    current_ver=$(grep '^current:' "$roadmap" 2>/dev/null | sed 's/current: *//')
    [ -n "$current_ver" ] && thesis_pct="$current_ver"
fi

# Context pressure
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty' 2>/dev/null)
ctx_warn=""
if [ -n "$used" ] && [ "$used" != "null" ]; then
    used_int=${used%.*}
    [ "$used_int" -ge 80 ] 2>/dev/null && ctx_warn="${R}ctx:${used_int}%${N}"
    [ "$used_int" -ge 50 ] 2>/dev/null && [ "$used_int" -lt 80 ] 2>/dev/null && ctx_warn="${Y}ctx:${used_int}%${N}"
fi

# --- Line 1: anchor ---
printf "${D}◆${N} ${B}%s${N}" "$project"
[ -n "$git_branch" ] && [ "$git_branch" != "HEAD" ] && printf " ${C}%s${N}" "$git_branch"
[ -n "$dirty" ] && printf "${Y}%s${N}" "$dirty"

# Show product completion as primary number — this is the grade toward production
show_num="${completion:-$score}"
if [ -n "$show_num" ] && [ "$show_num" != "null" ]; then
    if [ "$show_num" -ge 80 ] 2>/dev/null; then sc=$G; grade="production-ready"
    elif [ "$show_num" -ge 60 ] 2>/dev/null; then sc=$Y; grade="working"
    elif [ "$show_num" -ge 40 ] 2>/dev/null; then sc=$Y; grade="building"
    else sc=$R; grade="early"; fi
    printf " ${sc}${B}%s${N}${D}%% product complete${N}" "$show_num"
fi
[ -n "$ctx_warn" ] && printf " %b" "$ctx_warn"
printf '\n'

# --- Line 2: session-aware signal (priority order) ---
signal=""

# P0: Context pressure critical
if [ -n "$used" ] && [ "${used%.*}" -ge 85 ] 2>/dev/null; then
    signal="${R}context ${used%.*}% — /compact or start fresh${N}"

# P1: Score regression (delta from eval cache)
elif [ -f "$eval_cache" ] && command -v jq &>/dev/null; then
    worst_delta=$(jq -r '[.[] | .delta // "unknown"] | map(select(. == "worse")) | length' "$eval_cache" 2>/dev/null)
    if [ "$worst_delta" -gt 0 ] 2>/dev/null; then
        signal="${R}${worst_delta} feature(s) regressed${N} ${D}· /eval to investigate${N}"
    fi
fi

# P2: Ungraded predictions (learning loop leaking)
if [ -z "$signal" ] && [ "$ungraded" -gt 3 ]; then
    signal="${Y}${ungraded} ungraded predictions${N} ${D}· /retro${N}"
fi

# P3: Bottleneck with dimension
if [ -z "$signal" ] && [ -n "$bottleneck" ] && [ -n "$weakest_dim" ]; then
    signal="${D}←${N} ${B}${bottleneck}${N} ${D}${weakest_dim}:${weakest_val}${N}"
    # Add last session ROI if available
    [ -n "$session_roi" ] && signal="${signal} ${D}· last: ${session_roi}${N}"
fi

# P4: Active todos
if [ -z "$signal" ] && [ "$active_todos" -gt 0 ]; then
    signal="${D}${active_todos} active todos · /go${N}"
fi

# P5: Fallback — just show /help hint
if [ -z "$signal" ]; then
    signal="${D}/founder help${N}"
fi

printf "%b\n" "$signal"
