---
description: Capture implementation decisions for a phase before planning starts
---

# Discuss Phase

Extract implementation decisions that downstream planning needs. Analyze the phase to identify gray areas, let the user choose what to discuss, then deep-dive each selected area until satisfied.

**Usage:** Run `discuss-phase [N]` before `plan-phase [N]`.

**You are a thinking partner, not an interviewer.** The user is the visionary — you are the builder. Capture decisions that will guide research and planning.

## Step 1: Load Phase

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
```

Note any decisions that constrain or inform this phase's approach. Surface them during discussion rather than re-asking decided questions.

## Step 2: Check Existing Context

```bash
ls .planning/phases/*-CONTEXT.md 2>/dev/null
```

If CONTEXT.md already exists for this phase:
- Offer: **Update it** / **View it** / **Skip** (use as-is)
- If "Skip" → exit workflow

If no CONTEXT.md exists but plans already exist for this phase:
- Warn: "Phase [X] already has plans created without user context. Your decisions here won't affect existing plans unless you re-run plan-phase."
- Ask: **Continue and replan after** / **Cancel**

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

Present 3-4 gray areas for selection (multi-select). Annotate with:
- Prior decision context: "You chose X in Phase 5"
- Code context: "You already have a Card component with shadow/rounded variants"

**For each selected area, discuss:**

1. Announce: "Let's talk about [Area]."
2. Ask 4 focused questions with concrete options (not abstract). Include the recommended choice. Annotate options with existing code where relevant.
3. After 4 questions, ask: "More questions about [area], or move to next?"
4. If more → ask 4 more, then check again

After all selected areas:
- Summarize decisions captured
- Ask: "Which gray areas remain unclear?" → "Explore more" or "I'm ready for context"

**Scope guardrail:** If the user suggests a new capability, say:
```
"[Feature X] sounds like a new capability — that's its own phase.
Want me to note it for the roadmap backlog?

Back to [current area]..."
```

Track deferred ideas internally.

## Step 6: Write CONTEXT.md

Find or create the phase directory:
```bash
mkdir -p ".planning/phases/[padded_phase]-[phase_slug]"
```

Write `.planning/phases/[padded_phase]-[phase_slug]/[padded_phase]-CONTEXT.md`:

```markdown
# Phase [X]: [Name] - Context

**Gathered:** [date]
**Status:** Ready for planning

<domain>
## Phase Boundary

[Clear statement of what this phase delivers]

</domain>

<decisions>
## Implementation Decisions

### [Category discussed]
- [Decision captured]

### Claude's Discretion
[Areas where user said "you decide"]

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- [Component/hook]: [How it could be used]

### Established Patterns
- [Pattern]: [How it constrains/enables this phase]

### Integration Points
- [Where new code connects to existing system]

</code_context>

<specifics>
## Specific Ideas

[Any "I want it like X" moments or specific references]

[If none: "No specific requirements — open to standard approaches"]

</specifics>

<deferred>
## Deferred Ideas

[Ideas that came up but belong in other phases]

[If none: "None — discussion stayed within phase scope"]

</deferred>

---
*Phase: [padded_phase]-[phase_slug]*
*Context gathered: [date]*
```

## Step 7: Commit and Confirm

```bash
git add ".planning/phases/[padded_phase]-[phase_slug]/[padded_phase]-CONTEXT.md"
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
