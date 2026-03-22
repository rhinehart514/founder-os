# Release Notes Template

Fill this from `scripts/release-notes.sh` output + roadmap.yml evidence.

Every bullet must trace to evidence: a git commit, an eval score change, a proven thesis item, or a confirmed prediction. Delete any line that doesn't.

---

## [version]: [thesis summary — one line]

[2-3 sentences. What this version proves. Written for someone who uses the product, not someone who reads the code.]

### What's new
- [User-facing change derived from a proven evidence item]
- [User-facing change derived from a feature eval score improvement]
- [User-facing change — trace to specific commit or assertion]

### Improvements
- [Fix or refinement — what was broken, what's better now]
- [Performance, reliability, or UX improvement with specifics]

### What we learned
- [Key pattern confirmed during this version — from experiment-learnings.md]
- [Wrong prediction that updated the model — what we expected vs what happened]

### Known limitations
- [Honest gap — what this version doesn't solve yet]
- [Unproven thesis item — what we're still testing]

---

## Anti-slop rules

These words/phrases are banned from release notes. If you catch yourself writing them, replace with specifics or delete the bullet.

- "improved performance" → say what got faster and by how much
- "enhanced user experience" → say what changed for the user
- "various bug fixes" → name the bugs
- "under the hood improvements" → name what changed
- "streamlined" → say what's simpler and why
- "robust" → say what failure mode is handled
- "seamless" → say what friction was removed
- "cutting-edge" / "state-of-the-art" — delete
- "leverages" / "utilizes" → "uses"
