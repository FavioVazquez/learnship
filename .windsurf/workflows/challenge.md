---
description: Product + engineering challenge gate — is this worth building?
---

# Challenge

Product and engineering challenge gate. Asks forcing questions to determine whether a proposed feature, project, or milestone is worth building — before investing in planning and execution.

Two lenses:
- **Product lens:** "Is this worth building?" — demand, specificity, alternatives, user impact
- **Engineering lens:** "Will it hold?" — complexity, maintainability, scalability, risk

**Usage:** `challenge` — challenge the current milestone or phase
**Usage:** `challenge [description]` — challenge a specific idea or proposal

## Step 1: Gather Context

Read available project context:

```bash
cat .planning/DECISIONS.md 2>/dev/null
cat .planning/KNOWLEDGE.md 2>/dev/null
ls .planning/solutions/ 2>/dev/null
```

**Brownfield enhancement:** If `.planning/codebase/` exists, also read:
```bash
cat .planning/codebase/ARCHITECTURE.md 2>/dev/null
cat .planning/codebase/CONCERNS.md 2>/dev/null
```

If a description argument was provided, use it as the proposal to challenge.

If no argument: read `.planning/ROADMAP.md` and `.planning/STATE.md` to identify the current or next milestone/phase as the proposal.

## Step 2: Product Challenge

Read `parallelization` from `.planning/config.json` (defaults to `false`).

**If `parallelization` is `true` (subagent mode):**

```
Task(
  subagent_type="learnship-challenger",
  prompt="
    <objective>
    Run the PRODUCT lens challenge on this proposal:
    [proposal description]

    Ask 3-5 forcing questions from the product perspective:
    1. Who specifically wants this? (not 'users' — name the persona and their pain)
    2. What do they do today without it? (status quo is always the competitor)
    3. How would you know it succeeded? (concrete metric, not 'engagement')
    4. What's the narrowest version that still delivers value?
    5. What are you saying NO to by building this?

    Read DECISIONS.md and KNOWLEDGE.md for context on prior decisions.
    If ARCHITECTURE.md and CONCERNS.md exist, validate against existing architecture.

    Return: answers to each question + verdict (proceed/rethink/reduce-scope)
    </objective>

    <files_to_read>
    - .planning/DECISIONS.md (if exists)
    - .planning/KNOWLEDGE.md (if exists)
    - .planning/codebase/ARCHITECTURE.md (if exists)
    - .planning/codebase/CONCERNS.md (if exists)
    </files_to_read>
  "
)
```

**If `parallelization` is `false` (sequential mode):**

Using `@./agents/challenger.md` as your challenge persona, ask the 3-5 product forcing questions and answer them based on available context.

## Step 3: Engineering Challenge

**If `parallelization` is `true`:**

```
Task(
  subagent_type="learnship-challenger",
  prompt="
    <objective>
    Run the ENGINEERING lens challenge on this proposal:
    [proposal description]

    Ask 3-5 forcing questions from the engineering perspective:
    1. What's the complexity ceiling? (will this stay simple or inevitably grow complex?)
    2. What existing patterns does this break? (check ARCHITECTURE.md)
    3. What's the failure mode? (when this breaks, what happens to the user?)
    4. What does this make harder later? (second-order effects on maintenance)
    5. Is there a simpler approach that delivers 80% of the value?

    Read DECISIONS.md and KNOWLEDGE.md for context on prior decisions.
    Search .planning/solutions/ for related past issues.

    Return: answers to each question + verdict (proceed/rethink/reduce-scope)
    </objective>

    <files_to_read>
    - .planning/DECISIONS.md (if exists)
    - .planning/KNOWLEDGE.md (if exists)
    - .planning/codebase/ARCHITECTURE.md (if exists)
    </files_to_read>
  "
)
```

**If `parallelization` is `false`:**

Using `@./agents/challenger.md`, switch to the engineering lens and ask the 3-5 engineering forcing questions.

## Step 4: Synthesize Verdict

Combine both lenses into a verdict:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 learnship ► CHALLENGE COMPLETE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Proposal: [description]

## Product Lens
[summary of product challenge findings]

## Engineering Lens
[summary of engineering challenge findings]

## Verdict: [PROCEED | RETHINK | REDUCE SCOPE]

[1-3 sentence rationale]

[If RETHINK: specific concerns that need addressing]
[If REDUCE SCOPE: suggested narrower scope]
[If PROCEED: key risks to monitor]
```

Present the verdict using the platform's blocking question tool:
- **Proceed as planned** → continue to planning
- **Adjust scope** → describe adjustments, then re-challenge or proceed
- **Rethink** → go back to ideation or discussion

## Step 5: Record Decision

If the user makes a decision based on the challenge:

```bash
# Append to DECISIONS.md if it exists
cat >> .planning/DECISIONS.md << 'EOF'

### DEC-[NNN]: [Challenge verdict — proposal title]

**Date:** [YYYY-MM-DD]
**Type:** scope
**Context:** Challenged via `/challenge` — product + engineering lens
**Decision:** [proceed | reduced scope | rethought]
**Rationale:** [key reasons from both lenses]
EOF

git add .planning/DECISIONS.md
git commit -m "docs: challenge verdict — [proposal title]"
```

---

## Integration Points

- `/new-project` Step 7: optionally suggest `/challenge` before committing to scope
- `/discuss-milestone`: suggest `/challenge` for ambitious milestones
- `/quick --challenge`: flag for quick tasks that warrant a sanity check

---

## Learning Checkpoint

Read `learning_mode` from `.planning/config.json`.

**If `auto`:** After the challenge, offer:

> 💡 **Learning moment:** Challenge gates sharpen product thinking:
>
> `@agentic-learning either-or` — Which lens (product vs engineering) surfaced the most important concern? Log the reasoning pattern for future decisions.
>
> `@agentic-learning brainstorm [proposal topic]` — If the verdict was "rethink," use collaborative brainstorming to explore alternative approaches.

**If `manual`:** Add quietly: *"Tip: `@agentic-learning either-or` to log which challenge lens was most valuable."*
