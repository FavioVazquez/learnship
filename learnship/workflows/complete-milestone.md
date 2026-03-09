---
description: Archive a completed milestone, tag the release, and prepare for the next version
---

# Complete Milestone

Mark the current milestone as shipped. Archives plans and requirements, updates the roadmap, tags the git release, and sets up for the next milestone.

**Use when:** all phases in the current milestone are complete and verified.

## Step 1: Verify Readiness

Read `.planning/ROADMAP.md` and `.planning/REQUIREMENTS.md`.

Check every phase in the milestone:
```bash
for phase_dir in .planning/phases/*/; do
  plans=$(ls "${phase_dir}"*-PLAN.md 2>/dev/null | wc -l)
  summaries=$(ls "${phase_dir}"*-SUMMARY.md 2>/dev/null | wc -l)
  echo "${phase_dir}: ${plans} plans, ${summaries} summaries"
done
```

Present readiness report:
```
Milestone: [Name]

| Phase | Plans | Summaries | Status |
|-------|-------|-----------|--------|
| 1: [Name] | [N] | [N] | ✓ Complete |
| 2: [Name] | [N] | [N] | ✓ Complete |
...

Requirements: [X] of [Y] v1 requirements checked off
```

**If any phase incomplete** (plans > summaries): stop and show which phases need execution.

**If requirements incomplete**: list unchecked requirements and ask to proceed anyway or address them first.

Ask for confirmation:
- **Archive and tag release** → proceed
- **Not ready — I need to finish something** → stop

## Step 2: Determine Version

Read `.planning/STATE.md` and check for existing version tags:
```bash
git tag --list "v*" | sort -V | tail -5
```

Propose the next version (e.g., `v1.0`, `v1.1`, `v2.0`). Ask for confirmation or let user specify.

## Step 3: Archive Milestone Artifacts

Create the milestones archive directory:
```bash
mkdir -p .planning/milestones
```

Archive the roadmap for this milestone:
```bash
cp .planning/ROADMAP.md ".planning/milestones/${VERSION}-ROADMAP.md"
```

Archive the requirements:
```bash
cp .planning/REQUIREMENTS.md ".planning/milestones/${VERSION}-REQUIREMENTS.md"
```

## Step 4: Update ROADMAP.md

Replace the current milestone's detailed phases with a one-line summary per milestone section:

```markdown
## Completed Milestones

### [VERSION] — [Milestone Name]
Completed [date]. [N] phases, [M] requirements delivered. See `.planning/milestones/[VERSION]-ROADMAP.md` for full details.

---
```

Delete `.planning/REQUIREMENTS.md` (a fresh one will be created for the next milestone):
```bash
git rm .planning/REQUIREMENTS.md
```

## Step 5: Update PROJECT.md

Read `.planning/PROJECT.md` and update:
- Bump version reference
- Move "Active" requirements that were completed to "Validated"
- Update the "Key Decisions" table with final outcomes
- Update the "Last updated" footer

## Step 6: Create Milestone Summary in STATE.md

Add a milestone completion entry to STATE.md:

```markdown
## Milestone History

### [VERSION] — [Milestone Name]
Completed: [date]
Phases: [N]
Requirements delivered: [list of REQ-IDs]
Key achievements: [2-3 sentence summary]
```

## Step 7: Git Tag the Release

Commit all updated artifacts:
```bash
git add .planning/
git commit -m "docs: archive milestone [VERSION]"
```

Tag the release:
```bash
git tag -a "[VERSION]" -m "Milestone [VERSION]: [Milestone Name]

[2-3 sentence summary of what was built]

Phases: [N]
Requirements: [M] delivered"
```

Display:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 MILESTONE [VERSION] COMPLETE ✓
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**[Milestone Name]**
[N] phases complete | [M] requirements delivered
Tagged: [VERSION]

Archives:
- .planning/milestones/[VERSION]-ROADMAP.md
- .planning/milestones/[VERSION]-REQUIREMENTS.md
```

## Step 7b: Update AGENTS.md

If `AGENTS.md` exists at the project root, update:

1. **Current Phase block** — mark milestone complete:
```markdown
## Current Phase

**Milestone:** [VERSION] — [Milestone Name] ✓ shipped
**Phase:** —
**Status:** milestone complete — ready for next milestone
**Last updated:** [today's date]
```

2. **Project Structure** — update if the milestone added significant new modules.

```bash
git add AGENTS.md
git commit -m "docs: update AGENTS.md — milestone [VERSION] complete"
```

## Step 8: Offer Next Milestone

Ask: "Ready to start the next milestone?"

- **Yes, start planning next milestone** → Run `new-project` logic adapted for a new milestone on an existing codebase:
  - Skip git init (already exists)
  - Ask what to build next
  - Research the new feature domain
  - Define new requirements
  - Create new ROADMAP.md
- **Not yet** → stop here

---

## Learning Checkpoint

Read `learning_mode` from `.planning/config.json`.

**If `auto`:** Offer:

> 💡 **Learning moment:** Milestone [VERSION] is shipped. This is the right time for a deep reflection.
>
> `@agentic-learning reflect` — What did you learn building this? What was your goal? What gaps remain for the next milestone?
>
> `@agentic-learning space` — Schedule the key concepts from this milestone for spaced review before the next one starts.

**If `manual`:** Add quietly: *"Tip: `@agentic-learning reflect` for a milestone retrospective."*
