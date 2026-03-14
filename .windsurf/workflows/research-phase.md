---
description: Deep-dive domain research for a phase without immediately creating plans
---

# Research Phase

Run standalone domain research for a phase. Useful when the domain is unfamiliar, the phase is complex, or you want to explore options before committing to a planning approach.

**Normally you don't need this** — `plan-phase` runs research automatically. Use `research-phase` when you want research results to review and discuss before planning starts.

**Usage:** `research-phase [N]`

## Step 1: Validate Phase

```bash
test -f .planning/ROADMAP.md && echo "OK" || echo "MISSING"
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
Research already exists: .planning/phases/[phase-dir]/[N]-RESEARCH.md

Options:
1. View existing research
2. Re-run and overwrite
3. Skip — use existing
```

Wait for choice.

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
