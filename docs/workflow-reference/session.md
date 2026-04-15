---
title: Session & Learning Extraction
description: "Capture ideas, generate reports, extract learnings, and summarize milestones."
---

# Session & Learning Extraction

Workflows for capturing ideas mid-flow, generating session summaries, extracting structured learnings from completed phases, and creating comprehensive milestone overviews.

**New in v2.1.0.**

---

## `/note`

Zero-friction idea capture. One write, one confirmation line. No questions.

```bash
/note "auth should use refresh tokens"    # save a note
/note list                                 # show all notes
/note promote 3                            # promote note #3 to todo/decision/phase
```

**What it does:**

1. Writes a timestamped markdown file to `.planning/notes/`
2. Confirms with exactly one line: `Noted: [text]`

**Subcommands:**

| Subcommand | What it does |
|------------|-------------|
| `note [text]` | Save a note — verbatim, no modifications |
| `note list` | Show all notes (numbered, sorted by date) |
| `note promote [N]` | Convert note to todo, decision, or phase proposal |

**Notes vs Todos:** Notes are observations and ideas. Todos are concrete actions. `/note` captures freely; `/add-todo` captures actionably.

---

## `/session-report`

Generate a post-session summary for stakeholder sharing or team standups.

```bash
/session-report
```

**What it does:**

1. Gathers git activity (last 24h), planning state, phase artifacts
2. Estimates session duration from commit timestamps
3. Generates a structured report with work performed, decisions, issues, next steps
4. Writes to `.planning/reports/SESSION-[date].md`

**Report sections:** Session summary, work performed, decisions made, issues encountered, files changed, next steps.

**Learning checkpoint:** `reflect`

---

## `/extract-learnings`

Extract structured meta-knowledge from completed phase artifacts.

```bash
/extract-learnings 3        # extract from phase 3
```

**What it does:**

1. Reads all PLAN.md and SUMMARY.md files for the phase (required)
2. Optionally reads VERIFICATION.md, UAT.md, SECURITY.md, STATE.md
3. Extracts learnings into 4 categories with source attribution
4. Writes LEARNINGS.md to the phase directory

**The 4 categories:**

| Category | What it captures |
|----------|-----------------|
| **Decisions** | Technology choices, trade-offs, rationale |
| **Lessons** | What worked, what didn't, why it matters |
| **Patterns** | Reusable code/process/integration patterns |
| **Surprises** | Unexpected bugs, wrong assumptions, external factors |

**Complements `/compound`:** compound captures reusable *solutions*; extract-learnings captures *meta-knowledge* (why things worked, what patterns emerged).

**Learning checkpoint:** `space` · `interleave`

---

## `/milestone-summary`

Generate a comprehensive milestone summary for team onboarding.

```bash
/milestone-summary           # current milestone
/milestone-summary 1.0       # specific version
```

**What it does:**

1. Locates milestone artifacts (current or archived)
2. Reads ROADMAP, REQUIREMENTS, phase CONTEXT/SUMMARY/VERIFICATION/LEARNINGS files
3. Synthesizes into a single human-readable document
4. Writes `.planning/MILESTONE-SUMMARY-v{VERSION}.md`

**Designed for onboarding:** A new contributor reads the summary and understands the entire project — what was built, why, key decisions, lessons learned, and how to get started.

**Learning checkpoint:** `reflect`
