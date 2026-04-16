---
description: Codebase-grounded divergent thinking — discover what is worth working on
---

# Ideate

Codebase-grounded divergent ideation with Socratic exploration. Two modes: **scan mode** (default) scans the actual codebase for hotspots and generates ranked improvement ideas. **Explore mode** (`--explore`) uses Socratic questioning to help you think through an idea before committing to artifacts.

**Usage:** `ideate` — open-ended scan-based ideation on the current project
**Usage:** `ideate [focus]` — focused ideation on a specific area, concept, or constraint
**Usage:** `ideate --explore [topic]` — Socratic exploration of an idea with mid-conversation research

**Sequencing:** Run between milestones — after `/complete-milestone`, before `/discuss-milestone` or `/new-milestone`. Requires an existing project with `AGENTS.md` and `.planning/`.

> **No project yet?** Use `@agentic-learning brainstorm [idea]` for pure divergent thinking without codebase grounding. `/ideate` is for projects that already have code to scan.

## Step 1: Pre-flight Check

Verify the project has artifacts to ground ideation on:

```bash
ls AGENTS.md 2>/dev/null && ls .planning/PROJECT.md 2>/dev/null
```

**If neither exists:** Stop. Tell the user:
> `/ideate` needs an existing project to scan. Run `/new-project` first to set up the project, or use `@agentic-learning brainstorm [idea]` for pre-project ideation.

**If project exists:** Continue.

## Step 2: Mode Selection

Parse arguments for `--explore` flag.

**If `--explore` is present:** Jump to Step 2b (Socratic Exploration).
**Otherwise:** Continue to Step 2a (Scan Mode).

## Step 2a: Scope (Scan Mode)

If a focus argument was provided, use it as the ideation lens.
If no argument, proceed with open-ended ideation.

Check for recent ideation work:
```bash
find .planning/ -name "*-ideation-*.md" -mtime -30 2>/dev/null
```

If recent ideation exists, ask: "Found recent ideation work. Resume from it, or start fresh?"

## Step 2b: Socratic Exploration (only with `--explore`)

If a topic was provided, acknowledge it and begin exploring:
```
## Explore: {topic}

Let's think through this together. I'll ask questions to help clarify the idea
before we commit to any artifacts.
```

If no topic, ask:
```
## Explore

What's on your mind? This could be a feature idea, an architectural question,
a problem you're trying to solve, or something you're not sure about yet.
```

**Conversation rules (2-5 exchanges):**
- Ask **one question at a time** (never a list of questions)
- Questions should probe: constraints, tradeoffs, users, scope, dependencies, risks
- Listen for signals: "or" / "versus" / "tradeoff" indicate competing priorities worth exploring
- Reflect back what you hear to confirm understanding before moving forward
- **Follow the user's energy** — if they're excited about one aspect, go deeper there

**Mid-conversation research offer (after 2-3 exchanges):**

If the conversation surfaces factual questions, technology comparisons, or unknowns:

```
ask_user_question([
  {
    header: "Research Opportunity",
    question: "This touches on [specific question]. Want me to do a quick research pass before we continue?",
    multiSelect: false,
    options: [
      { label: "Yes, research this", description: "~30 seconds — may surface useful context" },
      { label: "No, keep exploring", description: "Continue the conversation without research" }
    ]
  }
])
```

> 🛑 STOP. Wait for the user's reply before continuing.

If yes: read `parallelization` from `.planning/config.json`. If `parallelization.enabled` is true, spawn a researcher agent:
```
Task(
  subagent_type="learnship-researcher",
  description="Quick research pass",
  prompt="
    <agent_definition>
    You are a learnship researcher doing a quick, focused research pass.
    Your training data is stale — use search_web to verify current state. Be concise.
    </agent_definition>

    <objective>
    Quick research pass on: [specific question].
    Search web, scan codebase for relevant patterns, and return a concise summary of findings.
    </objective>
  "
)
```
<persona_context>
You are now the **learnship researcher**. Do a quick research pass on the ideation domain.
Use search_web to discover current state. Tag confidence levels. Share findings before ideation begins.
</persona_context>

> **Announce persona** — print this before proceeding:
> ```bash
> printf "\n  \033[36m  learnship-researcher(Do a quick research pass on the ideation domain)\033[0m\n\n"
> ```

If parallelization is false, read `@./agents/researcher.md` for the full persona definition. Do a quick research pass. Share findings and continue.

**Crystallize outputs (after 3-6 exchanges):**

When the conversation reaches natural conclusions, propose **up to 4 outputs**:

| Type | Destination | When to suggest |
|------|-------------|----------------|
| Note | `.planning/notes/{slug}.md` | Observations, context, decisions worth remembering |
| Todo | via `/add-todo` | Concrete actionable tasks identified |
| Decision | via `/decision-log` | Architectural or scope decisions made |
| Phase proposal | via `/add-phase` | Idea crystallized into a deliverable phase |

Write selected outputs, then jump to Step 7 (Present Results) with a tailored summary.

## Step 3: Codebase Scan (Scan Mode)

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

## Step 4: Divergent Ideation

Read `parallelization` from `.planning/config.json` (defaults to `false`).

**If `parallelization` is `true` (subagent mode):**

Spawn 3-4 ideation agents in parallel, each with a different thinking frame:

```
Task(
  subagent_type="learnship-ideation-agent",
  description="Ideate: [FRAME] lens",
  prompt="
    <agent_definition>
    You are a learnship ideation agent. Generate improvement ideas grounded in the actual codebase — no abstract advice.
    Every idea must cite specific files, patterns, or evidence. Be creative but practical.
    </agent_definition>

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

<persona_context>
You are now the **learnship ideation agent**. Generate ideas across multiple creative frames.
Quantity first, quality later. Push past the obvious. Use contrarian thinking and cross-domain analogies.
</persona_context>

> **Announce persona** — print this before proceeding:
> ```bash
> printf "\n  \033[35m  learnship-ideation-agent(Generate ideas across multiple creative frames)\033[0m\n\n"
> ```

Read `@./agents/ideation-agent.md` for the full persona definition. Generate 15-25 ideas across all four frames sequentially.

## Step 5: Deduplicate & Filter

Merge ideas from all frames:

1. **Deduplicate** — merge ideas that describe the same improvement from different angles
2. **Adversarial filter** — for each idea, ask:
   - Is this grounded in the actual codebase, or generic advice?
   - Is this actionable within a reasonable scope?
   - Does the evidence support the claimed impact?
   - Would a senior engineer roll their eyes at this suggestion?
3. **Eliminate** weak ideas with explicit reasons

## Step 6: Rank Survivors

Rank the surviving ideas (target: 5-7) by:

| Factor | Weight |
|--------|--------|
| **Impact** — how much does this improve the project? | High |
| **Evidence** — how grounded is the idea in codebase data? | High |
| **Feasibility** — can this be done in a reasonable scope? | Medium |
| **Compounding** — does this make future work easier? | Medium |

## Step 7: Present Results

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

## Step 8: Route to Action

Present the "What's next?" options using the platform's blocking question tool:

- **Deep-dive an idea** → expand on the selected idea with more detail
- **Explore an idea** → run `ideate --explore [idea]` for Socratic deep-dive
- **Add to current milestone** → feed into `/add-phase`
- **Start a new milestone** → feed into `/discuss-milestone` then `/new-milestone`
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
