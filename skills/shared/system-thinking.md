# System Thinking

Methodology for system-level work. Systems are the 0-coverage level in the hierarchy — no skill currently reasons about system boundaries, decomposition, or health. This reference fills that gap.

A system is a coherent product domain with its own data model and ownership. You can't prioritize systems against each other — they all need to exist. But you can evaluate whether the decomposition is right.

## System identification

List every noun in the product that has its own CRUD lifecycle. Each is a candidate system.

**Method:**
1. Scan `config/founder.yml` and `config/portfolio.yml` for feature names
2. For each feature, identify the primary data entity it manages
3. Group features by shared data entities — each group is a candidate system
4. Name the system by its domain, not its implementation (e.g., "identity" not "auth middleware")

**Signs you've found a system:**
- It has its own database table(s) or data store
- Multiple features read from or write to it
- It has an API surface (even internal)
- Removing it would break multiple features
- It can be reasoned about independently ("the auth system works" vs "the billing flow works")

**Signs something is NOT a system:**
- It's a shared utility (logging, error handling) — that's infrastructure
- It only serves one feature — it's a feature detail
- It has no data model — it's a behavior pattern

## System boundary mapping

For each identified system, map:

```
SYSTEM: [name]
  owns: [data entities]
  features inside: [features that live within this system]
  depends on: [other systems this one calls]
  depended on by: [other systems that call this one]
  boundary: [what's inside vs outside]
  coupling: [where boundaries leak]
```

**Healthy boundaries:**
- Data flows through defined interfaces, not direct access
- Changes to the system's internals don't break other systems
- The system can be tested independently
- Ownership is clear — one team (or one person) owns it

**Unhealthy boundaries:**
- Feature A directly reads System B's database
- A change in auth requires changes in billing
- The "system" is actually a grab-bag of unrelated features
- Nobody knows who owns it

## System health questions

When auditing a system (used by `/measure systems`):

1. **Data model coherence:** Is the data model clean? Are entities well-defined? Any zombie tables?
2. **Boundary integrity:** Do other systems access this one only through interfaces? Any direct coupling?
3. **Independent evolution:** Can this system change without breaking others? What's the blast radius?
4. **Feature coverage:** Do the features inside this system fully serve the jobs they're meant to?
5. **Right size:** Is it too big (doing too many things) or too small (over-decomposed)?
6. **Ownership clarity:** Is it clear who owns this system? Can they make decisions about it independently?

## System-level decisions

### When to split a system
- It serves two unrelated jobs
- Changes to one part frequently break another part
- Different parts evolve at different speeds
- It has grown so large that nobody understands the whole thing

### When to merge systems
- Two systems always change together
- They share 80%+ of their data model
- The boundary between them creates more confusion than clarity
- Users think of them as one thing

### When to add a new system
- A feature cluster has emerged that doesn't fit any existing system
- You're building infrastructure that multiple features need (but doesn't exist yet)
- A job requires a new data entity that doesn't belong to any current system

### When to kill a system
- No features use it anymore
- The job it served has been killed or pivoted away from
- It was built for a hypothesis that was disproven

## Systems vs features

| | System | Feature |
|---|--------|---------|
| **Scope** | Coherent domain | Discrete unit |
| **Data** | Owns data model | Uses system's data |
| **Shipping** | Not shipped alone | Can be shipped independently |
| **Jobs** | Enables jobs | Fulfills jobs |
| **Priority** | Can't deprioritize — must exist | Can be ranked against peers |

**Red flag:** A feature that spans multiple systems is a coupling smell. Either:
- The feature should be split into system-scoped pieces
- The systems should merge
- The system boundaries are wrong

## For ideation (`/ideate system`)

When generating system-level ideas, explore:
- **Boundary redesign:** What if we split system X? Merged systems Y and Z?
- **New systems:** What product domain is missing entirely?
- **System kills:** What system exists but serves no current job?
- **Data model rethink:** What if the core entity was different?
- **Ownership shift:** What if a different team owned this?
- **Platform extraction:** What system could become a shared service?

## For measurement (`/measure systems`)

Output format:
```
SYSTEM: [name]
  health: [score 1-5]
  data model: [clean/messy/zombie]
  boundaries: [intact/leaking at X]
  coupling: [low/medium/high — to systems X, Y]
  evolution: [independent/coupled]
  features: [N features, M jobs served]
  verdict: [healthy/needs attention/redesign candidate]
```
