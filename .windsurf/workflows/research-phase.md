---
description: Deep-dive domain research for a phase without immediately creating plans
---

# Research Phase

Run standalone domain research for a phase. Useful when the domain is unfamiliar, the phase is complex, or you want to explore options before committing to a planning approach.

**Normally you don't need this** — `plan-phase` runs research automatically. Use `research-phase` when you want research results to review and discuss before planning starts.

**Usage:** `research-phase [N]`

## Step 1: Validate Phase

```bash
node -e "const fs=require('fs'); console.log(fs.existsSync('.planning/ROADMAP.md') ? 'OK' : 'MISSING')"
```

Find phase `[N]` in ROADMAP.md:
```bash
grep -E "Phase [N]:" .planning/ROADMAP.md
```

If not found: list available phases and stop.

## Step 2: Check Existing Research

```bash
ls ".planning/phases/"*"/"*"-RESEARCH.md" 2>/dev/null | grep "^[N]-\|/[N][^0-9]"
```

If RESEARCH.md already exists for this phase:

```
ask_user_question([
  {
    header: "Existing Research",
    question: "Research already exists for this phase. What do you want to do?",
    multiSelect: false,
    options: [
      { label: "View existing", description: "Show current research, then decide" },
      { label: "Re-run and overwrite", description: "Discard existing research and re-run" },
      { label: "Skip", description: "Use existing research as-is" }
    ]
  }
])
```

## Step 3: Load Context

Read all available phase context:
```bash
cat .planning/ROADMAP.md        # phase goal and requirements
cat .planning/REQUIREMENTS.md   # requirement IDs and acceptance criteria
cat .planning/STATE.md          # project history and past decisions
```

Check for CONTEXT.md (user decisions from discuss-phase):
```bash
ls ".planning/phases/[padded_phase]-[slug]/"*"-CONTEXT.md" 2>/dev/null
```

If CONTEXT.md exists, read it — user decisions shape what to research.

## Step 4: Run Research

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 learnship ► RESEARCHING PHASE [N]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Read `parallelization` from `.planning/config.json` (defaults to `false`).

**If `parallelization.enabled` is `true` (subagent mode — Claude Code, OpenCode, Codex):**

Spawn a dedicated researcher agent:
```
Task(
  subagent_type="learnship-researcher",
  prompt="
    <objective>
    Research phase [N] for this project. Read the phase goal from ROADMAP.md,
    requirements from REQUIREMENTS.md, and any CONTEXT.md decisions.
    Write [padded_phase]-RESEARCH.md with Don't Hand-Roll, Common Pitfalls,
    Existing Patterns, and Recommended Approach sections.
    Follow the researcher persona at @./agents/researcher.md.
    </objective>

    <files_to_read>
    - .planning/ROADMAP.md
    - .planning/REQUIREMENTS.md
    - .planning/STATE.md
    - .planning/phases/[padded_phase]-[slug]/[padded_phase]-CONTEXT.md (if exists)
    - @./agents/researcher.md (persona)
    </files_to_read>
  "
)
```

**If `parallelization.enabled` is `false` (sequential mode):**

Using `@./agents/researcher.md` as your research persona in **phase research mode**:

Read all loaded context, then investigate how to implement this phase. Write `.planning/phases/[padded_phase]-[slug]/[padded_phase]-RESEARCH.md` with two sections:

**Don't Hand-Roll** — problems that have battle-tested solutions:
```
- Problem: [what looks custom]
  Solution: Use [library/approach]
  Why: [specific reason — ESM compat, maintenance, type safety, etc.]
```

**Common Pitfalls** — what goes wrong in this type of phase:
```
- Pitfall: [what fails]
  Warning sign: [what to look for]
  Prevention: [how to avoid]
  Phase impact: [when/where to address this]
```

## Step 5: Commit Research

```bash
git add ".planning/phases/[padded_phase]-[slug]/[padded_phase]-RESEARCH.md"
git commit -m "docs([padded_phase]): phase research"
```

## Step 6: Present Results

Display key findings:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 learnship ► RESEARCH COMPLETE ✓
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Phase [N]: [Name]

Don't hand-roll: [N items]
Pitfalls: [N items]

Key findings:
- [Most important recommendation]
- [Second most important]
- [Third]

File: .planning/phases/[phase-dir]/[N]-RESEARCH.md
```

Ask: "What would you like to do next?"
- **Plan this phase** → `plan-phase [N]` (research is already done, will be skipped)
- **Discuss first** → `discuss-phase [N]` → then plan
- **Read full research** → show the research file
- **Done for now** → stop

---

## Learning Checkpoint

Read `learning_mode` from `.planning/config.json`.

**If `auto`:** Offer all three — new research is the best time to use all of them:

> 💡 **Learning moment:** Research complete — new domain concepts are fresh. Lock them in before they fade:
>
> `@agentic-learning learn [phase topic]` — Active retrieval on the key concepts from this research. You explain first, gaps get filled. This is how domain knowledge becomes intuition, not just notes.
>
> `@agentic-learning explain-first [phase topic]` — Explain the domain back in your own words before planning starts. If you can’t explain it clearly, the plans won’t be clear either.
>
> `@agentic-learning quiz [phase topic]` — Test yourself on what the research surfaced. Retrieval practice now means fewer surprises during execution.

**If `manual`:** Add quietly: *"Tip: `@agentic-learning learn [topic]` · `@agentic-learning explain-first [topic]` to consolidate the research before planning."*
