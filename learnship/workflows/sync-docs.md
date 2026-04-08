---
description: Detect stale documentation after code changes
---

# Sync Docs

Scan documentation against recent code changes to detect stale sections, outdated references, and drift between docs and implementation. Auto-update simple cases, flag complex ones for manual review.

**Usage:** `sync-docs` — scan all docs for staleness
**Usage:** `sync-docs [path]` — scan docs for a specific module or directory

## Step 1: Discover Documentation

Find all documentation files in the project:

```bash
# README and top-level docs
find . -maxdepth 1 -name "*.md" -type f 2>/dev/null

# Docs directory
find docs/ -name "*.md" -type f 2>/dev/null

# API docs, guides, etc.
find . -path "*/docs/*" -name "*.md" -type f 2>/dev/null | head -30

# Planning docs
find .planning/ -name "*.md" -type f 2>/dev/null | grep -v "phases\|debug\|milestones" | head -20
```

If a path argument was provided, narrow the scan to docs related to that module.

## Step 2: Identify Recent Changes

```bash
# Get files changed in last 30 commits
git log --oneline -30 --format="" --name-only | sort -u

# Get files changed since last tag/release
LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null)
if [ -n "$LAST_TAG" ]; then
  git diff --name-only "$LAST_TAG"..HEAD
fi
```

Map changed source files to their documentation:
- `src/auth/` changes → check docs mentioning auth, authentication, login
- API route changes → check API documentation
- Config changes → check setup/installation docs
- Schema changes → check data model docs

## Step 3: Scan for Staleness

For each documentation file, check:

1. **Dead references** — does the doc reference files, functions, or APIs that no longer exist?
```bash
# Extract code references from doc (backtick-wrapped paths, function names)
grep -oE '`[^`]+\.(ts|js|py|rb|go)`' [doc_file] 2>/dev/null
# Check if referenced files exist
```

2. **Outdated descriptions** — does the doc describe behavior that's changed?
- Compare doc descriptions against actual code behavior
- Check version numbers, dependency names, command syntax

3. **Missing coverage** — are there new files/features with no documentation?
```bash
# Find source files with no corresponding doc mention
for file in $(git log --oneline -30 --format="" --name-only | sort -u | grep -E '\.(ts|js|py|rb|go)$'); do
  BASENAME=$(basename "$file" | sed 's/\.[^.]*$//')
  grep -ril "$BASENAME" docs/ 2>/dev/null | wc -l | tr -d ' '
done
```

## Step 4: Report Findings

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 learnship ► DOC SYNC REPORT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Scanned: [N] documentation files
Changes since: [last tag or last 30 commits]

## Stale Sections

| Doc | Section | Issue | Severity |
|-----|---------|-------|----------|
| [file] | [heading] | [what's wrong] | high/medium/low |

## Dead References

| Doc | Reference | Status |
|-----|-----------|--------|
| [file] | `[reference]` | removed / renamed to [new name] |

## Missing Documentation

| New File/Feature | Suggested Doc |
|------------------|---------------|
| [file] | Add to [existing doc] or create new |

## Auto-Fixable

[N] issues can be auto-fixed (renamed references, updated paths)
```

## Step 5: Auto-Fix Simple Cases

For issues that can be fixed automatically (renamed files, updated paths, version numbers):

```bash
# Apply fixes
sed -i 's/old_reference/new_reference/g' [doc_file]

git add [fixed files]
git commit -m "docs: sync — fix [N] stale references"
```

For complex issues (rewritten behavior, new feature descriptions), present to user:

```
These [N] issues need manual review:
1. [doc]: [section] — [what needs updating and why]
2. [doc]: [section] — [what needs updating and why]
```

## Step 6: Confirm

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 learnship ► DOC SYNC COMPLETE ✓
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Auto-fixed: [N] issues
Manual review needed: [M] issues
Missing docs: [K] new features without documentation
```

---

## Integration Points

- `complete-milestone`: optionally run `/sync-docs` before releasing
- `release`: suggest `/sync-docs` as pre-release checklist item

---

## Learning Checkpoint

Read `learning_mode` from `.planning/config.json`.

**If `auto`:** After sync, offer:

> 💡 **Learning moment:** Documentation drift is a signal about process:
>
> `@agentic-learning reflect` — Why did these docs get stale? Is there a pattern (e.g., docs always lag behind API changes)? Reflecting on the drift pattern prevents it next time.

**If `manual`:** Add quietly: *"Tip: `@agentic-learning reflect` to understand why docs drifted and prevent it."*
