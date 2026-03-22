#!/usr/bin/env bash
# product-brief.sh — Generate a human-readable product brief from code intelligence.
# Reads topology, value, claims, eval-cache. Outputs natural language, not JSON.
# Usage: bash skills/shared/product-brief.sh [project-dir] [section]
# Sections: all, features, journey, risks, gaps, pitch
set -uo pipefail

PROJECT_DIR="${1:-.}"
SECTION="${2:-all}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Ensure intelligence is fresh
VALUE_CACHE="$PROJECT_DIR/.claude/cache/product-value.json"
TOPO_CACHE="$PROJECT_DIR/.claude/cache/topology.json"
EVAL_CACHE="$PROJECT_DIR/.claude/cache/eval-cache.json"
FOUNDER_YML="$PROJECT_DIR/config/founder.yml"
CLAIM_CACHE="$PROJECT_DIR/.claude/cache/claim-verify.json"

# Generate topology + value if missing
[[ ! -f "$TOPO_CACHE" ]] && bash "$SCRIPT_DIR/product-topology.sh" "$PROJECT_DIR" > /dev/null 2>&1
[[ ! -f "$VALUE_CACHE" ]] && bash "$SCRIPT_DIR/product-value.sh" "$PROJECT_DIR" > /dev/null 2>&1

# Run claim verify and cache it
if [[ ! -f "$CLAIM_CACHE" ]] && [[ -f "$FOUNDER_YML" ]] && [[ -f "$SCRIPT_DIR/claim-verify.sh" ]]; then
    bash "$SCRIPT_DIR/claim-verify.sh" "$PROJECT_DIR" > "$CLAIM_CACHE" 2>/dev/null || true
fi

python3 - "$PROJECT_DIR" "$SECTION" "$TOPO_CACHE" "$VALUE_CACHE" "$EVAL_CACHE" "$FOUNDER_YML" "$CLAIM_CACHE" << 'PYEOF'
import json, os, sys, re, textwrap

project_dir = sys.argv[1]
section = sys.argv[2]
topo_file = sys.argv[3]
value_file = sys.argv[4]
eval_file = sys.argv[5]
founder_yml_file = sys.argv[6]
claim_file = sys.argv[7]

# Load data (all optional)
topo = {}
if os.path.exists(topo_file):
    with open(topo_file) as f:
        topo = json.load(f)

value = {}
if os.path.exists(value_file):
    with open(value_file) as f:
        value = json.load(f)

eval_data = {}
if os.path.exists(eval_file):
    try:
        with open(eval_file) as f:
            eval_data = json.load(f)
    except:
        pass

claims = {}
if os.path.exists(claim_file):
    try:
        with open(claim_file) as f:
            claims = json.load(f)
    except:
        pass

# Parse features from founder.yml
features = {}
if os.path.exists(founder_yml_file):
    current = None
    in_features = False
    with open(founder_yml_file) as f:
        for line in f:
            s = line.rstrip()
            if s == "features:":
                in_features = True
                continue
            if in_features:
                if s and not s.startswith(" ") and not s.startswith("#"):
                    in_features = False
                    continue
                m = re.match(r'^  ([a-zA-Z0-9_-]+):\s*$', s)
                if m:
                    current = m.group(1)
                    features[current] = {}
                    continue
                if current:
                    fm = re.match(r'^    ([a-zA-Z_-]+):\s*(.+)$', s)
                    if fm:
                        k, v = fm.group(1), fm.group(2).strip().strip('"').strip("'")
                        features[current][k] = v

    # Filter to active
    features = {k: v for k, v in features.items() if v.get("status", "active") in ("active", "proven")}

# Helper
def wrap(text, indent=0):
    prefix = " " * indent
    return textwrap.fill(text, width=72, initial_indent=prefix, subsequent_indent=prefix)

surfaces = topo.get("surfaces", {})
value_surfaces = value.get("surfaces", {})
journey_funnel = value.get("journey_funnel", {})
product_model = value.get("product_model", "")
product_type = topo.get("product_type", value.get("product_type", "unknown"))
critical_data = topo.get("critical_data", {})

# ============================================================
# SECTION: OVERVIEW
# ============================================================
def write_overview():
    print("THE PRODUCT")
    print()

    if product_model:
        print(wrap(product_model))
        print()

    # Project name from directory
    project_name = os.path.basename(os.path.abspath(project_dir)).replace("_", " ").replace("-", " ").title()

    # Hypothesis
    hyp = ""
    if os.path.exists(founder_yml_file):
        with open(founder_yml_file) as f:
            content = f.read()
        m = re.search(r'hypothesis:\s*"([^"]+)"', content)
        if m:
            hyp = m.group(1)

    if hyp:
        print(f"  Hypothesis: {hyp}")
        print()

    # User
    user = ""
    if os.path.exists(founder_yml_file):
        with open(founder_yml_file) as f:
            content = f.read()
        m = re.search(r'user:\s*"([^"]+)"', content)
        if m:
            user = m.group(1)

    if user:
        print(f"  Built for: {user}")
        print()

    # Stats
    stats = value.get("stats", {})
    if stats:
        core = stats.get("core_count", 0)
        auth = stats.get("auth_gated_count", 0)
        infra = stats.get("infrastructure_count", 0)
        print(f"  {core} core surfaces, {auth} behind auth, {infra} infrastructure")
        print()

# ============================================================
# SECTION: FEATURES
# ============================================================
def write_features():
    print("WHAT WE HAVE")
    print()

    if not features:
        # No founder.yml — infer features from value categories
        cats = value.get("categories", {})
        for cat, info in sorted(cats.items(), key=lambda x: -x[1]["avg_value"]):
            if cat in ("infrastructure", "support"):
                continue
            top = info.get("surfaces", [])[:3]
            top_names = [s.split("/")[-1] for s in top]
            print(f"  {cat.upper()} ({info['count']} surfaces, avg value {info['avg_value']})")
            if top_names:
                print(f"    Key surfaces: {', '.join(top_names)}")
            print()
        return

    for fname, feat in sorted(features.items(), key=lambda k: -int(k[1].get("weight", "1"))):
        delivers = feat.get("delivers", "")
        weight = feat.get("weight", "1")
        target = feat.get("for", "")

        # Eval data
        ev = eval_data.get(fname, {})
        score = ev.get("score")
        delivery = ev.get("delivery_score")
        craft = ev.get("craft_score")
        delta = ev.get("delta")
        gaps = ev.get("gaps", [])

        # Claim verification
        claim_feat = claims.get("features", {}).get(fname, {})
        verdict = claim_feat.get("verdict", "")
        pass_rate = claim_feat.get("pass_rate")

        # Journey position from topology
        jpos = topo.get("journey_positions", {}).get(fname, {})
        position = jpos.get("position", "")

        # Maturity label
        maturity = "planned"
        if score is not None:
            if score >= 90: maturity = "proven"
            elif score >= 70: maturity = "polished"
            elif score >= 50: maturity = "working"
            elif score >= 30: maturity = "building"

        # Feature header
        label = f"{fname.upper()}"
        if position:
            label += f" [{position}]"
        label += f" — weight {weight}"
        print(f"  {label}")

        # What it delivers
        if delivers:
            print(f"    {delivers}")
        if target:
            print(f"    For: {target}")

        # Status line
        status_parts = []
        if score is not None:
            status_parts.append(f"{maturity} ({score}/100)")
        if delivery is not None and craft is not None:
            status_parts.append(f"delivery:{delivery} craft:{craft}")
        if delta and delta != "none":
            direction = "↑" if delta == "better" else ("↓" if delta == "worse" else "→")
            status_parts.append(f"trending {direction}")
        if verdict:
            status_parts.append(f"claims: {verdict}")
        if pass_rate is not None:
            status_parts.append(f"({pass_rate}% verified)")

        if status_parts:
            print(f"    Status: {', '.join(status_parts)}")

        # Gaps
        if gaps:
            print(f"    Gaps: {gaps[0][:80]}")
            if len(gaps) > 1:
                print(f"          {gaps[1][:80]}")

        # What's left — based on maturity
        if maturity == "planned":
            print(f"    → Needs: everything. Code doesn't deliver the claim yet.")
        elif maturity == "building":
            print(f"    → Needs: core implementation. Skeleton exists but users can't get value.")
        elif maturity == "working":
            remaining = 100 - (score or 0)
            print(f"    → {remaining} points to polished. Focus on delivery gaps, then craft.")
        elif maturity == "polished":
            print(f"    → Close to proven. Needs external validation or edge case coverage.")

        print()

# ============================================================
# SECTION: JOURNEY
# ============================================================
def write_journey():
    print("THE USER JOURNEY")
    print()

    stages = [
        ("acquire", "How users find us"),
        ("activate", "First experience — signup to first value"),
        ("engage", "Core loop — what they come back for"),
        ("retain", "Depth features — what makes them stay"),
        ("support", "Infrastructure — admin, settings, internals"),
    ]

    for stage, description in stages:
        info = journey_funnel.get(stage, {})
        count = info.get("count", 0)
        if count == 0:
            continue
        avg = info.get("avg_value", 0)
        tops = info.get("top_surfaces", [])

        print(f"  {stage.upper()} — {description}")
        print(f"    {count} surfaces, avg value {avg}")

        if tops:
            top_names = [s.split("/")[-1] for s in tops[:4]]
            print(f"    Key: {', '.join(top_names)}")

        # Commentary
        if stage == "acquire" and count < 5:
            print(f"    ⚠ Thin acquisition layer — how do new users discover this?")
        if stage == "activate" and avg < 40:
            print(f"    ⚠ Low activation value — first experience might be confusing")
        if stage == "engage" and count > 100:
            print(f"    ⚠ {count} engagement surfaces is a lot. Is the core loop clear?")
        if stage == "retain" and count < 3:
            print(f"    ⚠ Few retention surfaces — what makes users come back?")

        print()

    # Funnel balance
    balance = value.get("stats", {}).get("journey_balance", {})
    if balance:
        acquire = balance.get("acquire", 0)
        activate = balance.get("activate", 0)
        engage = balance.get("engage", 0)
        retain = balance.get("retain", 0)

        if acquire > 0 and engage > 0:
            ratio = round(engage / max(acquire, 1))
            if ratio > 15:
                print(wrap(f"  Funnel shape: {acquire} acquire → {activate} activate → {engage} engage → {retain} retain. The product is engagement-heavy — lots to do once inside, but thin on getting people in.", 2))
            elif acquire > engage:
                print(wrap(f"  Funnel shape: {acquire} acquire → {activate} activate → {engage} engage → {retain} retain. More acquisition than engagement — marketing outpaces product depth.", 2))
        print()

# ============================================================
# SECTION: RISKS
# ============================================================
def write_risks():
    print("RISKS")
    print()

    # Critical dependencies
    if critical_data:
        tier1 = [(n, v) for n, v in critical_data.items() if v["consumers"] >= 100]
        if tier1:
            print("  SINGLE POINTS OF FAILURE:")
            for name, info in sorted(tier1, key=lambda x: -x[1]["consumers"])[:5]:
                print(f"    {name}: {info['consumers']} files depend on this.")
                print(f"      If it breaks → {info['consumers']} surfaces go down.")
            print()

    # Orphan risk
    orphan_count = topo.get("stats", {}).get("orphan_count", 0)
    total = topo.get("stats", {}).get("surface_count", 0)
    if orphan_count > 0 and total > 0:
        pct = round(orphan_count / total * 100)
        print(f"  NAVIGATION GAPS:")
        print(f"    {orphan_count}/{total} surfaces ({pct}%) have no detected inbound path.")
        if pct > 50:
            print(f"    Most are likely reached via dynamic routing or client-side nav")
            print(f"    that static analysis can't see. But verify the core pages are")
            print(f"    actually reachable.")
        print()

    # Feature sprawl (from eval)
    if eval_data:
        building = [k for k, v in eval_data.items() if v.get("score") and 30 <= v["score"] <= 60]
        if len(building) > 3:
            names = ", ".join(building[:5])
            print(f"  FEATURE SPRAWL:")
            print(f"    {len(building)} features half-built (30-60 score): {names}")
            print(f"    Pick one. Finish it. Defer the rest.")
            print()

# ============================================================
# SECTION: GAPS
# ============================================================
def write_gaps():
    print("WHAT'S MISSING")
    print()

    # From claims verification
    if claims.get("features"):
        for fname, feat in claims["features"].items():
            if feat.get("verdict") in ("gap", "broken"):
                print(f"  {fname.upper()}: {feat['verdict']}")
                print(f"    Claim: {feat.get('claim', '')}")
                failing = [c for c in feat.get("checks", []) if not c["pass"]]
                for c in failing[:3]:
                    print(f"    ✗ {c['check']}: {c['detail'][:70]}")
                print()

    # From eval gaps
    if eval_data:
        for fname, ev in eval_data.items():
            gaps = ev.get("gaps", [])
            if gaps and ev.get("score", 100) < 70:
                print(f"  {fname.upper()} (score {ev.get('score', '?')}):")
                for g in gaps[:3]:
                    print(f"    · {g[:80]}")
                print()

    # Missing journey stages
    if journey_funnel:
        for stage in ["acquire", "activate"]:
            info = journey_funnel.get(stage, {})
            if info.get("count", 0) == 0:
                print(f"  NO {stage.upper()} SURFACES")
                print(f"    The product has no detected {stage} flow.")
                if stage == "acquire":
                    print(f"    How do new users find this?")
                elif stage == "activate":
                    print(f"    How do new users get started?")
                print()

# ============================================================
# SECTION: PITCH
# ============================================================
def write_pitch():
    print("THE PITCH")
    print()

    # Synthesize from all data
    project_name = os.path.basename(os.path.abspath(project_dir)).replace("_", " ").replace("-", " ").title()

    # What is it?
    hyp = ""
    user = ""
    if os.path.exists(founder_yml_file):
        with open(founder_yml_file) as f:
            content = f.read()
        m = re.search(r'hypothesis:\s*"([^"]+)"', content)
        if m: hyp = m.group(1)
        m = re.search(r'user:\s*"([^"]+)"', content)
        if m: user = m.group(1)

    if hyp:
        print(f"  {project_name}: {hyp}")
    else:
        # Infer from value loop
        vl = value.get("value_loop", [])
        if vl:
            feature_names = [s.split("/")[-1] for s in vl[:4]]
            print(f"  {project_name}: {', '.join(feature_names)} — and more.")

    if user:
        print(f"  For: {user}")
    print()

    # What works?
    if features:
        working = [(k, v) for k, v in eval_data.items() if v.get("score", 0) >= 50]
        if working:
            print("  What works today:")
            for fname, ev in sorted(working, key=lambda x: -x[1].get("score", 0)):
                delivers = features.get(fname, {}).get("delivers", fname)
                print(f"    ✓ {delivers}")
            print()

    # What's next?
    if features:
        building = [(k, v) for k, v in eval_data.items() if v.get("score", 0) < 50 and v.get("score", 0) > 0]
        if building:
            print("  What's in progress:")
            for fname, ev in sorted(building, key=lambda x: -int(features.get(x[0], {}).get("weight", "1"))):
                delivers = features.get(fname, {}).get("delivers", fname)
                print(f"    · {delivers} ({ev.get('score', '?')}/100)")
            print()

    # Strength
    vl = value.get("value_loop", [])
    if vl:
        top_name = vl[0].split("/")[-1]
        top_v = value.get("surfaces", {}).get(vl[0], {})
        print(f"  Strongest surface: {top_name} (value score {top_v.get('value_score', '?')})")
        print()

# ============================================================
# MAIN
# ============================================================
sections = {
    "all": [write_overview, write_features, write_journey, write_risks, write_gaps, write_pitch],
    "features": [write_features],
    "journey": [write_journey],
    "risks": [write_risks],
    "gaps": [write_gaps],
    "pitch": [write_pitch],
}

writers = sections.get(section, sections["all"])
for i, writer in enumerate(writers):
    if i > 0:
        print("─" * 60)
        print()
    writer()

PYEOF
