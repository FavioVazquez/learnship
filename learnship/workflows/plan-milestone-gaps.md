---
description: Create fix phases for all gaps found by audit-milestone
---

# Plan Milestone Gaps

Create all phases needed to close gaps identified by `audit-milestone`. One workflow creates all fix phases — no need to run `add-phase` per gap.

**Use after:** `audit-milestone` reports `gaps_found`.

## Step 1: Load Audit Results

Find the most recent audit file:
```bash
ls -t .planning/*-MILESTONE-AUDIT.md 2>/dev/null | head -1
```

If no audit file exists or status is `passed`:
```
No gaps found. Run audit-milestone first, or all gaps are already closed.
```
Stop.

Read the audit file and extract structured gaps:
- `gaps.requirements` — unsatisfied requirement IDs
- `gaps.integration` — broken cross-phase connections
- `gaps.flows` — broken E2E user flows
- `gaps.stubs` — stub/placeholder locations

## Step 2: Prioritize Gaps

Read `.planning/REQUIREMENTS.md` to get priority for each requirement gap:

| Priority | Treatment |
|----------|-----------|
| `must` / required | Always include — blocks milestone |
| `should` / recommended | Include by default |
| `nice-to-have` / optional | Ask user: include now or defer to next milestone? |

For integration and flow gaps: infer priority from the affected requirements.

If there are nice-to-have gaps, ask:
```
[N] optional gap(s) found. Include in fix phases or defer to next milestone?

- [gap description]
- [gap description]

Include (recommended) / Defer all / Choose individually
```

## Step 3: Group Gaps into Phases

Cluster related gaps into logical fix phases:

**Grouping rules:**
- Same affected source phase → combine into one fix phase
- Same subsystem (auth, API, UI, data layer) → combine
- Dependency order: fix broken exports before fixing callers
- Keep phases focused: 2-4 tasks each

Example:
```
Gap: REQ AUTH-02 unsatisfied (session not persisting)
Gap: Integration Phase 1→3 (auth token not passed to API calls)
Gap: Flow "User stays logged in" broken

→ Fix Phase: "Wire Auth Session"
  Tasks: persist session, pass token in API calls, handle expiry
```

## Step 4: Determine Phase Numbers

Find the highest existing phase number:
```bash
ls .planning/phases/ | grep -E "^[0-9]" | sort -V | tail -1
```

Gap closure phases continue from the highest existing phase + 1.

## Step 5: Present Gap Closure Plan

```
## Gap Closure Plan

Milestone: [VERSION]
Gaps to close: [N] requirements, [M] integration, [K] flows

### Proposed Fix Phases

**Phase [N]: [Name]**
Closes:
- [REQ-ID]: [description]
- Integration: [from phase] → [to phase]
Tasks: [count]

**Phase [N+1]: [Name]**
Closes:
- [REQ-ID]: [description]
Tasks: [count]

---

Create these [X] fix phase(s)? (yes / adjust)
```

Wait for confirmation.

## Step 6: Update ROADMAP.md

Append each gap closure phase to the current milestone section:

```markdown
## Phase [N]: [Name] *(gap closure)*

**Goal:** [what user can do after this phase]
**Closes:** [REQ-IDs and integration gaps being addressed]
**Status:** [ ] Not started
**Depends on:** [prior phase]
```

## Step 7: Update REQUIREMENTS.md

For each unsatisfied requirement being addressed:
- Update the Phase column to the new gap closure phase number
- Reset status to `Pending`
- Change `[x]` back to `[ ]` if it was incorrectly marked complete
- Update the coverage count at top of REQUIREMENTS.md

## Step 8: Create Phase Directories

```bash
for each gap closure phase:
  mkdir -p ".planning/phases/[NN]-[slug]"
done
```

## Step 9: Commit

```bash
git add .planning/ROADMAP.md .planning/REQUIREMENTS.md .planning/phases/
git commit -m "docs(roadmap): add gap closure phases [N]-[M] for [VERSION] audit"
```

## Step 10: Present Next Steps

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 learnship ► GAP CLOSURE PHASES CREATED ✓
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Phases added: [N] through [M]
Gaps addressed: [X] requirements, [Y] integration, [Z] flows

▶ Next: plan-phase [N]  (first gap closure phase)

After all gap phases are complete:
  audit-milestone   — re-audit to verify all gaps closed
  complete-milestone — archive when audit passes
```
