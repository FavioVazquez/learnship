---
description: Structured codebase discovery before working on an unfamiliar area — reads code, maps dependencies, surfaces risks
---

# Discovery Phase

Structured discovery for working on an unfamiliar part of the codebase. Maps the relevant code area, traces dependencies, identifies risks, and produces a focused discovery report before planning starts.

**Usage:** `discovery-phase [N]` or `discovery-phase [area description]`

**Run before:** `discuss-phase [N]` or `plan-phase [N]` when the area is unfamiliar.

## Step 1: Identify Discovery Target

If a phase number was provided, read the phase goal from ROADMAP.md:
```bash
cat .planning/ROADMAP.md | grep -A 10 "Phase [N]:"
```

If a description was provided, use it directly.

Display:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 learnship ► DISCOVERY — [target area]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Step 2: Locate Relevant Code

Search for code related to the target area using key terms from the phase goal:

```bash
# Find files mentioning key terms
grep -rl "[key term 1]" src/ 2>/dev/null | head -15
grep -rl "[key term 2]" src/ 2>/dev/null | head -10

# Find related directories
find src/ -type d | grep -i "[key term]" 2>/dev/null

# Find entry points
grep -rn "export\|module.exports\|def " src/ --include="*.ts" --include="*.js" --include="*.py" 2>/dev/null | grep -i "[key term]" | head -20
```

Read the 5-8 most relevant files. Focus on interfaces, types, exports, and public API — not implementation details.

## Step 3: Map Dependencies

For the relevant files, trace what they depend on and what depends on them:

**Incoming dependencies** (who calls this code):
```bash
grep -rl "import.*[module name]\|require.*[module name]" src/ 2>/dev/null | head -10
```

**Outgoing dependencies** (what this code calls):
Read import statements from the relevant files.

Build a dependency map:
```
[target area]
  ← used by: [file A], [file B]
  → uses: [lib X], [module Y], [service Z]
  ↔ shares state with: [store/context/DB table]
```

## Step 4: Identify Integration Points

Find where new code for this phase would need to connect:
- Entry points (routes, event handlers, CLI commands)
- Shared state (stores, contexts, DB models)
- External service calls that affect this area
- Configuration that controls behavior

## Step 5: Surface Risks

Look specifically for:

**Complexity hotspots:**
```bash
# Files with most lines of code in the area
wc -l $(find src/ -name "*.ts" -o -name "*.py" 2>/dev/null | xargs grep -l "[key term]" 2>/dev/null) | sort -n | tail -10
```

**Test coverage gaps:**
```bash
find . -name "*.test.*" -o -name "test_*.py" | xargs grep -l "[key term]" 2>/dev/null
```

**TODO/FIXME in the area:**
```bash
grep -rn "TODO\|FIXME\|HACK\|XXX" src/ 2>/dev/null | grep -i "[key term]" | head -10
```

**Known issues from DECISIONS.md:**
```bash
grep -i "[key term]" .planning/DECISIONS.md 2>/dev/null
```

## Step 6: Write Discovery Report

Write `.planning/phases/[padded_phase]-[slug]/[padded_phase]-DISCOVERY.md`:

```markdown
---
phase: [N]
area: [target area]
created: [date]
---

# Discovery: [target area]

## Relevant Files

| File | Role | Lines |
|------|------|-------|
| [path] | [what it does] | [N] |

## Dependency Map

[ASCII diagram or bullet list]

## Integration Points

- **Entry point:** [where new code connects]
- **Shared state:** [what is shared]
- **External dependencies:** [services, APIs]

## Risks

### High
- [risk]: [why it's risky, what to watch for]

### Medium
- [risk]: [description]

### Low / Acceptable
- [risk]: [description]

## Test Coverage

[Summary of what's tested, what's not]

## Recommendations

Before planning Phase [N]:
- [Specific recommendation 1]
- [Specific recommendation 2]
```

## Step 7: Commit and Report

```bash
git add ".planning/phases/[padded_phase]-[slug]/"
git commit -m "docs([padded_phase]): discovery report for [area]"
```

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 learnship ► DISCOVERY COMPLETE ✓
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Area: [target]
Files mapped: [N]
Risks found: [high: N, medium: M, low: K]

▶ Next: discuss-phase [N] — your decisions will be informed by this discovery
        or: plan-phase [N] — discovery is available for the planner to read
```

---

## Learning Checkpoint

Read `learning_mode` from `.planning/config.json`.

**If `auto`:** Offer:

> 💡 **Learning moment:** Discovery complete. Verify your mental model before building:
>
> `@agentic-learning explain [area name]` — Explain the area you just discovered back in your own words. Gaps in the explanation are gaps in the understanding — better to find them now.

**If `manual`:** Add quietly: *"Tip: `@agentic-learning explain [area]` to verify your understanding before planning."*
