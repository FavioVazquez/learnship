---
description: Analyze an existing codebase and produce structured reference docs before starting a new project on top of it
---

# Map Codebase

Analyze an existing codebase through structured focused exploration. Produces 7 structured documents in `.planning/codebase/` that feed into `new-project` when adding features to existing code.

**Use before:** `/new-project` on a brownfield (existing) codebase.

**Philosophy:** Each agent gets fresh context, explores a specific domain, and writes documents directly. The orchestrator only confirms what was created — it never receives document contents.

## Step 1: Check Existing Maps

```bash
ls .planning/codebase/ 2>/dev/null
```

If `.planning/codebase/` already exists with documents:

```
.planning/codebase/ already exists:
- [list files found]

Options:
1. Refresh — delete and remap from scratch
2. Update — only re-run specific agents
3. Skip — use existing map as-is
```

Wait for response before continuing.

## Step 2: Create Output Directory

```bash
mkdir -p .planning/codebase
```

Expected output files:
- `STACK.md` — technologies and dependencies
- `INTEGRATIONS.md` — external APIs, databases, auth
- `ARCHITECTURE.md` — patterns, layers, data flow
- `STRUCTURE.md` — directory layout, naming conventions
- `CONVENTIONS.md` — code style, patterns, error handling
- `TESTING.md` — test framework, structure, coverage
- `CONCERNS.md` — tech debt, security, fragile areas

## Step 3: Run Structured Mapping

For each dimension below, adopt the relevant `@./agents/researcher.md` persona, explore the codebase thoroughly, and write the document directly.

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 learnship ► MAPPING CODEBASE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Running structured analysis...
```

**Agent 1 — Tech Stack:**
Explore: languages, runtime, frameworks, package.json/requirements.txt, build config, env vars.
Write: `STACK.md` (stack overview, versions, key libraries) + `INTEGRATIONS.md` (external APIs, databases, auth providers, webhooks, message queues).

**Agent 2 — Architecture:**
Explore: entry points, module structure, data flow, abstractions, dependency injection patterns, shared utilities.
Write: `ARCHITECTURE.md` (overall pattern — monolith/microservices/serverless, layers, data flow, key abstractions) + `STRUCTURE.md` (directory map with purpose of each directory, file naming conventions, where to find things).

**Agent 3 — Conventions & Quality:**
Explore: code style, linting config, existing patterns for common operations (error handling, logging, validation), test files.
Write: `CONVENTIONS.md` (coding style enforced, naming patterns, common idioms, what NOT to do based on existing code) + `TESTING.md` (test framework, structure, mocking approach, coverage state, how to run tests).

**Agent 4 — Concerns:**
Explore: TODO/FIXME/HACK comments, large files, circular dependencies, outdated packages, security patterns (secrets, auth, input validation).
Write: `CONCERNS.md` (tech debt items, known bugs, security concerns, performance bottlenecks, fragile areas the planner should avoid or tread carefully around).

## Step 4: Security Check

Before committing, scan for accidentally captured secrets:

```bash
grep -rE '(sk-[a-zA-Z0-9]{20,}|sk_live_|sk_test_|ghp_[a-zA-Z0-9]{36}|AKIA[A-Z0-9]{16}|-----BEGIN.*PRIVATE KEY)' .planning/codebase/*.md 2>/dev/null && echo "SECRETS_FOUND" || echo "CLEAN"
```

**If secrets found:**
```
⚠️  SECURITY ALERT: Potential secrets detected in codebase documents.

[Show what was found]

Review and remove sensitive values before committing.
Reply "safe" once clean, or I'll skip the commit.
```

Wait for confirmation.

## Step 5: Verify Output

```bash
ls -la .planning/codebase/
wc -l .planning/codebase/*.md 2>/dev/null
```

Report any missing or suspiciously short documents (< 20 lines = likely empty).

## Step 6: Commit

```bash
git add .planning/codebase/
git commit -m "docs: map existing codebase"
```

## Step 7: Present Summary

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 learnship ► CODEBASE MAPPED ✓
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Created .planning/codebase/:
- STACK.md ([N] lines) — Technologies and dependencies
- ARCHITECTURE.md ([N] lines) — System design and patterns
- STRUCTURE.md ([N] lines) — Directory layout and organization
- CONVENTIONS.md ([N] lines) — Code style and patterns
- TESTING.md ([N] lines) — Test structure and practices
- INTEGRATIONS.md ([N] lines) — External services and APIs
- CONCERNS.md ([N] lines) — Technical debt and issues

▶ Next: new-project (questions will focus on what you're ADDING)
```

---

## Learning Checkpoint

Read `learning_mode` from `.planning/config.json`.

**If `auto`:** Offer:

> 💡 **Learning moment:** Codebase mapped. Test your understanding before building on top of it:
>
> `@agentic-learning explain [codebase/module name]` — Explain the architecture back in your own words. Gaps in the explanation reveal gaps in the mental model — before they become bugs.

**If `manual`:** Add quietly: *"Tip: `@agentic-learning explain [codebase]` to verify your understanding of the architecture."*
