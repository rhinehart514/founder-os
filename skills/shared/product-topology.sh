#!/usr/bin/env bash
# product-topology.sh — Mechanical product surface graph.
# Maps surfaces, connections, orphans, dead ends, journey depth.
# Works for any product type (CLI, web, API).
# Usage: bash skills/shared/product-topology.sh [project-dir]
# Output: JSON to stdout, cached to .claude/cache/topology.json
set -uo pipefail

PROJECT_DIR="${1:-.}"
CACHE_FILE="$PROJECT_DIR/.claude/cache/topology.json"

# --- Cache check (mtime-based, 5min TTL) ---
if [[ -f "$CACHE_FILE" ]]; then
    cache_age=0
    if [[ "$(uname)" == "Darwin" ]]; then
        cache_age=$(( $(date +%s) - $(stat -f %m "$CACHE_FILE") ))
    else
        cache_age=$(( $(date +%s) - $(stat -c %Y "$CACHE_FILE") ))
    fi
    if [[ $cache_age -lt 300 ]]; then
        cat "$CACHE_FILE"
        exit 0
    fi
fi

# --- Detect product type ---
detect_product_type() {
    local dir="$1"
    if [[ -d "$dir/pages" || -d "$dir/app" ]] && [[ -f "$dir/package.json" ]]; then
        grep -q '"next"' "$dir/package.json" 2>/dev/null && echo "web-nextjs" && return
    fi
    # Monorepo: check apps/*/package.json for next
    if [[ -d "$dir/apps" ]] && [[ -f "$dir/package.json" ]]; then
        for _app_pkg in "$dir"/apps/*/package.json; do
            [[ -f "$_app_pkg" ]] || continue
            grep -q '"next"' "$_app_pkg" 2>/dev/null && echo "web-nextjs-monorepo" && return
            grep -qE '"react"|"vue"|"svelte"' "$_app_pkg" 2>/dev/null && echo "web-monorepo" && return
        done
    fi
    if [[ -d "$dir/src" ]] && [[ -f "$dir/package.json" ]]; then
        grep -qE '"react"|"vue"|"svelte"' "$dir/package.json" 2>/dev/null && echo "web" && return
    fi
    [[ -d "$dir/skills" ]] && echo "cli-plugin" && return
    [[ -d "$dir/bin" ]] && ls "$dir/bin"/*.sh &>/dev/null && echo "cli" && return
    [[ -d "$dir/routes" || -d "$dir/endpoints" || -d "$dir/api" ]] && echo "api" && return
    if [[ -f "$dir/Cargo.toml" ]]; then grep -q '^\[bin\]' "$dir/Cargo.toml" 2>/dev/null && echo "cli-rust" && return; fi
    if [[ -f "$dir/go.mod" ]] && [[ -d "$dir/cmd" ]]; then echo "cli-go" && return; fi
    if [[ -f "$dir/config/founder.yml" ]]; then
        local pt
        pt=$(grep -m1 'product_type:' "$dir/config/founder.yml" 2>/dev/null | sed 's/.*product_type:\s*//' | tr -d '"')
        [[ -n "$pt" ]] && echo "$pt" && return
    fi
    echo "unknown"
}

PRODUCT_TYPE=$(detect_product_type "$PROJECT_DIR")
mkdir -p "$(dirname "$CACHE_FILE")"

# --- Single python3 pass: analyze, print, and cache ---
python3 - "$PROJECT_DIR" "$PRODUCT_TYPE" "$CACHE_FILE" << 'PYEOF'
import json, re, os, sys, glob
from datetime import datetime

project_dir = sys.argv[1]
product_type = sys.argv[2]
cache_file = sys.argv[3]

surfaces = {}
edges = []

# --- 1. Parse skills/*/SKILL.md ---
skills_dir = os.path.join(project_dir, "skills")
SKIP_DIRS = {"founder-mind", "product-lens", "shared"}
if os.path.isdir(skills_dir):
    for skill_path in sorted(glob.glob(os.path.join(skills_dir, "*/SKILL.md"))):
        skill_name = os.path.basename(os.path.dirname(skill_path))
        if skill_name in SKIP_DIRS:
            continue
        surface_id = f"skill/{skill_name}"
        skill_data = {"type": "skill", "feature": None, "next": [], "reads": []}
        try:
            with open(skill_path) as f:
                content = f.read()
        except:
            continue
        # Extract next-command references
        next_cmds = set()
        for m in re.finditer(r'(?:^|[^a-zA-Z/])/([a-z][a-z_-]{1,20})(?:\s|$|[^a-zA-Z])', content):
            cmd = m.group(1)
            if cmd not in (skill_name, "dev", "tmp", "usr", "bin", "etc", "var", "go"):
                next_cmds.add(cmd)
        # Also check for "Run /go" or "suggest /eval" patterns specifically
        for m in re.finditer(r'`/([a-z][a-z_-]+)`', content):
            cmd = m.group(1)
            if cmd != skill_name:
                next_cmds.add(cmd)
        skill_data["next"] = sorted(next_cmds)
        # Extract cache file references
        for m in re.finditer(r'(eval-cache|score-cache|topology|viability-cache|market-context|customer-intel)', content):
            ref = m.group(1)
            if ref not in skill_data["reads"]:
                skill_data["reads"].append(ref)
        surfaces[surface_id] = skill_data
        for cmd in skill_data["next"]:
            edges.append({"from": surface_id, "to": f"skill/{cmd}", "type": "next_command"})

# --- 2. Parse bin/ CLI commands + scan for file I/O ---
DATA_EXTENSIONS = r'\.(?:json|yml|yaml|tsv|md|csv|db|sqlite|env|toml|ini|conf|lock)'

def scan_file_io(filepath):
    """Scan a script/source file for files it reads and writes.
    Works for bash, python, javascript/typescript, go, ruby."""
    reads, writes = set(), set()
    try:
        with open(filepath) as f:
            content = f.read()
    except:
        return [], []

    ext = os.path.splitext(filepath)[1].lower()

    # --- Bash / Shell ---
    if ext in ('.sh', '.bash', '') or content.startswith('#!/'):
        # Read patterns
        for m in re.finditer(r'(?:cat|jq|grep|awk|read|source|\.)[\s]+["\']?([^\s"\'|;]+' + DATA_EXTENSIONS + ')', content):
            reads.add(m.group(1))
        for m in re.finditer(r'\$\(.*?(?:cat|jq)\s+["\']?([^\s"\'|;)]+' + DATA_EXTENSIONS + ')', content):
            reads.add(m.group(1))
        for m in re.finditer(r'-f\s+["\']?([^\s"\']+' + DATA_EXTENSIONS + ')', content):
            reads.add(m.group(1))
        # Write patterns
        for m in re.finditer(r'>\s*["\']?([^\s"\']+' + DATA_EXTENSIONS + ')', content):
            writes.add(m.group(1))
        for m in re.finditer(r'tee\s+["\']?([^\s"\']+' + DATA_EXTENSIONS + ')', content):
            writes.add(m.group(1))

    # --- Python ---
    if ext in ('.py',) or 'import json' in content or 'import yaml' in content:
        for m in re.finditer(r'open\(["\']([^"\']+' + DATA_EXTENSIONS + r')["\']', content):
            path = m.group(1)
            # Check if it's a write mode
            ctx = content[max(0, m.start()-50):m.end()+50]
            if re.search(r'["\']w["\']|["\']a["\']|mode\s*=\s*["\']w', ctx):
                writes.add(path)
            else:
                reads.add(path)
        # json.dump / yaml.dump -> write
        for m in re.finditer(r'(?:json|yaml|toml)\.dump\w*\(.+?["\']([^"\']+' + DATA_EXTENSIONS + r')["\']', content):
            writes.add(m.group(1))
        # json.load / yaml.safe_load -> read
        for m in re.finditer(r'(?:json|yaml|toml)\.(?:safe_)?load\w*\(.+?["\']([^"\']+' + DATA_EXTENSIONS + r')["\']', content):
            reads.add(m.group(1))

    # --- JavaScript / TypeScript ---
    if ext in ('.js', '.ts', '.mjs', '.cjs', '.jsx', '.tsx'):
        # fs.readFileSync / readFile
        for m in re.finditer(r'(?:readFileSync|readFile)\(["\']([^"\']+' + DATA_EXTENSIONS + r')["\']', content):
            reads.add(m.group(1))
        # fs.writeFileSync / writeFile
        for m in re.finditer(r'(?:writeFileSync|writeFile)\(["\']([^"\']+' + DATA_EXTENSIONS + r')["\']', content):
            writes.add(m.group(1))
        # require('./foo.json')
        for m in re.finditer(r'require\(["\']([^"\']+\.json)["\']', content):
            reads.add(m.group(1))
        # import from json
        for m in re.finditer(r'from\s+["\']([^"\']+\.json)["\']', content):
            reads.add(m.group(1))
        # fetch/axios to files (less common but worth catching)
        for m in re.finditer(r'(?:fetch|axios\.get)\(["\']([^"\']*' + DATA_EXTENSIONS + r')["\']', content):
            reads.add(m.group(1))

    # --- Go ---
    if ext == '.go':
        for m in re.finditer(r'os\.(?:Open|ReadFile)\(["\']([^"\']+' + DATA_EXTENSIONS + r')["\']', content):
            reads.add(m.group(1))
        for m in re.finditer(r'os\.(?:Create|WriteFile|OpenFile)\(["\']([^"\']+' + DATA_EXTENSIONS + r')["\']', content):
            writes.add(m.group(1))

    # --- Universal: string literals that look like data file paths ---
    for m in re.finditer(r'["\']([a-zA-Z0-9_./-]+' + DATA_EXTENSIONS + r')["\']', content):
        path = m.group(1)
        if '://' in path or path.startswith('node_modules') or path.startswith('http'):
            continue
        if path not in writes:
            reads.add(path)

    # --- Import graph (JS/TS/Python) — track shared module dependencies ---
    if ext in ('.js', '.ts', '.mjs', '.cjs', '.jsx', '.tsx'):
        for m in re.finditer(r'''(?:import\s+.*?from\s+|require\()['"](@[/\w-]+|\.\.?/[^'"]+)['"]''', content):
            dep = m.group(1)
            # Normalize: @/lib/auth -> lib/auth, @hive/core -> @hive/core
            if dep.startswith('@/'):
                dep = dep[2:]
            reads.add(dep)
    if ext == '.py':
        for m in re.finditer(r'(?:from|import)\s+([\w.]+)', content):
            reads.add(m.group(1))

    # Normalize: extract basename for data files
    def normalize(paths):
        result = []
        for p in paths:
            base = os.path.basename(p.rstrip('"').rstrip("'").rstrip(")"))
            if base and base not in result and not base.startswith('$') and len(base) > 2:
                result.append(base)
        return sorted(result)

    return normalize(reads), normalize(writes)

# Scan bin/ scripts (shell CLIs)
bin_dir = os.path.join(project_dir, "bin")
if os.path.isdir(bin_dir):
    for script in sorted(glob.glob(os.path.join(bin_dir, "*.sh"))):
        name = os.path.basename(script).replace(".sh", "")
        if name.startswith("lib") or name.startswith("_"):
            continue
        file_reads, file_writes = scan_file_io(script)
        surfaces[f"cli/{name}"] = {
            "type": "cli", "feature": None, "next": [],
            "reads": file_reads, "writes": file_writes
        }

# Scan web routes (Next.js pages/app, Express routes, etc.)
# Build list of candidate route dirs — include monorepo apps/*/src/app patterns
route_dirs = ["pages", "app", "src/pages", "src/app", "src/routes", "routes"]
# Monorepo: apps/*/src/app, packages/*/src/app
for mono_root in ["apps", "packages", "services"]:
    mono_path = os.path.join(project_dir, mono_root)
    if os.path.isdir(mono_path):
        for app_name in os.listdir(mono_path):
            app_path = os.path.join(mono_path, app_name)
            if not os.path.isdir(app_path):
                continue
            for sub in ["src/app", "src/pages", "app", "pages", "src/routes"]:
                candidate = os.path.join(mono_root, app_name, sub)
                if os.path.isdir(os.path.join(project_dir, candidate)):
                    route_dirs.append(candidate)

for route_dir in route_dirs:
    full_dir = os.path.join(project_dir, route_dir)
    if not os.path.isdir(full_dir):
        continue
    for ext_pattern in ["**/*.tsx", "**/*.jsx", "**/*.ts", "**/*.js", "**/*.vue", "**/*.svelte"]:
        for page in glob.glob(os.path.join(full_dir, ext_pattern), recursive=True):
            rel = os.path.relpath(page, project_dir)
            # Convert file path to route: app/dashboard/page.tsx -> /dashboard
            route = os.path.dirname(rel).replace(route_dir, "").replace("\\", "/")
            if route.startswith("/"): route = route[1:]
            # Skip layout, loading, error files
            basename = os.path.basename(page).split(".")[0]
            if basename in ("layout", "loading", "error", "not-found", "template"):
                continue
            surface_id = f"page/{route or 'index'}"
            file_reads, file_writes = scan_file_io(page)
            surfaces[surface_id] = {
                "type": "page", "feature": None, "next": [],
                "reads": file_reads, "writes": file_writes,
                "file": rel
            }

# Scan API routes
api_dirs = ["pages/api", "app/api", "src/routes/api", "routes", "api", "src/api"]
for mono_root in ["apps", "packages", "services"]:
    mono_path = os.path.join(project_dir, mono_root)
    if os.path.isdir(mono_path):
        for app_name in os.listdir(mono_path):
            for sub in ["src/app/api", "src/pages/api", "app/api", "pages/api"]:
                candidate = os.path.join(mono_root, app_name, sub)
                if os.path.isdir(os.path.join(project_dir, candidate)):
                    api_dirs.append(candidate)

for api_dir in api_dirs:
    full_dir = os.path.join(project_dir, api_dir)
    if not os.path.isdir(full_dir):
        continue
    for ext_pattern in ["**/*.ts", "**/*.js", "**/*.py", "**/*.go"]:
        for endpoint in glob.glob(os.path.join(full_dir, ext_pattern), recursive=True):
            rel = os.path.relpath(endpoint, project_dir)
            route = os.path.dirname(rel).replace(api_dir, "").replace("\\", "/").strip("/")
            surface_id = f"api/{route or os.path.basename(endpoint).split('.')[0]}"
            file_reads, file_writes = scan_file_io(endpoint)
            surfaces[surface_id] = {
                "type": "api", "feature": None, "next": [],
                "reads": file_reads, "writes": file_writes,
                "file": rel
            }

# Scan Go/Rust/Python CLI entry points
for cmd_dir in ["cmd", "src/cmd", "cli"]:
    full_dir = os.path.join(project_dir, cmd_dir)
    if not os.path.isdir(full_dir):
        continue
    for ext_pattern in ["**/*.go", "**/*.rs", "**/*.py"]:
        for entry in glob.glob(os.path.join(full_dir, ext_pattern), recursive=True):
            rel = os.path.relpath(entry, project_dir)
            name = os.path.basename(os.path.dirname(entry)) if os.path.basename(entry) == "main.go" else os.path.basename(entry).split(".")[0]
            file_reads, file_writes = scan_file_io(entry)
            surfaces[f"cli/{name}"] = {
                "type": "cli", "feature": None, "next": [],
                "reads": file_reads, "writes": file_writes,
                "file": rel
            }

# Also scan skill scripts for I/O
for sid in list(surfaces.keys()):
    if not sid.startswith("skill/"):
        continue
    skill_name = sid.split("/")[1]
    scripts_dir = os.path.join(skills_dir, skill_name, "scripts")
    if os.path.isdir(scripts_dir):
        all_reads, all_writes = [], []
        for script in glob.glob(os.path.join(scripts_dir, "*.sh")):
            fr, fw = scan_file_io(script)
            all_reads.extend(fr)
            all_writes.extend(fw)
        # Merge with existing reads, add writes
        existing_reads = surfaces[sid].get("reads", [])
        surfaces[sid]["reads"] = sorted(set(existing_reads + all_reads))
        surfaces[sid]["writes"] = sorted(set(all_writes))

# --- 3. Parse features from founder.yml ---
founder_yml = os.path.join(project_dir, "config", "founder.yml")
feature_data = {}
if os.path.exists(founder_yml):
    current = None
    in_features = False
    with open(founder_yml) as f:
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
                    feature_data[current] = {"code": [], "commands": [], "skills": [], "internal": [], "status": "active", "weight": 1, "depends_on": []}
                    continue
                if current:
                    fm = re.match(r'^    ([a-zA-Z_-]+):\s*(.+)$', s)
                    if fm:
                        k, v = fm.group(1), fm.group(2).strip().strip('"').strip("'")
                        if k in ("code", "commands", "skills", "internal", "depends_on"):
                            v = [x.strip().strip('"').strip("'") for x in v.strip('[]').split(',') if x.strip()]
                        elif k == "weight":
                            try: v = int(v)
                            except: v = 1
                        feature_data[current][k] = v

    # Bind features to surfaces
    active = {k: v for k, v in feature_data.items() if v.get("status") in ("active", "proven")}
    for fname, feat in active.items():
        for cp in feat.get("code", []):
            bound = False
            # Match skills/plan/SKILL.md -> skill/plan
            skill_match = re.match(r'skills/([^/]+)/SKILL\.md', cp)
            if skill_match:
                sid = f"skill/{skill_match.group(1)}"
                if sid in surfaces:
                    surfaces[sid]["feature"] = fname
                    bound = True
                continue
            # Match bin/score.sh -> cli/score
            base = os.path.basename(cp).replace(".sh", "").replace(".md", "")
            cid = f"cli/{base}"
            if cid in surfaces:
                surfaces[cid]["feature"] = fname
                bound = True
            # Match directory code paths (src/auth/, lib/billing/) -> page/api surfaces
            if not bound and (cp.endswith("/") or os.path.isdir(os.path.join(project_dir, cp))):
                for sid, surf in surfaces.items():
                    if surf.get("file", "").startswith(cp):
                        surfaces[sid]["feature"] = fname
                        bound = True
            # Match individual source files -> surfaces by file path
            if not bound:
                for sid, surf in surfaces.items():
                    if surf.get("file") == cp:
                        surfaces[sid]["feature"] = fname
                        bound = True
                        break
        for cmd in feat.get("commands", []) + feat.get("internal", []):
            parts = cmd.replace("founder ", "").split()
            if parts:
                cid = f"cli/{parts[0]}"
                if cid in surfaces:
                    surfaces[cid]["feature"] = fname
        for dep in feat.get("depends_on", []):
            edges.append({"from": f"feature/{fname}", "to": f"feature/{dep}", "type": "depends_on"})

# --- 4. Parse hooks ---
hooks_file = os.path.join(project_dir, "hooks", "hooks.json")
if os.path.exists(hooks_file):
    try:
        with open(hooks_file) as f:
            hd = json.load(f)
        for event, hooks in hd.items():
            if isinstance(hooks, list):
                for h in hooks:
                    if h.get("command"):
                        sid = f"hook/{event}"
                        if sid not in surfaces:
                            surfaces[sid] = {"type": "hook", "feature": None, "next": [], "reads": []}
    except:
        pass

# --- 5. Web edge detection — scan pages for internal links and API calls ---
def scan_web_edges(filepath, surface_id):
    """Scan a page/component for links to other pages and API calls."""
    found_edges = []
    try:
        with open(filepath) as f:
            content = f.read()
    except:
        return found_edges

    # Internal navigation: Link href, router.push, redirect, useRouter
    for m in re.finditer(r'''(?:href|push|replace|redirect)\s*(?:\(|=)\s*[`"']/?([a-zA-Z][a-zA-Z0-9/_\[\]-]*?)(?:[`"'?#])''', content):
        target_path = m.group(1).strip("/")
        if not target_path or target_path.startswith("http") or target_path.startswith("mailto"):
            continue
        # Map to surface: /dashboard -> page/dashboard, /api/auth -> api/auth
        if target_path.startswith("api/"):
            target_sid = f"api/{target_path[4:]}"
        else:
            target_sid = f"page/{target_path}"
        # Check if target exists (or a parent route exists for dynamic segments)
        if target_sid in surfaces:
            found_edges.append({"from": surface_id, "to": target_sid, "type": "navigation"})
        else:
            # Try parent (spaces/123 -> spaces/[spaceId])
            parts = target_path.split("/")
            for i in range(len(parts), 0, -1):
                parent = "/".join(parts[:i])
                parent_sid = f"page/{parent}" if not parent.startswith("api/") else f"api/{parent[4:]}"
                if parent_sid in surfaces:
                    found_edges.append({"from": surface_id, "to": parent_sid, "type": "navigation"})
                    break

    # API calls: fetch("/api/..."), axios.get/post("/api/...")
    for m in re.finditer(r'''(?:fetch|get|post|put|patch|delete)\s*\(\s*[`"']/?(api/[a-zA-Z0-9/_\[\]-]+?)(?:[`"'?])''', content):
        api_path = m.group(1).strip("/")
        if api_path.startswith("api/"):
            api_path = api_path[4:]
        target_sid = f"api/{api_path}"
        if target_sid in surfaces:
            found_edges.append({"from": surface_id, "to": target_sid, "type": "api_call"})
        else:
            # Try parent route
            parts = api_path.split("/")
            for i in range(len(parts), 0, -1):
                parent = "/".join(parts[:i])
                parent_sid = f"api/{parent}"
                if parent_sid in surfaces:
                    found_edges.append({"from": surface_id, "to": parent_sid, "type": "api_call"})
                    break

    return found_edges

# Scan all page/api surfaces for internal edges
for sid in list(surfaces.keys()):
    surf = surfaces[sid]
    if surf["type"] not in ("page", "api"):
        continue
    filepath = surf.get("file")
    if not filepath:
        continue
    full_path = os.path.join(project_dir, filepath)
    if os.path.exists(full_path):
        web_edges = scan_web_edges(full_path, sid)
        edges.extend(web_edges)

# Also scan hooks/, contexts/, lib/, server/ for API calls
for lib_dir in ["hooks", "contexts", "lib", "server", "services",
                 "src/hooks", "src/contexts", "src/lib", "src/server", "src/services"]:
    candidates = [os.path.join(project_dir, lib_dir)]
    for mono_root in ["apps", "packages"]:
        mono_path = os.path.join(project_dir, mono_root)
        if os.path.isdir(mono_path):
            for app_name in os.listdir(mono_path):
                candidates.append(os.path.join(mono_path, app_name, "src", lib_dir.replace("src/", "")))

    for lib_path in candidates:
        if not os.path.isdir(lib_path):
            continue
        for ext_pattern in ["**/*.ts", "**/*.tsx", "**/*.js", "**/*.jsx"]:
            for lib_file in glob.glob(os.path.join(lib_path, ext_pattern), recursive=True):
                lib_sid = f"lib/{os.path.basename(lib_file).split('.')[0]}"
                lib_edges = scan_web_edges(lib_file, lib_sid)
                edges.extend(lib_edges)

# Also scan components/ directories for navigation (nav bars, sidebars link to pages)
for comp_dir in ["components", "src/components"]:
    # Include monorepo paths
    candidates = [os.path.join(project_dir, comp_dir)]
    for mono_root in ["apps", "packages"]:
        mono_path = os.path.join(project_dir, mono_root)
        if os.path.isdir(mono_path):
            for app_name in os.listdir(mono_path):
                candidates.append(os.path.join(mono_path, app_name, "src", "components"))
                candidates.append(os.path.join(mono_path, app_name, "components"))

    for comp_path in candidates:
        if not os.path.isdir(comp_path):
            continue
        for ext_pattern in ["**/*.tsx", "**/*.jsx", "**/*.vue", "**/*.svelte"]:
            for comp_file in glob.glob(os.path.join(comp_path, ext_pattern), recursive=True):
                rel = os.path.relpath(comp_file, project_dir)
                comp_sid = f"component/{os.path.basename(comp_file).split('.')[0]}"
                comp_edges = scan_web_edges(comp_file, comp_sid)
                # Attribute component edges to "component/*" source
                edges.extend(comp_edges)

# --- 6. Graph metrics ---
inbound, outbound = {}, {}
for e in edges:
    inbound.setdefault(e["to"], []).append(e["from"])
    outbound.setdefault(e["from"], []).append(e["to"])

orphans = [s for s in surfaces if surfaces[s]["type"] not in ("hook",) and not inbound.get(s)]
dead_ends = [s for s in surfaces if surfaces[s]["type"] not in ("hook", "cli") and not outbound.get(s) and not surfaces[s].get("next")]

entry_points = []
for s in surfaces:
    if surfaces[s]["type"] != "skill":
        continue
    name = s.split("/")[1]
    if name in ("onboard", "founder"):
        entry_points.append(s)
    elif len(outbound.get(s, [])) > 5 and len(inbound.get(s, [])) < 3:
        entry_points.append(s)

# BFS depth
avg_depth = 0
if entry_points:
    depths = []
    for ep in entry_points:
        visited = set()
        q = [(ep, 0)]
        while q:
            node, d = q.pop(0)
            if node in visited: continue
            visited.add(node)
            depths.append(d)
            for t in outbound.get(node, []):
                if t in surfaces:
                    q.append((t, d + 1))
    if depths:
        avg_depth = round(sum(depths) / len(depths), 1)

# --- 6. Journey positions ---
# Count how connected each feature is via its surfaces in the skill graph
journey_positions = {}
for fname, feat in feature_data.items():
    if feat.get("status") not in ("active", "proven"):
        continue

    # Surface connectivity: how many edges touch this feature's surfaces
    feat_surfaces = [s for s in surfaces if surfaces[s].get("feature") == fname]
    surf_inbound = sum(len(inbound.get(s, [])) for s in feat_surfaces)
    surf_outbound = sum(len(outbound.get(s, [])) for s in feat_surfaces)

    # Dependency connectivity: how many features depend on / are depended on
    depended_on_by = sum(1 for e in edges if e["to"] == f"feature/{fname}" and e["type"] == "depends_on")
    depends_on = sum(1 for e in edges if e["from"] == f"feature/{fname}" and e["type"] == "depends_on")

    ti = surf_inbound + depended_on_by
    to_ = surf_outbound + depends_on

    # Heuristics for position:
    # - "install" with no deps and high weight = entry
    # - Features other things depend on + high surface connectivity = core
    # - Features with depends_on but nothing depends on them = leaf
    if depended_on_by >= 1:
        pos = "core"  # other features depend on this — it's foundational
    elif depends_on == 0 and surf_outbound >= 2:
        pos = "entry"  # no dependency chain, but outbound connections (entry point)
    elif surf_outbound <= 1 and depends_on >= 1:
        pos = "leaf"  # depends on others, few outbound — end of chain
    elif ti >= 2 and to_ >= 2:
        pos = "core"
    else:
        pos = "leaf"

    journey_positions[fname] = {
        "position": pos,
        "inbound": ti,
        "outbound": to_,
        "surfaces": len(feat_surfaces),
        "depended_on_by": depended_on_by,
        "weight": feat.get("weight", 1)
    }

# --- 7. Data flows — who produces and consumes each file ---
data_flows = {}
for sid, surf in surfaces.items():
    for r in surf.get("reads", []):
        data_flows.setdefault(r, {"producers": [], "consumers": []})
        if sid not in data_flows[r]["consumers"]:
            data_flows[r]["consumers"].append(sid)
    for w in surf.get("writes", []):
        data_flows.setdefault(w, {"producers": [], "consumers": []})
        if sid not in data_flows[w]["producers"]:
            data_flows[w]["producers"].append(sid)

# Identify critical data files: many consumers, few producers
critical_data = {}
for fname, flow in data_flows.items():
    if len(flow["consumers"]) >= 2:
        critical_data[fname] = {
            "consumers": len(flow["consumers"]),
            "producers": len(flow["producers"]),
            "producer_surfaces": flow["producers"],
            "consumer_surfaces": flow["consumers"][:10],  # cap for readability
            "risk": "high" if len(flow["producers"]) <= 1 and len(flow["consumers"]) >= 3 else "normal"
        }

# Add data flow edges
for fname, flow in data_flows.items():
    for producer in flow["producers"]:
        for consumer in flow["consumers"]:
            if producer != consumer:
                edges.append({"from": producer, "to": consumer, "type": "data_flow", "via": fname})

# --- 8. Output + cache ---
result = {
    "product_type": product_type,
    "generated_at": datetime.now().isoformat(),
    "surfaces": surfaces,
    "edges": edges[:200],
    "orphans": orphans,
    "dead_ends": dead_ends,
    "entry_points": entry_points,
    "value_surface": "skill/go",
    "journey_positions": journey_positions,
    "data_flows": data_flows,
    "critical_data": critical_data,
    "stats": {
        "surface_count": len(surfaces),
        "edge_count": len(edges),
        "orphan_count": len(orphans),
        "dead_end_count": len(dead_ends),
        "avg_depth": avg_depth,
        "feature_count": len([f for f in feature_data if feature_data[f].get("status") in ("active", "proven")]),
        "data_file_count": len(data_flows),
        "critical_data_count": len(critical_data)
    }
}

out = json.dumps(result, indent=2)
with open(cache_file, "w") as f:
    f.write(out)
print(out)
PYEOF
