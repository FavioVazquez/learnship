---
title: Navigation
description: Reference for learnship navigation and utility workflows — ls, next, quick, resume-work, pause-work.
---

# Navigation

These workflows handle session management, orientation, and ad-hoc tasks.

---

## `/ls`

Shows current project status and what to do next. Run this at the start of every session.

**What it shows:**
- Current phase, position, and progress bar
- Last activity and timestamp
- Recommended next step — with an offer to run it

**New user (no project):** Explains learnship and offers to run `/new-project`.  
**Returning user:** Shows progress and routes you into the next workflow.

---

## `/next`

Auto-pilot — reads state and immediately runs the correct next workflow.

**Use when:** You trust the state is current and just want to keep moving without reviewing the status first.

Under the hood: same logic as `/ls`, but dispatches immediately instead of asking.

---

## `/progress`

Identical to `/ls` — full status overview and smart routing. An alias for users who prefer the word "progress" over "ls".

---

## `/resume-work`

Restores full project context after a break or in a new session.

**What it does:**
1. Reads `STATE.md`, `PROJECT.md`, and `ROADMAP.md`
2. Checks for `.continue-here.md` handoff files from `/pause-work`
3. Detects incomplete plans (PLAN without SUMMARY)
4. Presents a clear status panel and recommended next action

**Learning checkpoint:** `quiz [phase topic]` · `space` — warm up after a break before diving in.

---

## `/pause-work`

Saves a handoff file so you can resume seamlessly in a future session.

**What it creates:** `.planning/phases/[phase]/.continue-here.md` with:
- Exact position (phase, plan, task)
- What's completed vs. in progress
- Key decisions made this session
- Blockers
- The specific first action to take when resuming

**Learning checkpoint:** `space` · `reflect` — schedule what you worked on before closing.

---

## `/quick "[description]"`

Executes a small, self-contained task with full guarantees. No phase planning ceremony.

```bash
/quick "Fix login button not responding on mobile Safari"
/quick --discuss "Add dark mode toggle"
/quick --full "Refactor auth middleware to support OAuth"
```

**Flags:**

| Flag | What it adds |
|------|-------------|
| *(none)* | Minimal: plan → execute → atomic commit |
| `--discuss` | Brief decision conversation before executing |
| `--full` | Full plan + execute + verification pass |

**Learning checkpoint:** `struggle` · `learn` · `either-or` — matched to what happened during the task.

---

## `/help`

Lists all 42 workflows organized by category with one-line descriptions.

```
/help
```

Use this to discover capabilities — scope management, debugging workflows, decision logging, milestone management, and more.

---

## `/transition`

Writes a full `HANDOFF.md` document for handing off to a new session or collaborator.

Contains: full project context, current state, open decisions, blockers, and exactly what to do next. More comprehensive than `/pause-work` — intended for longer breaks or team handoffs.
