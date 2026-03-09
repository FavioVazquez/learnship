---
description: Aggregate key learnings and decisions across all sessions into a searchable KNOWLEDGE.md
---

# Knowledge Base

Aggregate key learnings, decisions, and patterns from all sessions into a single searchable `KNOWLEDGE.md`. The knowledge base is the project's institutional memory — it compounds across milestones.

**Usage:** `knowledge-base` — rebuild/update from all sources
**Usage:** `knowledge-base search [query]` — search the knowledge base

## Step 1: Determine Mode

If `search [query]` argument provided → skip to **Search Mode** at end.

Otherwise → build/update mode.

## Step 2: Locate All Sources

```bash
# Decisions register
cat .planning/DECISIONS.md 2>/dev/null

# Debug session resolutions
ls .planning/debug/resolved/ 2>/dev/null

# Retrospectives
ls .planning/milestones/*-RETROSPECTIVE.md 2>/dev/null

# Phase research files
find .planning/ -name "*-RESEARCH.md" | sort

# AGENTS.md regressions
grep -A 5 "### 20" AGENTS.md 2>/dev/null
```

## Step 3: Extract Knowledge

From each source, extract structured knowledge items:

**From DECISIONS.md:**
- Each DEC-XXX entry → Knowledge item: `decision`

**From debug resolved sessions:**
- Each session's root cause + lesson → Knowledge item: `lesson`

**From retrospectives:**
- "What worked well" → Knowledge item: `pattern`
- "What to avoid" → Knowledge item: `anti-pattern`
- "Carry forward" → Knowledge item: `carry-forward`

**From RESEARCH.md files:**
- "Don't Hand-Roll" entries → Knowledge item: `library`
- "Common Pitfalls" entries → Knowledge item: `pitfall`

Deduplicate: if the same concept appears multiple times, merge into one entry with multiple `sources`.

## Step 4: Write / Update KNOWLEDGE.md

Write `.planning/KNOWLEDGE.md`:

```markdown
---
updated: [date]
items: [N]
---

# Project Knowledge Base

Aggregated learnings from [N] decisions, [M] debug sessions, [K] retrospectives.

---

## Decisions

### DEC-001: [title]
**Type:** architecture | library | scope | pattern
**Phase:** [N] | **Date:** [date]
**Choice:** [what was decided]
**Rationale:** [why]
**Still active:** yes | superseded by DEC-XXX

[...repeat for each decision...]

---

## Lessons Learned

### [YYYY-MM-DD]: [title]
**From:** debug session | retrospective
**What broke:** [description]
**Root cause:** [cause]
**Lesson:** [what to do differently]

[...repeat...]

---

## Patterns That Work

- **[Pattern name]**: [description — what it is and why it works here]
- **[Pattern name]**: [description]

---

## Anti-Patterns to Avoid

- **[Anti-pattern]**: [what it is] — [why it fails in this project]
- **[Anti-pattern]**: [description]

---

## Libraries & Tools

| Tool | Use for | Notes |
|------|---------|-------|
| [lib] | [purpose] | [any caveats] |

---

## Open Questions

Questions surfaced during work that haven't been fully resolved:

- [question] (from [source])
```

## Step 5: Commit

```bash
git add .planning/KNOWLEDGE.md
git commit -m "docs: update knowledge base ([N] items)"
```

## Step 6: Confirm

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 learnship ► KNOWLEDGE BASE UPDATED ✓
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Items: [N] total
  Decisions: [N]
  Lessons: [N]
  Patterns: [N]
  Anti-patterns: [N]

Saved: .planning/KNOWLEDGE.md
```

---

## Search Mode

If `knowledge-base search [query]` was invoked:

```bash
grep -i "[query]" .planning/KNOWLEDGE.md 2>/dev/null
grep -i "[query]" .planning/DECISIONS.md 2>/dev/null
```

Display matching sections with context. If no results:
```
No results for "[query]" in knowledge base.

Try: knowledge-base  (rebuild from all sources first)
     or search with broader terms
```
