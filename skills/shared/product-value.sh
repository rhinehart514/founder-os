#!/usr/bin/env bash
# product-value.sh — Infer product value map from code signals.
# Works on ANY codebase. No config required.
# Detects core value loop, supporting features, infrastructure, and dead weight.
# Usage: bash skills/shared/product-value.sh [project-dir]
# Output: JSON with per-surface value signals and product value map
set -uo pipefail

PROJECT_DIR="${1:-.}"
CACHE_FILE="$PROJECT_DIR/.claude/cache/product-value.json"
TOPOLOGY_FILE="$PROJECT_DIR/.claude/cache/topology.json"

# Needs topology first
if [[ ! -f "$TOPOLOGY_FILE" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
    bash "$SCRIPT_DIR/product-topology.sh" "$PROJECT_DIR" > /dev/null 2>&1
fi

if [[ ! -f "$TOPOLOGY_FILE" ]]; then
    echo '{"error": "topology generation failed"}'
    exit 1
fi

python3 - "$PROJECT_DIR" "$TOPOLOGY_FILE" "$CACHE_FILE" << 'PYEOF'
import json, os, sys, re, glob
from datetime import datetime

project_dir = sys.argv[1]
topology_file = sys.argv[2]
cache_file = sys.argv[3]

with open(topology_file) as f:
    topo = json.load(f)

surfaces = topo.get("surfaces", {})
edges = topo.get("edges", [])
product_type = topo.get("product_type", "unknown")

# --- Compute inbound/outbound from edges ---
inbound = {}
outbound = {}
for e in edges:
    inbound.setdefault(e["to"], []).append(e)
    outbound.setdefault(e["from"], []).append(e)

# === SIGNAL 1: Code complexity (file size + import count) ===
def measure_complexity(filepath):
    """Measure code investment in a surface."""
    if not filepath or not os.path.exists(filepath):
        return {"lines": 0, "imports": 0, "components": 0, "size_bytes": 0}
    try:
        with open(filepath) as f:
            content = f.read()
        lines = len(content.split("\n"))
        imports = len(re.findall(r'^import\s', content, re.MULTILINE))
        # React components referenced
        components = len(re.findall(r'<[A-Z][a-zA-Z]+', content))
        return {
            "lines": lines,
            "imports": imports,
            "components": components,
            "size_bytes": len(content)
        }
    except:
        return {"lines": 0, "imports": 0, "components": 0, "size_bytes": 0}

# === SIGNAL 2: Auth gates (behind auth = core product) ===
def detect_auth_gate(filepath):
    """Check if a page requires authentication."""
    if not filepath or not os.path.exists(filepath):
        return "unknown"
    try:
        with open(filepath) as f:
            content = f.read()
        # Common auth patterns
        auth_patterns = [
            r'useAuth|useSession|useUser|getServerSession|getSession',
            r'requireAuth|withAuth|AuthGuard|ProtectedRoute|auth-guard',
            r'middleware.*auth|isAuthenticated|checkAuth',
            r'redirect.*login|redirect.*auth|redirect.*sign',
            r'getToken|verifyToken|validateSession',
        ]
        for pat in auth_patterns:
            if re.search(pat, content):
                return "authenticated"
        # Public page signals
        public_patterns = [
            r'landing|marketing|pricing|about|terms|privacy|legal',
        ]
        for pat in public_patterns:
            if re.search(pat, content, re.IGNORECASE):
                return "public"
        return "unknown"
    except:
        return "unknown"

# === SIGNAL 3: Page category from URL structure ===
def categorize_surface(sid, surf_type):
    """Infer what kind of product surface this is."""
    name = sid.lower()

    # --- CLI / skill surfaces ---
    if surf_type in ("skill", "cli"):
        # CLI infrastructure (library scripts, helpers)
        if any(x in name for x in ["cli/lib", "cli/compute-", "cli/detect-",
                                     "cli/maturity-", "cli/statusline"]):
            return "infrastructure"
        # CLI measurement (scoring, eval)
        if any(x in name for x in ["score", "eval", "bench", "self"]):
            return "measurement"
        # CLI onboarding
        if any(x in name for x in ["init", "onboard", "install"]):
            return "onboarding"
        # Skill categories
        if any(x in name for x in ["skill/plan", "skill/go", "skill/eval",
                                     "skill/taste", "skill/score"]):
            return "core"
        if any(x in name for x in ["skill/research", "skill/ideate", "skill/strategy",
                                     "skill/discover", "skill/product"]):
            return "intelligence"
        if any(x in name for x in ["skill/ship", "skill/roadmap", "skill/retro"]):
            return "lifecycle"
        if any(x in name for x in ["skill/configure", "skill/calibrate"]):
            return "settings"
        if any(x in name for x in ["skill/assert", "skill/todo", "skill/feature"]):
            return "supporting"
        # Default CLI
        return "core"

    # --- Web/API surfaces ---
    # Infrastructure (not user value)
    if any(x in name for x in ["api/health", "api/cron", "api/internal", "api/debug",
                                 "api/admin", "design-system", "api/dev-"]):
        return "infrastructure"

    # Auth flow
    if any(x in name for x in ["auth", "login", "signup", "register", "verify",
                                 "forgot", "reset", "magic-link", "start/email",
                                 "start/verify"]):
        return "auth"

    # Onboarding
    if any(x in name for x in ["onboard", "welcome", "setup", "start", "getting-started"]):
        return "onboarding"

    # Legal/compliance
    if any(x in name for x in ["legal", "terms", "privacy", "cookie", "gdpr"]):
        return "compliance"

    # Settings/profile management
    if any(x in name for x in ["settings", "preferences", "account", "profile/edit",
                                 "profile/settings"]):
        return "settings"

    # Admin
    if "admin" in name:
        return "admin"

    # Core product (everything else that's user-facing)
    return "core"

# === SIGNAL 4: Git activity (recent changes = active development) ===
def get_git_activity(filepath):
    """Count recent commits touching this file."""
    if not filepath:
        return 0
    import subprocess
    try:
        result = subprocess.run(
            ["git", "log", "--oneline", "--since=30 days ago", "--", filepath],
            capture_output=True, text=True, timeout=5,
            cwd=project_dir
        )
        return len(result.stdout.strip().split("\n")) if result.stdout.strip() else 0
    except:
        return 0

# === SIGNAL 5: API dependency count (pages that call more APIs = richer features) ===
def count_api_deps(sid):
    """Count how many API routes this surface calls."""
    return sum(1 for e in outbound.get(sid, []) if e.get("type") == "api_call")

# === Analyze each surface ===
value_map = {}
for sid, surf in surfaces.items():
    if surf["type"] in ("hook",):
        continue

    filepath = surf.get("file")
    full_path = os.path.join(project_dir, filepath) if filepath else None

    category = categorize_surface(sid, surf.get("type", ""))
    complexity = measure_complexity(full_path)
    auth = detect_auth_gate(full_path)
    api_deps = count_api_deps(sid)
    inbound_count = len(inbound.get(sid, []))
    outbound_count = len(outbound.get(sid, []))

    # === Compute value score (0-100) ===
    score = 0

    # Category weight
    category_weights = {
        "core": 40,
        "measurement": 35,
        "onboarding": 35,
        "intelligence": 30,
        "auth": 25,
        "supporting": 25,
        "lifecycle": 20,
        "settings": 15,
        "admin": 10,
        "compliance": 5,
        "infrastructure": 5
    }
    score += category_weights.get(category, 20)

    # Complexity (more code investment = more value, diminishing returns)
    if complexity["lines"] > 200:
        score += 15
    elif complexity["lines"] > 50:
        score += 10
    elif complexity["lines"] > 10:
        score += 5

    # Components used (rich UI = user-facing value)
    if complexity["components"] > 10:
        score += 10
    elif complexity["components"] > 3:
        score += 5

    # Auth gated (behind auth = core product, not marketing)
    if auth == "authenticated":
        score += 10

    # Connectivity (more connected = more central)
    if inbound_count >= 5:
        score += 10
    elif inbound_count >= 2:
        score += 5

    # API dependencies (richer features call more APIs)
    if api_deps >= 3:
        score += 10
    elif api_deps >= 1:
        score += 5

    # CLI-specific: data flow connectivity (reads/writes many files = central)
    reads_count = len(surf.get("reads", []))
    writes_count = len(surf.get("writes", []))
    if reads_count + writes_count >= 5:
        score += 10
    elif reads_count + writes_count >= 2:
        score += 5

    # CLI-specific: next-command references (skills that lead to many others = hubs)
    next_count = len(surf.get("next", []))
    if next_count >= 5:
        score += 10
    elif next_count >= 2:
        score += 5

    # Cap at 100
    score = min(score, 100)

    value_map[sid] = {
        "category": category,
        "value_score": score,
        "auth": auth,
        "complexity": complexity,
        "api_deps": api_deps,
        "inbound": inbound_count,
        "outbound": outbound_count,
        "feature": surf.get("feature")
    }

# === Identify the value loop ===
# Web: highest-value authenticated pages
# CLI: highest-value core/measurement surfaces
if product_type.startswith("web"):
    core_surfaces = sorted(
        [(sid, v) for sid, v in value_map.items()
         if v["category"] == "core" and v["auth"] in ("authenticated", "unknown")
         and surfaces.get(sid, {}).get("type") == "page"],
        key=lambda x: -x[1]["value_score"]
    )
else:
    core_surfaces = sorted(
        [(sid, v) for sid, v in value_map.items()
         if v["category"] in ("core", "measurement")
         and v["value_score"] >= 50],
        key=lambda x: -x[1]["value_score"]
    )

value_loop = [sid for sid, _ in core_surfaces[:10]]

# === Identify entry points (first thing users see) ===
entry_surfaces = sorted(
    [(sid, v) for sid, v in value_map.items()
     if v["category"] in ("onboarding", "auth") or sid in ("page/index", "page/landing")],
    key=lambda x: -x[1]["value_score"]
)

# === Journey stage detection ===
# Classify each surface by user journey stage
# acquire → activate → engage → retain → monetize
def detect_journey_stage(sid, v, is_cli=False):
    cat = v["category"]

    if is_cli:
        if cat == "onboarding": return "activate"
        if cat == "measurement": return "engage"
        if cat == "core": return "engage"
        if cat == "intelligence": return "retain"
        if cat == "lifecycle": return "retain"
        if cat == "supporting": return "engage"
        if cat in ("settings", "infrastructure"): return "support"
        return "engage"

    # Web journey
    if cat == "compliance": return "acquire"
    if cat == "auth": return "activate"
    if cat == "onboarding": return "activate"
    if cat == "settings": return "retain"
    if cat == "admin": return "support"
    if cat == "infrastructure": return "support"

    # Core pages — classify by depth
    name = sid.lower()
    # Landing, marketing = acquire
    if any(x in name for x in ["landing", "index", "page/waitlist", "page/schools"]):
        return "acquire"
    # First-use core features = engage
    if any(x in name for x in ["feed", "discover", "dashboard", "spaces/browse"]):
        return "engage"
    # Depth features = retain (you have to care to get here)
    if any(x in name for x in ["create", "edit", "analytics", "/settings",
                                 "connections", "rituals", "tools/"]):
        return "retain"
    # Default core = engage
    return "engage"

is_cli = not product_type.startswith("web")

for sid in value_map:
    value_map[sid]["journey_stage"] = detect_journey_stage(sid, value_map[sid], is_cli)

# === Journey funnel ===
journey_stages = ["acquire", "activate", "engage", "retain", "support"]
journey_funnel = {}
for stage in journey_stages:
    stage_surfaces = [(sid, v) for sid, v in value_map.items() if v["journey_stage"] == stage]
    journey_funnel[stage] = {
        "count": len(stage_surfaces),
        "avg_value": round(sum(v["value_score"] for _, v in stage_surfaces) / max(len(stage_surfaces), 1)),
        "top_surfaces": sorted([sid for sid, _ in stage_surfaces],
                                key=lambda s: -value_map[s]["value_score"])[:5]
    }

# === Product model (natural language synthesis) ===
def synthesize_model():
    lines = []

    # What is this product?
    total = len(value_map)
    core_count = sum(1 for v in value_map.values() if v["category"] == "core")
    auth_count = sum(1 for v in value_map.values() if v["auth"] == "authenticated")

    if product_type.startswith("web"):
        page_count = sum(1 for s in surfaces if surfaces[s]["type"] == "page" and not s.startswith("page/api/"))
        api_count = sum(1 for s in surfaces if surfaces[s]["type"] == "api")
        lines.append(f"{product_type} with {page_count} pages and {api_count} API routes.")
        if auth_count > 0:
            lines.append(f"{auth_count} surfaces are auth-gated (the real product).")
    else:
        lines.append(f"{product_type} with {total} surfaces.")

    # What's the core value?
    if value_loop:
        top_names = [s.split("/")[-1] for s in value_loop[:5]]
        lines.append(f"Core value surfaces: {', '.join(top_names)}.")

    # What's the user journey?
    acquire = journey_funnel.get("acquire", {})
    activate = journey_funnel.get("activate", {})
    engage = journey_funnel.get("engage", {})
    retain = journey_funnel.get("retain", {})

    if acquire.get("top_surfaces"):
        lines.append(f"Acquisition: {', '.join(s.split('/')[-1] for s in acquire['top_surfaces'][:3])}.")
    if activate.get("top_surfaces"):
        lines.append(f"Activation: {', '.join(s.split('/')[-1] for s in activate['top_surfaces'][:3])}.")
    if engage.get("top_surfaces"):
        lines.append(f"Engagement: {', '.join(s.split('/')[-1] for s in engage['top_surfaces'][:3])}.")
    if retain.get("top_surfaces"):
        lines.append(f"Retention: {', '.join(s.split('/')[-1] for s in retain['top_surfaces'][:3])}.")

    # Risks
    critical = topo.get("critical_data", {})
    top_risks = sorted(critical.items(), key=lambda x: -x[1]["consumers"])[:3]
    if top_risks:
        risk_strs = [f"{n} ({v['consumers']} consumers)" for n, v in top_risks]
        lines.append(f"Critical dependencies: {', '.join(risk_strs)}.")

    orphan_count = topo.get("stats", {}).get("orphan_count", 0)
    if orphan_count > 10:
        lines.append(f"{orphan_count} orphan surfaces — potential dead code or missing navigation.")

    return " ".join(lines)

product_model = synthesize_model()

# === Category summary ===
categories_summary = {}
for sid, v in value_map.items():
    cat = v["category"]
    categories_summary.setdefault(cat, {"count": 0, "avg_value": 0, "surfaces": []})
    categories_summary[cat]["count"] += 1
    categories_summary[cat]["avg_value"] += v["value_score"]
    categories_summary[cat]["surfaces"].append(sid)

for cat in categories_summary:
    c = categories_summary[cat]
    c["avg_value"] = round(c["avg_value"] / max(c["count"], 1))
    c["surfaces"] = c["surfaces"][:5]

# === Output ===
result = {
    "product_type": product_type,
    "generated_at": datetime.now().isoformat(),
    "product_model": product_model,
    "value_loop": value_loop,
    "entry_points": [sid for sid, _ in entry_surfaces[:5]],
    "journey_funnel": journey_funnel,
    "categories": categories_summary,
    "surfaces": value_map,
    "stats": {
        "total_surfaces": len(value_map),
        "core_count": sum(1 for v in value_map.values() if v["category"] == "core"),
        "auth_gated_count": sum(1 for v in value_map.values() if v["auth"] == "authenticated"),
        "infrastructure_count": sum(1 for v in value_map.values() if v["category"] == "infrastructure"),
        "avg_core_value": round(sum(v["value_score"] for v in value_map.values() if v["category"] == "core") / max(sum(1 for v in value_map.values() if v["category"] == "core"), 1)),
        "value_concentration": round(sum(v["value_score"] for _, v in core_surfaces[:5]) / max(sum(v["value_score"] for v in value_map.values()), 1) * 100),
        "journey_balance": {stage: journey_funnel[stage]["count"] for stage in journey_stages}
    }
}

out = json.dumps(result, indent=2)
os.makedirs(os.path.dirname(cache_file), exist_ok=True)
with open(cache_file, "w") as f:
    f.write(out)
print(out)
PYEOF
