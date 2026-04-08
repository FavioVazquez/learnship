---
description: Codebase-grounded divergent thinking — discover what is worth working on
---

# Ideate

Codebase-grounded divergent ideation. Scans the actual codebase for hotspots, TODOs, test gaps, and friction points, then generates 15-25 improvement ideas across multiple thinking frames. Adversarial filter eliminates weak ideas. Presents top 5-7 ranked survivors.

**Usage:** `ideate` — open-ended ideation on the current project
**Usage:** `ideate [focus]` — focused ideation on a specific area, concept, or constraint

**Sequencing:** Run before `/new-project`, `/challenge`, or `/discuss-milestone` to discover what's worth building.

## Step 1: Scope

If a focus argument was provided, use it as the ideation lens.
If no argument, proceed with open-ended ideation.

Check for recent ideation work:
```bash
find .planning/ -name "*-ideation-*.md" -mtime -30 2>/dev/null
```

If recent ideation exists, ask: "Found recent ideation work. Resume from it, or start fresh?"

## Step 2: Codebase Scan

Gather grounding context before generating ideas:

```bash
# Project shape
cat AGENTS.md 2>/dev/null || cat CLAUDE.md 2>/dev/null || cat README.md 2>/dev/null

# TODOs and FIXMEs in codebase
grep -rn "TODO\|FIXME\|HACK\|XXX" --include="*.ts" --include="*.js" --include="*.py" --include="*.rb" --include="*.go" --include="*.rs" . 2>/dev/null | head -30

# Test coverage gaps (files without corresponding test files)
find . -name "*.ts" -not -name "*.test.*" -not -name "*.spec.*" -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null | head -20

# Recent git activity (hotspots)
git log --oneline -20 --format="%s" 2>/dev/null
git log --since="30 days ago" --format="" --name-only 2>/dev/null | sort | uniq -c | sort -rn | head -15
```

**Brownfield enhancement:** If `.planning/codebase/` exists, also read:
```bash
cat .planning/codebase/ARCHITECTURE.md 2>/dev/null
cat .planning/codebase/CONCERNS.md 2>/dev/null
cat .planning/codebase/TESTING.md 2>/dev/null
```

Read compounded solutions and knowledge:
```bash
ls .planning/solutions/ 2>/dev/null
cat .planning/KNOWLEDGE.md 2>/dev/null
```

## Step 3: Divergent Ideation

Read `parallelization` from `.planning/config.json` (defaults to `false`).

**If `parallelization` is `true` (subagent mode):**

Spawn 3-4 ideation agents in parallel, each with a different thinking frame:

```
Task(
  subagent_type="learnship-ideation-agent",
  prompt="
    <objective>
    Generate 6-8 improvement ideas for this project using the [FRAME] lens.
    Ground every idea in the codebase scan results — no abstract advice.
    Return: title, summary, why_it_matters, evidence (specific files/patterns)

    Frame: [one of the frames below]
    Focus: [focus hint if provided]
    </objective>

    <context>
    [codebase scan results]
    [solutions and knowledge if available]
    </context>
  "
)
```

**Thinking frames:**
1. **User/operator pain** — friction, confusion, error-prone workflows
2. **Inversion/removal** — what could be automated, eliminated, or simplified
3. **Assumption-breaking** — what if the current approach is wrong?
4. **Leverage/compounding** — what would make all future work easier?

**If `parallelization` is `false` (sequential mode):**

Using `@./agents/ideation-agent.md`, generate 15-25 ideas across all four frames sequentially.

## Step 4: Deduplicate & Filter

Merge ideas from all frames:

1. **Deduplicate** — merge ideas that describe the same improvement from different angles
2. **Adversarial filter** — for each idea, ask:
   - Is this grounded in the actual codebase, or generic advice?
   - Is this actionable within a reasonable scope?
   - Does the evidence support the claimed impact?
   - Would a senior engineer roll their eyes at this suggestion?
3. **Eliminate** weak ideas with explicit reasons

## Step 5: Rank Survivors

Rank the surviving ideas (target: 5-7) by:

| Factor | Weight |
|--------|--------|
| **Impact** — how much does this improve the project? | High |
| **Evidence** — how grounded is the idea in codebase data? | High |
| **Feasibility** — can this be done in a reasonable scope? | Medium |
| **Compounding** — does this make future work easier? | Medium |

## Step 6: Present Results

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 learnship ► IDEATION COMPLETE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Focus: [focus or "open-ended"]
Scanned: [N] files, [M] TODOs, [K] hotspots
Generated: [total] ideas → [filtered] eliminated → [survivors] survivors

## Top Ideas

### 1. [Title]
**Impact:** high | medium | low
**Evidence:** [specific files/patterns from codebase]
**Summary:** [2-3 sentences]
**Scope:** [estimated effort — small/medium/large]

### 2. [Title]
[...]

---

Eliminated ideas (with reasons):
- [idea]: [why eliminated]
[...]
```

Save the ideation artifact:
```bash
DATE=$(date +%Y%m%d)
node -e "require('fs').mkdirSync('.planning',{recursive:true})"
# Write ideation results to .planning/[DATE]-ideation-[slug].md
git add .planning/[DATE]-ideation-[slug].md
git commit -m "docs: ideation — [focus or 'open-ended'] ([N] survivors)"
```

## Step 7: Route to Action

Present the "What's next?" options using the platform's blocking question tool:

- **Deep-dive an idea** → expand on the selected idea with more detail
- **Start a new project** → feed selected idea into `/new-project`
- **Add to current milestone** → feed into `/add-phase`
- **Challenge an idea** → run `/challenge [idea]` to stress-test it
- **Save and return later** → already saved to `.planning/`

---

## Learning Checkpoint

Read `learning_mode` from `.planning/config.json`.

**If `auto`:** After ideation, offer:

> 💡 **Learning moment:** Ideation is where divergent thinking gets practiced:
>
> `@agentic-learning brainstorm [top idea]` — Take the #1 idea and brainstorm collaboratively. Explore variations, edge cases, and alternative approaches.
>
> `@agentic-learning either-or [idea A] vs [idea B]` — Compare two competing ideas. Which is worth pursuing? Log the reasoning.

**If `manual`:** Add quietly: *"Tip: `@agentic-learning brainstorm [idea]` to explore the top idea collaboratively."*
