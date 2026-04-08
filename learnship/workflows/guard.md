---
description: Safety mode — warn on destructive commands, lock file scope
---

# Guard

Safety mode for sensitive phases. Warns before destructive commands, locks file scope to prevent accidental changes outside the working area, and persists guard state across sessions.

**Usage:** `guard [scope]` — activate guard mode for a specific scope (directory, file pattern, or phase)
**Usage:** `guard off` — deactivate guard mode

## Step 1: Parse Arguments

If argument is `off` → deactivate guard mode (Step 6).

Otherwise, interpret the scope:
- **Directory path** (e.g., `src/auth/`) → guard all files under that path
- **File pattern** (e.g., `*.migration`) → guard files matching the pattern
- **Phase number** (e.g., `3`) → guard files modified by that phase's plans
- **No argument** → guard the current phase's file scope

## Step 2: Determine File Scope

**If a directory or pattern was provided:** Use it directly.

**If a phase number was provided:**
```bash
# Extract files_modified from all plans in the phase
grep -h "files_modified" .planning/phases/[padded_phase]-*/*-PLAN.md -A 50 2>/dev/null | grep "^ *-" | sed 's/^ *- //'
```

**If no argument — auto-detect from current phase:**
```bash
# Read current phase from STATE.md
cat .planning/STATE.md 2>/dev/null | grep -i "phase"

# Get files from current phase plans
grep -rh "files_modified" .planning/phases/$(ls .planning/phases/ | sort | tail -1)/*-PLAN.md -A 50 2>/dev/null | grep "^ *-" | sed 's/^ *- //'
```

**Brownfield enhancement:** If `.planning/codebase/CONCERNS.md` exists, read it and auto-suggest guard scope for files flagged as high-risk:
```bash
cat .planning/codebase/CONCERNS.md 2>/dev/null | grep -i "risk\|sensitive\|critical\|production"
```

## Step 3: Activate Guard

Write guard state to `.planning/guard-state.md`:

```markdown
---
active: true
activated: [ISO timestamp]
scope: [description of what's guarded]
---

# Guard Mode Active

## Protected Scope

[list of files/directories/patterns being guarded]

## Destructive Command Warnings

The following commands will trigger a warning before execution:
- `rm`, `rm -rf`, `git reset --hard`, `git clean -fd`
- `DROP TABLE`, `DELETE FROM`, `TRUNCATE`
- `git push --force`, `git rebase` (on shared branches)
- Any write to files outside the guarded scope

## Session Log

- [timestamp]: Guard activated — scope: [scope description]
```

```bash
git add .planning/guard-state.md
git commit -m "docs: activate guard mode — scope: [description]"
```

Display:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 learnship ► GUARD MODE ACTIVE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Protected scope:
[list of guarded files/dirs]

Warnings will trigger for:
- Destructive commands (rm -rf, git reset --hard, DROP TABLE)
- Writes outside guarded scope
- Force pushes and rebases on shared branches

▶ Run: guard off  — to deactivate
```

## Step 4: Guard Behavior (While Active)

When guard mode is active (`.planning/guard-state.md` exists with `active: true`):

**Before any file write:** Check if the target file is within the guarded scope.
- **Inside scope** → proceed normally
- **Outside scope** → warn: "⚠ Guard: This file is outside the guarded scope ([scope]). Proceed anyway?"

**Before destructive commands:** Always warn:
```
⚠ Guard: Destructive command detected: [command]
This will [description of what it does].
Proceed? (yes/no)
```

**Log all guard events** to the Session Log in `guard-state.md`.

## Step 5: Persistent State

Guard mode persists across sessions via `.planning/guard-state.md`. Any workflow that reads `.planning/config.json` should also check for active guard state:

```bash
# Check if guard is active
grep -q "active: true" .planning/guard-state.md 2>/dev/null && echo "GUARD_ACTIVE"
```

## Step 6: Deactivate

When `guard off` is invoked:

Update `.planning/guard-state.md`:
```markdown
---
active: false
activated: [original timestamp]
deactivated: [ISO timestamp]
scope: [original scope]
---
```

```bash
git add .planning/guard-state.md
git commit -m "docs: deactivate guard mode"
```

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 learnship ► GUARD MODE DEACTIVATED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Guard was active for: [duration]
Events logged: [N]
```

---

## Learning Checkpoint

Read `learning_mode` from `.planning/config.json`.

**If `auto`:** After activating guard, offer:

> 💡 **Learning moment:** Safety modes reflect risk awareness:
>
> `@agentic-learning either-or` — When should you use guard mode vs just being careful? Log the decision criteria for future reference.

**If `manual`:** Add quietly: *"Tip: `@agentic-learning either-or` to log when guard mode is worth the overhead."*
