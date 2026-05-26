---
description: Capture implementation decisions for a phase before planning starts
---

# Discuss Phase

Extract implementation decisions that downstream planning needs. Analyze the phase to identify gray areas, let the user choose what to discuss, then deep-dive each selected area until satisfied.

**Usage:** Run `discuss-phase [N]` before `plan-phase [N]`.
**Usage:** Run `discuss-phase [N] --deep` for extended deep questioning — walks every decision branch until shared understanding is reached, with a recommended answer for each question.

**You are a thinking partner, not an interviewer.** The user is the visionary — you are the builder. Your job is to capture decisions that will guide research and planning, not to figure out implementation yourself.

<downstream_awareness>
**CONTEXT.md feeds into:**

1. **Researcher** — Reads CONTEXT.md to know WHAT to research
   - "User wants card-based layout" → researcher investigates card component patterns
   - "Infinite scroll decided" → researcher looks into virtualization libraries

2. **Planner** — Reads CONTEXT.md to know WHAT decisions are locked
   - "Pull-to-refresh on mobile" → planner includes that in task specs
   - "Agent's Discretion: loading skeleton" → planner can decide approach

**Your job:** Capture decisions clearly enough that downstream agents can act on them without asking the user again.

**Not your job:** Figure out HOW to implement. That's what research and planning do with the decisions you capture.
</downstream_awareness>

## Step 1: Load Phase

**Detect mode:** Check for `--deep` flag in the command. If not present, check `workflow.discuss_mode` in `.planning/config.json` — if it is `"deep"`, activate deep mode. Otherwise, use standard mode.

```
DEEP_MODE = "--deep" flag present OR config.workflow.discuss_mode == "deep"
```

Read `.planning/ROADMAP.md` and find the requested phase number. If not found, stop and show available phases.

Read prior context to avoid re-asking decided questions:
```bash
cat .planning/PROJECT.md
cat .planning/REQUIREMENTS.md
cat .planning/STATE.md
find .planning/phases -name "*-CONTEXT.md" 2>/dev/null | sort
```

Extract from prior CONTEXT.md files: locked preferences, patterns the user has established (e.g., "user consistently prefers minimal UI", "user rejected single-key shortcuts").

## Step 1b: Load Decisions Register

If `.planning/DECISIONS.md` exists, read it:
```bash
cat .planning/DECISIONS.md 2>/dev/null | head -80
# PowerShell: Get-Content .planning/DECISIONS.md -ErrorAction SilentlyContinue | Select-Object -First 80
```

Note any decisions that constrain or inform this phase's approach. Surface them during discussion rather than re-asking decided questions.

## Step 2: Check Existing Context

```bash
ls .planning/phases/*-CONTEXT.md 2>/dev/null
```

If CONTEXT.md already exists for this phase, present the choice:

```
ask_user_question([
  {
    header: "Existing Context",
    question: "CONTEXT.md already exists for this phase. What do you want to do?",
    multiSelect: false,
    options: [
      { label: "Update it", description: "Add to or revise existing decisions" },
      { label: "View it", description: "Show current context, then decide" },
      { label: "Skip", description: "Use existing context as-is" }
    ]
  }
])
```

> 🛑 STOP. Wait for the user's reply before continuing.

If "Skip" → exit workflow.

If no CONTEXT.md exists but plans already exist for this phase:

```
ask_user_question([
  {
    header: "Plans Already Exist",
    question: "Phase [X] already has plans created without user context. Your decisions here won't affect existing plans unless you re-run plan-phase.",
    multiSelect: false,
    options: [
      { label: "Continue and replan after", description: "Capture decisions now, re-run plan-phase later" },
      { label: "Cancel", description: "Keep existing plans unchanged" }
    ]
  }
])
```

> 🛑 STOP. Wait for the user's reply before continuing.

## Step 3: Scout Codebase

Do a lightweight scan to inform the discussion. Look for:
- Existing components, hooks, utilities relevant to this phase
- Established patterns (state management, styling, data fetching)
- Integration points where new code would connect

```bash
ls src/components/ src/hooks/ src/lib/ src/utils/ 2>/dev/null
```

Use grep to find files related to the phase goal's key terms. Read 3-5 most relevant files. Store findings internally — don't write to a file yet.

## Step 4: Identify Gray Areas

Analyze the phase goal from ROADMAP.md. A gray area is an **implementation decision the user cares about** — something that could go multiple ways and would change the result.

**By domain type:**
- Something users **SEE** → layout, density, interactions, empty states
- Something users **CALL** → response format, errors, auth flow, versioning
- Something users **RUN** → output format, flags, modes, error handling
- Something users **READ** → structure, tone, depth, flow
- Something being **ORGANIZED** → grouping criteria, naming, duplicates

**Use domain-aware probes** from `@./references/domain-probes.md` when the phase touches a known domain (auth, real-time, dashboard, API, database, search, file upload, caching, testing, deployment, AI/ML). Pick 2-3 most relevant probes, not all of them.

**Check prior decisions first** — don't re-ask what's already locked from earlier phases.

Generate 3-4 **phase-specific** gray areas. Not generic categories ("UI", "UX") — concrete decisions:
```
Phase: "User authentication"
→ Session handling, Error responses, Multi-device policy, Recovery flow

Phase: "Post Feed"
→ Layout style (cards vs. timeline), Loading behavior, Content metadata, Empty state
```

If no meaningful gray areas exist (pure infrastructure, all already decided), note this and skip to Step 6.

## Step 5: Present Gray Areas and Discuss

Display:
```
Phase [X]: [Name]
Domain: [what this phase delivers]

We'll clarify HOW to implement this — new capabilities belong in other phases.
```

If prior decisions apply, show them:
```
Carrying forward from earlier phases:
- [Decision from Phase N]
```

Present gray areas using a structured multi-select question. Annotate with prior decisions and code context:

```
ask_user_question([
  {
    header: "Gray Areas",
    question: "Which areas do you want to discuss? (select all that apply)",
    multiSelect: true,
    options: [
      { label: "[Area 1]", description: "[Prior context or code context annotation]" },
      { label: "[Area 2]", description: "[Prior context or code context annotation]" },
      { label: "[Area 3]", description: "[Prior context or code context annotation]" },
      { label: "All clear — skip discussion", description: "No gray areas need clarification" }
    ]
  }
])
```

> 🛑 STOP. Wait for the user's reply before continuing.

If "All clear" → skip to Step 6.

**For each selected area, discuss:**

1. Announce: "Let's talk about [Area]."
2. Ask focused questions with concrete options using structured questions where possible. **Always include a recommended answer** — state which option you'd pick and why:

```
ask_user_question([
  {
    header: "[Area]: [Decision Point]",
    question: "[Specific implementation question]",
    multiSelect: false,
    options: [
      { label: "[Option A] (Recommended)", description: "[Why this is recommended, with code context if relevant]" },
      { label: "[Option B]", description: "[Why]" },
      { label: "[Option C]", description: "[Why]" }
    ]
  }
])
```

> 🛑 STOP. Wait for the user's reply before continuing.

**Standard mode** (default):
3. After 4 questions per area, ask: "More questions about [area], or move to next?"
4. If more → ask 4 more, then check again

**Deep mode** (`--deep` or `discuss_mode: "deep"`):
3. After each answer, analyze: what is the single biggest remaining unknown in this area that could change how it's implemented? Ask that next. Provide your recommended answer.
4. Continue drilling down each decision branch — if an answer opens a sub-branch, follow it. Do NOT move on until the branch is fully resolved.
5. Only move to the next area when you judge that the current area has no remaining decision branches that would change the implementation.
6. If you can explore the codebase to answer a question yourself, do so instead of asking the user.

> **Deep mode intent:** Walk the full decision tree. Resolve every fork. The CONTEXT.md produced should leave no ambiguity that downstream agents would need to guess about.

After all selected areas:
- Summarize decisions captured
- Present final check:

**Standard mode:**
```
ask_user_question([
  {
    header: "Wrap Up",
    question: "All gray areas discussed. Ready to generate CONTEXT.md?",
    multiSelect: false,
    options: [
      { label: "Ready", description: "Generate CONTEXT.md with captured decisions" },
      { label: "Explore more", description: "Discuss additional areas before writing context" }
    ]
  }
])
```

**Deep mode:**
```
ask_user_question([
  {
    header: "Shared Understanding Check",
    question: "I've walked through every decision branch I can identify. Do you feel we've reached shared understanding on how to implement this phase?",
    multiSelect: false,
    options: [
      { label: "Yes — write CONTEXT.md", description: "All key decisions are captured" },
      { label: "There's still [area] to discuss", description: "Keep going on a specific area" },
      { label: "Let me add something", description: "I have context to add before you write" }
    ]
  }
])
```

> 🛑 STOP. Wait for the user's reply before continuing.

<scope_guardrail>
**No scope creep.** The phase boundary comes from ROADMAP.md and is FIXED. Discussion clarifies HOW to implement what's scoped, never WHETHER to add new capabilities.

**Allowed (clarifying ambiguity):**
- "How should posts be displayed?" (layout, density, info shown)
- "What happens on empty state?" (within the feature)
- "Pull to refresh or manual?" (behavior choice)

**Not allowed (scope creep):**
- "Should we also add comments?" (new capability)
- "What about search/filtering?" (new capability)
- "Maybe include bookmarking?" (new capability)

**The heuristic:** Does this clarify how we implement what's already in the phase, or does it add a new capability that could be its own phase?

**When user suggests scope creep:**
```
"[Feature X] would be a new capability — that's its own phase.
Want me to note it for the roadmap backlog?

For now, let's focus on [phase domain]."
```

Capture the idea in the "Deferred Ideas" section. Don't lose it, don't act on it.
</scope_guardrail>

## Step 6: Write CONTEXT.md

Find or create the phase directory:
```bash
node -e "require('fs').mkdirSync('.planning/phases/[padded_phase]-[phase_slug]',{recursive:true})"
```

Write `.planning/phases/[padded_phase]-[phase_slug]/[padded_phase]-CONTEXT.md`:

```markdown
# Phase [X]: [Name] - Context

**Gathered:** [date]
**Mode:** [standard | deep]
**Status:** Ready for planning

<domain>
## Phase Boundary

[Clear statement of what this phase delivers]

</domain>

<decisions>
## Implementation Decisions

### [Category discussed]
- [Decision captured]

### Agent's Discretion
[Areas where user said "you decide"]

</decisions>

<specifics>
## Specific Ideas

[Any "I want it like X" moments or specific references]

[If none: "No specific requirements — open to standard approaches"]

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

[List specs, ADRs, or design docs relevant to this phase with full relative paths.]

[If no external specs: "No external specs — requirements are fully captured in decisions above"]

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- [Component/hook]: [How it could be used]

### Established Patterns
- [Pattern]: [How it constrains/enables this phase]

### Integration Points
- [Where new code connects to existing system]

</code_context>

<deferred>
## Deferred Ideas

[Ideas that came up but belong in other phases]

[If none: "None — discussion stayed within phase scope"]

</deferred>

---
*Phase: [padded_phase]-[phase_slug]*
*Context gathered: [date]*
```

## Step 7: Write Discussion Log

Also write a discussion log for audit purposes using `@./templates/discussion-log.md`:

Write `.planning/phases/[padded_phase]-[phase_slug]/[padded_phase]-DISCUSSION-LOG.md` with:
- All options considered for each area (not just the selected one)
- The user's verbatim choice and rationale
- Areas delegated to agent's discretion
- Deferred ideas

This file is for human audit trails only — it is NOT referenced by downstream agents.

## Step 8: Commit and Confirm

```bash
git add ".planning/phases/[padded_phase]-[phase_slug]/[padded_phase]-CONTEXT.md"
git add ".planning/phases/[padded_phase]-[phase_slug]/[padded_phase]-DISCUSSION-LOG.md"
git commit -m "docs([padded_phase]): capture phase context"
```

Update STATE.md with session info, then commit:
```bash
git add .planning/STATE.md && git commit -m "docs(state): record phase [X] context session"
```

Present summary:
```
Created: .planning/phases/[padded_phase]-[slug]/[padded_phase]-CONTEXT.md

## Decisions Captured

### [Category]
- [Key decision]

[If deferred ideas:]
## Noted for Later
- [Deferred idea] — future phase

---

▶ Next Up: plan-phase [X]

💡 Ambitious scope? `/challenge` — stress-test the approach before planning
💡 Made important decisions? `/compound` — capture them while context is fresh
💡 Want to go deeper? Re-run `discuss-phase [X] --deep` for relentless branch-walking until full shared understanding
```

---

## Learning Checkpoint

Read `learning_mode` from `.planning/config.json`.

**If `auto`:** Offer based on where you are in the discussion:

> 💡 **Learning moment:** Implementation decisions just captured. Make them stick:
>
> `@agentic-learning either-or` — Record the decision paths considered, the choice made, and expected consequences. Builds a searchable record of your reasoning that future phases can reference.
>
> `@agentic-learning brainstorm [phase topic]` — If any area felt unclear or you settled quickly, talk it through now. Better to surface a blind spot here than mid-execution.
>
> `@agentic-learning explain-first [phase topic]` — Explain the planned approach back in your own words. If the explanation has gaps, the CONTEXT.md probably does too.

**If `manual`:** Add quietly: *"Tip: `@agentic-learning either-or` to log today's decisions as a decision journal entry."*
