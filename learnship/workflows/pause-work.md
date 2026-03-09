---
description: Save a handoff file when stopping mid-phase so you can resume seamlessly later
---

# Pause Work

Create a `.continue-here.md` handoff file that captures complete work state. Enables seamless resumption with full context restoration.

**Use when:** stopping mid-plan, mid-phase, or any time you want to preserve exact position.

## Step 1: Detect Current Phase

Find the most recently active phase:
```bash
find .planning/phases -name "*-PLAN.md" -type f 2>/dev/null | xargs ls -t 2>/dev/null | head -1
```

Extract the phase directory name from the result.

If no active phase detected, ask: "Which phase are you pausing work on?"

## Step 2: Gather State

Collect the complete handoff state by reading current files:

```bash
cat ".planning/phases/[phase_dir]/"*-PLAN.md 2>/dev/null
cat .planning/STATE.md
```

Also ask the user (conversationally) for anything that can't be inferred from files:
- Which specific task were you on?
- What's already completed vs. what's in progress?
- Any key decisions made this session that aren't yet committed?
- Any blockers or things to watch out for?
- What's the very first thing to do when resuming?

## Step 3: Write Handoff File

Write `.planning/phases/[phase_dir]/.continue-here.md`:

```markdown
---
phase: [phase_dir]
task: [current task number]
total_tasks: [total tasks in current plan]
status: in_progress
last_updated: [ISO timestamp]
---

<current_state>
[Where exactly are we? Phase X, Plan Y, Task Z — immediate context for a fresh session]
</current_state>

<completed_work>
- Task 1: [name] — Done
- Task 2: [name] — Done
- Task 3: [name] — In progress, [what's done so far]
</completed_work>

<remaining_work>
- Task 3: [what's left to complete]
- Task 4: Not started
- Task 5: Not started
</remaining_work>

<decisions_made>
- Decided to use [X] because [reason]
- Chose [approach] over [alternative] because [reason]
</decisions_made>

<blockers>
- [Any blocker]: [status or workaround]
</blockers>

<context>
[The mental model: what approach is being taken, why, what to watch out for]
</context>

<next_action>
Start with: [the specific first action to take when resuming — be precise]
</next_action>
```

Be specific enough that a fresh Cascade session can pick up immediately without re-asking.

## Step 4: Commit

```bash
git add ".planning/phases/[phase_dir]/.continue-here.md"
git commit -m "wip: [phase-name] paused at task [X]/[Y]"
```

## Step 5: Confirm

```
✓ Handoff created: .planning/phases/[phase_dir]/.continue-here.md

Current state:
- Phase: [phase_dir]
- Task: [X] of [Y]
- Status: in_progress
- Committed as WIP

▶ To resume: resume-work
```
