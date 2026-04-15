---
description: Show where you are in the project and what to do next — the fastest way to orient yourself and keep moving
---

# ls — Project Status

The quickest way to answer "where am I and what do I do next?" Works for new users and returning users alike.

**Usage:** `/ls`

---

## Step 1: Check for Project

```bash
node -e "const fs=require('fs'); console.log(fs.existsSync('.planning/PROJECT.md') ? 'EXISTS' : 'MISSING')"
```

**If MISSING** — no project initialized yet. Display:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 learnship ► WELCOME
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

No project found in this directory.

learnship is a multi-platform agentic engineering system —
spec-driven phases, context-engineered plans, atomic execution,
and a learning partner woven into every phase transition.

▶ To start: /new-project
▶ Not sure what to build? `@agentic-learning brainstorm [idea]` — think through it first
▶ Have an existing codebase? /ideate — scan for improvement opportunities
▶ For a quick one-off task: /quick "description"
▶ To see all commands: /help
```

Stop here.

---

## Step 2: Load State

Read key state files:

```bash
cat .planning/STATE.md
cat .planning/ROADMAP.md
```

Find the 2–3 most recent SUMMARY.md files:

```bash
node -e "const fs=require('fs'),path=require('path');function find(d){let r=[];try{for(const e of fs.readdirSync(d,{withFileTypes:true})){const f=path.join(d,e.name);r=r.concat(e.isDirectory()?find(f):e.name.endsWith('-SUMMARY.md')?[f]:[]);}}catch(e){}return r;}const files=find('.planning').map(f=>({f,t:fs.statSync(f).mtimeMs})).sort((a,b)=>b.t-a.t).slice(0,3).map(x=>x.f);files.forEach(f=>console.log(f));"
```

Read each for a one-liner summary of what was accomplished.

Check for a `.continue-here.md` handoff:

```bash
find .planning/phases -name ".continue-here.md" 2>/dev/null
```

---

## Step 3: Analyze Phase

For the current phase, count:

```bash
ls ".planning/phases/[current_phase_dir]/"*-PLAN.md 2>/dev/null | wc -l
ls ".planning/phases/[current_phase_dir]/"*-SUMMARY.md 2>/dev/null | wc -l
ls ".planning/phases/[current_phase_dir]/"*-UAT.md 2>/dev/null | wc -l
```

Check for diagnosed UAT gaps:

```bash
grep -l "status: diagnosed" .planning/phases/[current_phase_dir]/*-UAT.md 2>/dev/null
```

---

## Step 4: Display Status

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 learnship ► [Project Name]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Progress: [████████░░] [X]% — Phase [N] of [total]

Recent work:
  • [Phase, Plan]: [what was accomplished — 1 line]
  • [Phase, Plan]: [what was accomplished — 1 line]

Current phase: [N] — [phase-name]
  Plans: [done]/[total]   UAT: [status]
```

---

## Step 5: Route and Offer to Run

Determine the next action (same logic as `progress`):

1. **`.continue-here.md` exists** → mid-plan handoff
   - Next: `resume-work`

2. **UAT gaps (status: diagnosed)** → fix plans needed
   - Next: `plan-phase [X]` (gap closure mode)

3. **Plans exist, summaries < plans** → unfinished execution
   - Next: `execute-phase [X]`

4. **Plans = 0, CONTEXT.md exists** → ready to plan
   - Next: `plan-phase [X]`

5. **Plans = 0, no CONTEXT.md** → needs discussion
   - Next: `discuss-phase [X]`

6. **All plans have summaries, UAT not done** → verify before moving on
   - Next: `verify-work [X]`

7. **All plans have summaries, UAT passed, more phases remain** → move forward
   - Next: `discuss-phase [X+1]`
   - Suggest: `/review` → `/ship` → `/compound` before starting next phase

8. **All phases done** → ready to ship
   - Next: `audit-milestone`

Display clearly, then **ask**:

```
▶ Next: [workflow name]
  [one-line reason]

  Run it now? Type "yes" to proceed, or just keep chatting.
```

If the user says yes (or "go", "do it", "run it", "proceed") — immediately invoke that workflow.

---

## Notes

- `/ls` is an alias for the status + routing logic in `progress`. Use either.
- For full auto-pilot (no prompt), use `/next` instead.
- To see all 57 available commands: `/help`
