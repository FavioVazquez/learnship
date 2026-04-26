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
  subagent_type="learnship-phase-researcher",
  description="Phase [N] research",
  prompt="
    <agent_definition>
    You are a learnship phase researcher. You answer 'What do I need to know to PLAN this phase well?' and produce a single RESEARCH.md that the planner consumes.
    Your training data is 6-18 months stale — treat it as hypothesis, not fact. Verify before asserting.
    Flag uncertainty with confidence levels (HIGH/MEDIUM/LOW). Be prescriptive: 'Use X because Y' not 'Options are X, Y, Z.'
    Tool priority: 1. search_web (implementation patterns — always include current year), 2. read_url_content (official docs), 3. Codebase scan (existing patterns to reuse).
    Investigation, not confirmation — gather evidence first, recommend second.
    </agent_definition>

    <objective>
    Research how to implement phase [N] for this project. Write [padded_phase]-RESEARCH.md.
    You MUST run search_web queries BEFORE writing the file. Do NOT write from training data alone.
    </objective>

    <research_steps>
    1. Read the phase goal from ROADMAP.md, requirements from REQUIREMENTS.md, and any CONTEXT.md decisions
    2. Run at least 3 search_web queries: '[phase technology] best practices [current year]', '[phase technology] common mistakes', '[phase technology] recommended libraries'
    3. read_url_content official docs for key libraries or frameworks discovered
    4. Scan the codebase for existing patterns relevant to this phase
    5. Write [padded_phase]-RESEARCH.md with confidence levels and source citations
    </research_steps>

    <files_to_read>
    - .planning/ROADMAP.md
    - .planning/REQUIREMENTS.md
    - .planning/STATE.md
    - .planning/phases/[padded_phase]-[slug]/[padded_phase]-CONTEXT.md (if exists)
    </files_to_read>

    <output>
    Required sections: ## Don't Hand-Roll, ## Common Pitfalls, ## Existing Patterns in This Codebase, ## Recommended Approach
    </output>

    **WRITE ACTION REQUIRED — You MUST use your file-write tool to write [padded_phase]-RESEARCH.md to disk. Do NOT output the content to the conversation. Do NOT treat this as done until the file physically exists on disk.**

    Write the research content to `.planning/phases/[padded_phase]-[slug]/[padded_phase]-RESEARCH.md` using your write tool now.

    Then verify:
    ```
    node -e "const fs=require('fs');const files=fs.readdirSync('.planning/phases/').flatMap(d=>fs.readdirSync('.planning/phases/'+d).filter(f=>f.endsWith('-RESEARCH.md')).map(f=>'.planning/phases/'+d+'/'+f));if(!files.length){console.log('RESEARCH_MISSING');process.exit(1);}console.log('RESEARCH_OK — '+files[files.length-1]);"
    ```

    If `RESEARCH_MISSING`: write the file and re-run until `RESEARCH_OK`.
  "
)
```

**If `parallelization.enabled` is `false` (sequential mode):**

<persona_context>
You are now the **learnship phase researcher**. Your training data is stale — verify before asserting.
Tag every claim: [VERIFIED: source], [CITED: url], or [ASSUMED]. Never present assumed knowledge as verified fact.
Use search_web for implementation patterns, read_url_content for official docs, codebase scan for existing patterns to reuse.
</persona_context>

> **Announce persona** — print this before proceeding:
> ```bash
> printf "\n  \033[34m  learnship-phase-researcher(Your training data is stale — verify before asserting)\033[0m\n\n"
> ```

Read `@./agents/phase-researcher.md` for the full persona definition. In **phase research mode**:

**Online research first.** Before writing anything, run at least 3 search_web queries relevant to this phase's domain:

1. `"[phase technology] best practices 2026"` — current recommendations
2. `"[phase technology] common mistakes gotchas"` — what goes wrong
3. `"[phase technology] recommended libraries"` — standard tools

Use read_url_content to read official docs for any libraries or frameworks discovered. Record findings internally.

> 🛑 STOP. Confirm: did you run at least 3 search_web queries? If you skipped straight to writing the research file, go back and search now.

Then write `.planning/phases/[padded_phase]-[slug]/[padded_phase]-RESEARCH.md` based on your web research findings. Include confidence levels and cite sources. The file must have these sections:

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
