---
title: Multi-Session Work
description: Patterns for pausing, resuming, and handing off work across sessions with learnship.
---

# Multi-Session Work

learnship is designed around the reality that real projects span many sessions. Here's how to manage context, continuity, and handoffs cleanly.

---

## Starting a session

Always start with:

```
/ls
```

It reads all state files and tells you exactly where you are, what was last done, and what to do next. If you're returning after a long break, it also detects incomplete plans and `.continue-here.md` handoff files.

Or use full auto-pilot:

```
/next
```

Reads state and immediately runs the correct next workflow. No status review — just continues.

---

## Pausing mid-phase

When stopping in the middle of a phase:

```
/pause-work
```

Creates `.planning/phases/[phase]/.continue-here.md` with:

```markdown
<current_state>
Phase 2, Plan 01-02, Task 3 of 5 — implementing the filtering logic
</current_state>

<completed_work>
- Task 1: GET /tasks endpoint — Done
- Task 2: POST /tasks with validation — Done
- Task 3: Filtering by status — In progress, query built, not yet tested
</completed_work>

<next_action>
Start with: complete the Prisma query for status filtering in TaskRepository.getFiltered()
Run: npm test to verify, then atomic commit
</next_action>
```

!!! tip "Before you go"
    `@agentic-learning space` — schedule what you worked on this session for spaced review. Two minutes now prevents re-learning later.

---

## Resuming work

```
/resume-work
```

Finds the `.continue-here.md` file, restores full context, and presents:

```
⚠️  Mid-plan handoff detected:
    Phase 2, Plan 01-02, Task 3 of 5
    Resume from: complete the Prisma query for status filtering

▶ Resuming now...
```

After consuming the handoff file, it's deleted automatically so the next `/ls` is clean.

!!! tip "After a long break"
    `@agentic-learning quiz [phase topic]` — warm up with active recall before diving in. Surfaces what's faded since the last session before it shows up as a bug.

---

## Handing off to a collaborator (or future you)

For longer breaks or team handoffs, create a comprehensive handoff document:

```
/transition
```

Produces `HANDOFF.md` at the project root with:

- Full project context and current state
- All active decisions and their rationale
- Open questions and blockers
- Exactly what to do next — step by step
- Key files and their purpose

More comprehensive than `/pause-work` — intended for situations where the next session may be someone else or weeks away.

---

## Typical multi-session project flow

```
Session 1:  /new-project
            /discuss-phase 1
            /plan-phase 1

Session 2:  /ls               ← where am I?
            /execute-phase 1  ← plans are ready, execute
            [mid-session stop]
            /pause-work       ← save handoff

Session 3:  /resume-work      ← pick up exactly where stopped
            @agentic-learning quiz [topic]  ← warm up first
            [continue execution]
            /verify-work 1

Session 4:  /ls               ← Phase 1 done, Phase 2 next
            /discuss-phase 2
            ...
```

---

## If `/ls` shows unexpected state

```
/health
```

Runs a full project health check — detects stale files, missing artifacts, uncommitted changes, and config drift. Use this when the project state feels off.

If `STATE.md` is missing entirely:

```
/resume-work
```

Will detect the missing file and reconstruct it from existing artifacts (`PROJECT.md`, `ROADMAP.md`, phase `SUMMARY.md` files).

---

## Managing context window degradation

For long sessions, context quality degrades as the window fills. learnship is designed around **fresh context windows** — each major workflow gets a clean slate:

- Start a new conversation for each `/execute-phase`
- Run `/resume-work` or `/ls` in the new conversation to restore state
- The agent reads `AGENTS.md` and `STATE.md` and is immediately oriented

This isn't a limitation — it's the design. Splitting work across fresh contexts produces more reliable execution than one very long degraded session.
