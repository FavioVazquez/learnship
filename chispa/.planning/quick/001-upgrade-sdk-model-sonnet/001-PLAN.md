# Quick Task 001: Upgrade SDK + Switch to claude-sonnet-4-6

**Task:** Upgrade Anthropic SDK to 0.99.0, switch model from claude-opus-4-7 to claude-sonnet-4-6 in all server files, update docs and artifacts.
**Date:** 2026-05-28

---

## Task 1 — Upgrade SDK and switch model

<files>
- server/package.json
- server/src/agent/analyzer.ts
- server/src/routes/index.ts
</files>

<action>
1. In server/package.json: change `@anthropic-ai/sdk` from `^0.30.0` to `^0.99.0`
2. Run `cd server && npm install` to install the new version
3. In server/src/agent/analyzer.ts: replace `claude-opus-4-7` with `claude-sonnet-4-6`
4. After install, check if `web_search_20250305` is now in the SDK's types — if so, remove the `as any` cast and the comment above it; otherwise keep the cast
5. In server/src/routes/index.ts: replace `claude-opus-4-7` with `claude-sonnet-4-6` in the health endpoint
</action>

<verify>
- `cd server && npm run typecheck` — 0 errors
- `grep -r "anthropic" server/package.json` shows 0.99.x
- `grep -r "sonnet-4-6" server/src/` shows both files updated
- `grep -r "opus" server/src/` returns nothing
</verify>

<done>
Server typechecks clean, both model references updated, SDK at 0.99.x
</done>

---

## Task 2 — Update all docs and artifacts

<files>
- README.md
- WORKSHOP.md
- AGENTS.md
- CHANGELOG.md
</files>

<action>
1. README.md tech stack table: update SDK version row and model row
2. WORKSHOP.md: update any `claude-opus-4-7` references
3. AGENTS.md Tech Stack section: update `@anthropic-ai/sdk ^0.30.0 — model claude-opus-4-7` → `^0.99.0 — model claude-sonnet-4-6`; sync to CLAUDE.md
4. CHANGELOG.md: add dated entry for this upgrade
</action>

<verify>
- `grep -r "opus-4-7" README.md WORKSHOP.md AGENTS.md CLAUDE.md` returns nothing
- `grep -r "0.30.0" README.md AGENTS.md CLAUDE.md` returns nothing
</verify>

<done>
All doc files reference claude-sonnet-4-6 and SDK 0.99.x. No stale opus references.
</done>
