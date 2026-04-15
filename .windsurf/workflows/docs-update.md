---
description: Generate, update, and verify project documentation — detects project type, builds doc queue, verifies against live codebase
---

# Docs Update

Generate, update, and verify project documentation. Detects the project's doc structure, assembles a work manifest, writes or updates docs, and verifies factual claims against the live codebase.

**Usage:** `docs-update` or `docs-update --force` (skip confirmations)

## Step 1: Detect Project Type

Scan the project root for signals:

```bash
ls package.json Makefile Cargo.toml go.mod setup.py pyproject.toml 2>/dev/null
ls .github/workflows/ .gitlab-ci.yml Dockerfile docker-compose.yml 2>/dev/null
ls LICENSE CONTRIBUTING.md 2>/dev/null
find . -maxdepth 2 -name "*.test.*" -o -name "*_test.*" -o -name "test_*" 2>/dev/null | head -5
```

Classify the project:

| Condition | Primary Type |
|-----------|-------------|
| Multiple package.json files at different levels | `monorepo` |
| `bin` field in package.json AND no API routes | `cli-tool` |
| API routes detected AND not open source | `saas` |
| LICENSE file AND no API routes | `open-source-library` |
| None of the above | `generic` |

## Step 2: Build Doc Queue

**Always-on docs (every project):**
1. README.md
2. ARCHITECTURE.md
3. GETTING-STARTED.md
4. DEVELOPMENT.md
5. TESTING.md
6. CONFIGURATION.md

**Conditional docs (add if signal matched):**
- API.md — if API routes detected
- CONTRIBUTING.md — if open source (LICENSE exists)
- DEPLOYMENT.md — if deploy config detected (Dockerfile, CI/CD)

**CHANGELOG.md is NEVER queued** — it's manually maintained.

Maximum 9 docs total.

## Step 3: Check Existing Docs

```bash
find . -maxdepth 2 -name "*.md" -not -path "./.planning/*" -not -path "./node_modules/*" 2>/dev/null
```

For each doc in the queue, determine mode:
- **Create** — doc doesn't exist yet
- **Update** — doc exists, check if it's stale

Display the plan:
```
learnship > DOCS UPDATE

Project type: [type]
Docs to create: [N]
Docs to update: [M]

| Doc | Mode | Status |
|-----|------|--------|
| README.md | update | exists, checking freshness |
| ARCHITECTURE.md | create | new |
| ... | ... | ... |

[Proceed] / [Customize queue] / [Cancel]
```

## Step 4: Write/Update Docs

For each doc in the queue:

### Create mode

Read relevant source files to understand the project structure, then write the doc grounded in the actual codebase. Every claim must be verifiable.

### Update mode

Read the existing doc AND the current codebase. Identify stale sections (references to renamed files, outdated instructions, missing new features). Update only stale sections — preserve the author's voice and structure.

For each doc, after writing:
```bash
git add [doc path]
```

## Step 5: Verify Docs Against Codebase

For each written/updated doc, verify factual claims:

- File paths mentioned in docs actually exist
- Commands shown in docs actually work
- Configuration examples match the actual schema
- API endpoints documented match the actual routes

```bash
# Example: check all file references in a doc
grep -oE '\`[a-zA-Z0-9_./-]+\.[a-z]+\`' [doc] | tr -d '`' | while read f; do
  [ -f "$f" ] || echo "MISSING: $f referenced in [doc]"
done
```

If verification finds issues: fix the doc, don't flag it as a separate issue.

## Step 6: Commit and Report

```bash
git add -A
git commit -m "docs: update project documentation ([N] docs)"
```

```
learnship > DOCS UPDATE COMPLETE

| Doc | Mode | Verified |
|-----|------|----------|
| README.md | updated | yes |
| ARCHITECTURE.md | created | yes |
| ... | ... | ... |

[N] docs written/updated, all verified against codebase.
```

---

## Learning Checkpoint

Read `learning_mode` from `.planning/config.json`.

**If `auto`:**

> **Learning moment:** Writing documentation forces you to articulate what was built:
>
> `@agentic-learning explain [project topic]` — Explain the architecture or a key feature in your own words. Gaps in the explanation reveal gaps in understanding. Writes a comprehension log to `docs/project-knowledge.md`.

**If `manual`:** Add quietly: *"Tip: `@agentic-learning explain [topic]` to test your understanding of what was documented."*
