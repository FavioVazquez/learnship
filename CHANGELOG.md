# Changelog

All notable changes to **learnship** are documented here.

This project uses [semantic versioning](https://semver.org/): `MAJOR.MINOR.PATCH`
- **MAJOR** — significant new capability layers or breaking changes
- **MINOR** — new workflows, skills, or agent personas
- **PATCH** — bug fixes to existing workflows

---

## [v2.2.0] — 2026-04-15

### Added

- **Claude Code native hooks** — 4 hooks installed via `settings.json` for Claude Code and Gemini CLI:
  - `learnship-statusline.js` — Status bar showing model, task/phase, directory, and context usage bar (green → yellow → orange → red+skull)
  - `learnship-context-monitor.js` — PostToolUse hook that warns the AI at 35% remaining (WARNING) and 25% remaining (CRITICAL) context, preventing new work when context is nearly exhausted
  - `learnship-prompt-guard.js` — PreToolUse hook that scans `.planning/` file writes for prompt injection patterns (advisory only, does not block)
  - `learnship-session-state.js` — SessionStart hook that injects STATE.md orientation and triggers background update checks
- **Research file templates** — 5 structured templates in `learnship/templates/research-project/` (STACK.md, FEATURES.md, ARCHITECTURE.md, PITFALLS.md, SUMMARY.md) with `<template>` and `<guidelines>` blocks. The AI reads these before writing research files, giving it a concrete fill-in-the-blanks target instead of just `##` header names.
- **Context profiles** — 3 output mode profiles in `learnship/contexts/` (dev.md, research.md, review.md) that guide agent verbosity and focus. Configurable via `"context"` field in config.json.
- **File manifest** — `learnship-file-manifest.json` generated after every install with SHA-256 hashes of all installed files. Enables upgrade safety: detects user-modified files and backs them up to `learnship-local-patches/` before overwriting.
- **`package.json` for CJS hooks** — Writes `{"type":"commonjs"}` to the install directory so Node.js `require()` works in hook files.

- **Structured interactive questions** — 14 workflows now use `AskUserQuestion()` blocks for user-facing decisions. install.js automatically maps to platform-native tools: `ask_user_question` (Windsurf), `question` (OpenCode), `ask_user` (Gemini), `request_user_input` (Codex). Text fallback for Cursor and platforms without interactive tools.
  - Workflows: new-project, settings, discuss-phase, challenge, quick, debug, ideate, discuss-milestone, new-milestone, research-phase, secure-phase, validate-phase, list-phase-assumptions, diagnose-issues
- **Agent persona delegation** — 5 additional workflows now spawn dedicated agent personas via `Task()` when parallelization is enabled, with `@./agents/` sequential fallback:
  - `new-project.md` Step 5 — researcher agent for project research
  - `research-phase.md` — researcher agent for phase research
  - `verify-work.md` Step 7 — debugger agent for issue diagnosis
  - `secure-phase.md` Step 5 — security auditor for threat verification
  - `validate-phase.md` Step 7 — verifier agent for test gap filling
  - `ideate.md` — researcher agent for mid-conversation research

### Changed

- **`/new-project` Step 2** — Configuration questions restructured into 3 rounds of structured questions (core settings, workflow agents, pipeline & git) instead of 7 plain-text groups.
- **`/new-project` Step 5** — Research decision now uses structured question with banner.
- **`/settings` Step 3** — Complete rewrite: 21 numbered text options replaced with 3 structured question rounds matching new-project format.
- **`/new-project` Step 5b** — Each research file instruction now says "First, read the template at `@./templates/research-project/X.md`" before writing. Directly addresses the recurring research-file skip bug by giving the AI a structural guide.
- **`install.js`** — New functions: `installClaudeHooks()`, `uninstallClaudeHooks()`, `generateManifest()`, `saveLocalPatches()`. Hook installation is Claude Code + Gemini only — Codex, OpenCode, Windsurf, Cursor paths are untouched.
- **`uninstall()`** — Now cleans up hooks from `settings.json`, removes hook files, manifest, and local patches directory.
- **`config.json` template** — Added `"context": "dev"` field for context profile selection.
- **9 commands** — Added `AskUserQuestion` to `allowed-tools` for discuss-phase, quick, research-phase, validate-phase, secure-phase, verify-work, ideate, list-phase-assumptions, diagnose-issues. Added `Task` to validate-phase.
- **`discuss-phase.md` command** — Fixed execution_context path (`@~/.claude/learnship/` → `@~/.claude/`).
- **`install.js` `replacePaths`** — Now rewrites `AskUserQuestion` to platform-native tool names: `ask_user_question` (Windsurf), `ask_user` (Gemini), `request_user_input` (Codex). OpenCode already handled by `convertToOpencode`.
- **Cursor `.mdc`** — Updated stale "Group D" reference to match Round-based config. Added "Structured Questions" section explaining text fallback.
- **`install.js` `--target` flag** — New `--target <dir>` CLI option overrides the default platform directory for both install and uninstall. Works on all 6 platforms. Useful for CI, Docker, testing, or non-standard config locations.
- **README restructure** — Install section moved to the top (line 33, was line 83). New order: Install → 5 Commands → Phase Loop → How It Works → Platform Support → Philosophy. Platform table collapsed into `<details>`. Inspired by get-shit-done's action-first structure.
- **Image audit** — Regenerated 4 images (`install.png` v2.2.0, `config-schema.png` spacious card layout, `platform-comparison.png` 6 platforms + hooks/questions rows, new `v22-overview.png`). All 24 image references verified, 0 broken.
- **Documentation** — Added v2.2 bullet to `docs/index.md`, context profiles + hooks sections to `docs/configuration.md`, interactive questions row to all 6 platform guide pages, Cursor tab + `--target` section to `docs/getting-started/installation.md`, `platform-comparison.png` to README + docs index.

---

## [v2.1.2] — 2026-04-15

### Fixed

- **`/new-project` research file-write enforcement** — After choosing "Research first," the AI was doing web searches and domain analysis in its head, then saying "I have enough research data" and jumping directly to requirements — without ever writing the 5 research files to disk. Root cause: the word "research" was interpreted as a cognitive action ("think about the domain") rather than a file-writing action ("create 5 files"). Fixed by:
  - Changed banner from `RESEARCHING` → `WRITING RESEARCH FILES`
  - Added forbidden-behaviors block listing the exact failure pattern
  - Added mandatory sequence: mkdir → write 5 files → verify → present → confirm
  - Added per-file stop-and-confirm after File 1
  - Updated SKILL.md and cursor-rules to say "Research = WRITE 5 FILES TO DISK"
  - Added regression entry to AGENTS.md documenting the lesson: "When the AI has a choice between 'think about X' and 'write X to a file,' it will always prefer thinking"

---

## [v2.1.1] — 2026-04-15

### Fixed

- **`/new-project` research output gate** — After research completes, the AI was displaying a 3-bullet summary and immediately jumping to Step 6 (requirements) without presenting research findings. Fixed by replacing the sparse banner with a full structured presentation of all 5 research files (stack, features, architecture, pitfalls) and adding a hard gate requiring explicit user confirmation before requirements can begin.

---

## [v2.1.0] — 2026-04-15

### Added

- **8 new workflows:**
  - `/forensics` — Post-mortem investigation for failed or stuck workflows (read-only diagnostic report)
  - `/undo` — Safe git revert for phase or plan commits (preserves history, dependency checks)
  - `/note` — Zero-friction idea capture (one write, one confirmation line, no questions)
  - `/session-report` — Post-session summary with work performed, outcomes, git activity
  - `/secure-phase` — Per-phase STRIDE security verification with threat register and SECURITY.md
  - `/docs-update` — Documentation generation pipeline (detects project type, builds doc queue, verifies against codebase)
  - `/extract-learnings` — Structured learning extraction from phase artifacts (decisions, lessons, patterns, surprises)
  - `/milestone-summary` — Comprehensive milestone summary for team onboarding
- **5 new references:**
  - `thinking-models.md` — Structured reasoning for planning (Pre-Mortem, MECE, Constraint Analysis, Reversibility, Curse of Knowledge, Base Rate)
  - `universal-anti-patterns.md` — Rules that apply to all workflows and agents (context budget, subagent, questioning, behavioral, error recovery)
  - `context-budget.md` — Context window management with degradation tiers (PEAK/GOOD/DEGRADING/POOR)
  - `gates.md` — Gate taxonomy (pre-flight, revision, escalation, abort) with workflow gate matrix
  - `common-bug-patterns.md` — Stub detection, wiring gaps, state drift patterns for verification
- **3 new templates:**
  - `security.md` — Per-phase security contract (trust boundaries, STRIDE register, accepted risks, audit trail)
  - `ui-spec.md` — UI design contract (design system, spacing scale, typography, color, impeccable checklist)
  - `discussion-log.md` — Audit trail for discuss-phase Q&A sessions (options considered, not just selected)
- **2 new agents:**
  - `learnship-security-auditor` — Spawned by secure-phase for STRIDE threat verification (read-only)
  - `learnship-doc-writer` — Spawned by docs-update for documentation generation
- **Config schema expanded** — New sections: `parallelization` (object with enabled/plan_level/max_concurrent_agents), `gates` (7 confirmation gates), `safety` (destructive/external service guards), `hooks` (context_warnings). New workflow fields: `security_enforcement`, `discuss_mode`, `tdd_mode`. All backward compatible — old configs parse fine.

### Changed

- **`discuss-phase` enhanced** — Downstream awareness section (how CONTEXT.md feeds researcher/planner), scope guardrail with allowed/not-allowed heuristic, discussion-log generation, canonical_refs in output
- **`execute-phase` enhanced** — `--wave N` flag for targeted execution, context window scaling, runtime compatibility awareness (sequential fallback), context degradation reference
- **`plan-phase` enhanced** — TDD mode awareness (`workflow.tdd_mode`), context window scaling for prior phase reads, explicit `--skip-research`/`--skip-verify`/`--research`/`--gaps` flags
- **`verify-work` enhanced** — Goal-backward verification principle (task completion ≠ goal achievement), must-haves extraction from plan frontmatter, stub detection reference
- **`quick` enhanced** — New composable flags: `--research` (focused research before planning), `--validate` (plan-checking + verification). `--full` = `--discuss --research --validate`
- **`ideate` enhanced** — New `--explore` mode for Socratic exploration (one question at a time, mid-conversation research offer, crystallize outputs to notes/todos/decisions/phases). Existing scan mode preserved.
- **`context.md` template overhauled** — New structure with `<domain>`, `<decisions>`, `<specifics>`, `<canonical_refs>`, `<code_context>`, `<deferred>` sections. 2 worked examples (visual feature, CLI tool). Guidelines for downstream agent awareness.
- **SKILL.md updated** — 8 new workflows in Active Workflows table, 2 new agents in Agent Personas, 4 new learning checkpoints, 5 new references
- **`new-project` config questioning updated** — Step 2 now writes the full v2.1.0 config schema (parallelization object, gates, safety, hooks, security_enforcement, discuss_mode, tdd_mode)
- **`settings` menu expanded** — 17 → 21 items (added security enforcement, parallelization with max agents, safety confirm destructive, context warnings). Save logic changed to read-modify-write to preserve fields not in the menu.
- **`help` updated** — 49 → 58 workflow count, new Recovery and Session categories
- **`domain-probes.md` reference added** — Domain-aware probing patterns for 11 domains (auth, real-time, dashboard, API, database, search, file upload, caching, testing, deployment, AI/ML). Referenced from discuss-phase and new-project deep questioning.
- **`planning-config.md` updated** — Full documentation for all v2.1.0 config fields with tables and examples
- **Parallelization default raised** — `max_concurrent_agents` default changed from 3 to 5. 5 is the sweet spot for cost vs. speed — most phases have 2-5 plans per wave.
- **Session-start hook enhanced** — Now injects STATE.md last-session context alongside SKILL.md (bash-only, zero deps, backward compatible)
- **`generate_images.py` updated** — 3 new image prompts: security-workflow, recovery-workflows, v21-overview
- **All plugin manifests at v2.1.0** (Claude Code, Cursor, Gemini)
- **Workflow count: 49 → 57** (published) | Templates: 7 → 11 | References: 9 → 15 | Agents: 10 → 12

---

## [v2.0.11] — 2026-04-15

### Changed

- **Principles consolidated (10 → 10, reworked)** — Three principles absorbed anti-overengineering and surgical-change guidance without adding new ones:
  - **#2** "Minimal Upstream Fix" → **"Minimal Fix, Surgical Change"** — adds "touch only what you must, don't improve adjacent code, every changed line traces to the request"
  - **#7** "One Moving Part" → **"One Thing at a Time, Nothing Extra"** — adds "no speculative features, no single-use abstractions, if 200 lines could be 50 rewrite"
  - **#8** "Code Reads > Code Writes" → **"Understand First, Then Change"** — adds "stop when confused, present multiple interpretations, ask"
- **New Voice & Character bullet** — "Stop when confused, not after" — surface ambiguity immediately, don't silently pick an interpretation

### Fixed

- **Platform-native file creation** — `/new-project` Step 8 now detects existing context files (`AGENTS.md`, `CLAUDE.md`, `GEMINI.md`, `.cursorrules`) and asks the user to Replace/Merge/Keep separate before writing
- **Claude Code CLAUDE.md copy** — `install.js` now generates a `cp AGENTS.md CLAUDE.md` instruction for Claude Code installs. Previously only Gemini CLI got a copy instruction.
- **Platform-native copy sync** — `execute-phase` Step 7b now auto-syncs `AGENTS.md → CLAUDE.md` and `AGENTS.md → GEMINI.md` if those files exist
- **11 new tests** (356 total)
- **learnship's own AGENTS.md** — The repo itself now has a filled-in AGENTS.md with project structure, tech stack, conventions, regressions, and all consolidated principles

---

## [v2.0.10] — 2026-04-12

### Fixed

- **Research decision gate — AI can no longer self-skip research** — Step 5 now has a formatted banner question (RESEARCH DECISION), a forbidden-responses list with exact phrases the AI must not say ("no research needed", "skipping research", etc.), and an exhaustive list of invalid skip reasons (tech stack in PROJECT.md, trivial domain, detailed answers, etc.). Previously the AI would reason "The tech stack is already well-defined in PROJECT.md. No research needed" and skip directly to requirements.
- **SKILL.md (Windsurf) research decision gate** — Added "Research decision = always ask the user" as gate #1 in ceremony enforcement. Windsurf was the platform where the skip was observed.
- **Cursor .mdc research decision gate** — Replaced the soft "ask and wait" gate #2 with explicit anti-skip language matching the new enforcement.
- **4 new tests** — Research decision forbidden-responses, PROJECT.md anti-skip pattern, SKILL.md gate, Cursor .mdc gate. (345 total)

---

## [v2.0.9] — 2026-04-12

### Fixed

- **Research creates 5 separate files, not one monolith** — `/new-project` Step 5 now has explicit per-file instructions ("File 1 of 5 — Write STACK.md now", etc.) with anti-monolith language. Previously the AI would write a single research file instead of the required STACK.md, FEATURES.md, ARCHITECTURE.md, PITFALLS.md, and SUMMARY.md. The `node -e` verification gate now blocks progression unless all 5 files exist with required sections.
- **AGENTS.md generated from template, not improvised** — Step 8 restructured into substeps: 8a (read template — hard gate), 8b (write with numbered section order specifying which sections are VERBATIM vs FILL IN), 8c (verify — now checks both section headers AND verbatim content phrases like "pair programmer", "Friction Is Signal", "decision tree"). Previously the AI would generate AGENTS.md without reading the template, producing files missing the Request Routing Protocol and other critical sections.
- **No auto-execution of Phase 1 after `/new-project`** — Step 9 now has a `HARD STOP` gate explicitly forbidding the AI from starting `/discuss-phase 1`, saying "Let me start Phase 1", or running any phase workflow. The routing suspension is explicitly lifted. Previously the AI would flow directly from the done banner into Phase 1 execution without user input.
- **SKILL.md ceremony enforcement (Windsurf)** — Added `/new-project` Ceremony Enforcement section with the 3 hard gates (5 research files, template-based AGENTS.md, STOP after done). This is Windsurf's primary entry point and previously had no reinforcement of these gates.
- **Cursor .mdc ceremony enforcement** — Added research file gate, AGENTS.md template gate, and Step 9 STOP gate to the critical gates list. Previously only had 4 gates; now has 6.
- **9 new enforcement tests** — Research file individuality, anti-monolith instruction, AGENTS.md substep structure, verbatim content verification, Step 9 HARD STOP, SKILL.md enforcement section, Cursor .mdc gates (research, template, STOP).

---

## [v2.0.8] — 2026-04-12

### Added

- **Research format enforcement** — `/new-project` Step 5 now specifies mandatory `##` section headers for each research file (STACK.md, FEATURES.md, ARCHITECTURE.md, PITFALLS.md, SUMMARY.md) and includes a cross-platform `node -e` post-research verification command that checks all 5 files exist with required sections.
- **Deep Questioning hard gate** — `/new-project` Step 3 now has a hard count-check gate: the AI must verify it sent exactly 4 separate question messages and received 4 separate answers before proceeding. Prevents treating a detailed Exchange 1 answer as satisfying all 4 exchanges.
- **AGENTS.md automated verification** — `/new-project` Step 8 now includes a cross-platform `node -e` verification command that checks the generated AGENTS.md contains all 9 mandatory sections (Soul, Principles, Request Routing Protocol, Platform Context, Current Phase, Project Structure, Tech Stack, Skills, Regressions). Stops and requests regeneration if any section is missing.
- **AGENTS.md update verification** — `/execute-phase` Step 7b now verifies mandatory AGENTS.md sections survive the update, using the same cross-platform `node -e` check.
- **`/ls` new user routing** — WELCOME banner now suggests `@agentic-learning brainstorm` for users who don't know what to build, and `/ideate` for users with an existing codebase.
- **`/next` new user routing** — MISSING state now shows `/new-project`, brainstorm, and `/ideate` options instead of auto-running `/new-project`.
- **`/quick` done banner** — Now suggests `/compound` (capture solutions) and `/ship` (push pipeline).
- **`/discuss-phase` done banner** — Now suggests `/challenge` (stress-test ambitious scope) and `/compound` (capture important decisions).
- **`/audit-milestone` done banner** — Now suggests `/sync-docs` before release in both PASSED and GAPS FOUND states.
- **AGENTS.md template `/compound` enforcement** — Solutions Store section now has an explicit list of events after which `/compound` must be run (bug fixes, phase completions, shipping, debugging, aha moments).
- **Harness enforcement tests** — 20 new tests in `validate_multiplatform.sh` covering: research format spec, post-research verification, Deep Questioning count gate, AGENTS.md verification in new-project and execute-phase, `/compound` in all 7 canonical done banners, brainstorm/ideate in `/ls` and `/next`, `/sync-docs` in audit-milestone, `/challenge` in discuss-phase, `/ship` in quick, AGENTS.md template enforcement language, and cross-platform `node -e` verification.

---

## [v2.0.7] — 2026-04-08

### Fixed

- **Marketplace auto-sync** — `publish.yml` now dynamically counts workflows, agent personas, and impeccable commands from the source repo and pushes both an updated `marketplace.json` (version + description) and a regenerated `README.md` to `learnship-marketplace`. Previously only the version field was bumped, leaving workflow/agent counts stale (was "42 workflows, 6 agents, 18 commands" → now correctly "49 workflows, 10 agents, 21 commands").
- **Immediate marketplace fix** — Pushed correct counts to `learnship-marketplace` repo (marketplace.json + README.md) without waiting for the next tag.

---

## [v2.0.6] — 2026-04-08

### Fixed

- **`/ideate` sequencing** — Removed incorrect "Run before `/new-project`" claim. `/ideate` requires an existing project with `AGENTS.md` and `.planning/` to ground its codebase scan. Added pre-flight check (Step 1) that stops with a helpful message if no project exists, directing users to `@agentic-learning brainstorm` for pre-project ideation instead. Updated "Route to Action" (Step 8) to offer "Start a new milestone" instead of "Start a new project."
- **`/ideate` documentation** — Updated "When to use" in `docs/workflow-reference/compounding-quality.md` to clarify project requirement and point to `@agentic-learning brainstorm` as the pre-project alternative.
- **`/complete-milestone` done banner** — Added `/ideate` and `/challenge` suggestions. This is the most natural moment to suggest between-milestone workflows, and it was the only milestone lifecycle workflow that didn't route to them.

---

## [v2.0.5] — 2026-04-08

### Fixed

- **`docs/getting-started/first-project.md`** — Complete rewrite: now covers the full `/new-project` experience including configuration questions, research decision (always user's choice), AGENTS.md structure (Soul, Principles, Platform Context explained), and the full 7-step phase loop with dedicated sections for `/review` (Step 10), `/ship` (Step 11), and `/compound` (Step 12). Shows `config.json` with 22 keys, `.planning/solutions/` directory, and milestone closure flow.
- **`docs/getting-started/five-commands.md`** — Session pattern updated to show full 7-step loop including review, ship, compound.
- **`docs/index.md`** — "Your First Project" card description updated to reference the full loop.
- **`docs/workflow-reference/compounding-quality.md`** — Removed "optional but recommended" framing; now says "recommended after every phase."
- **`docs/examples/greenfield.md`** — Expanded Session 6 with realistic `/review` findings (P1/P2/P3), `/ship` output, and `/compound` examples. Added "What's next?" section with `/ideate`, `/challenge` for post-milestone flow. Expanded key patterns to include `/review`→`/ship`→`/compound`, `/guard`.
- **`docs/examples/brownfield.md`** — Added "Safety mode for sensitive areas" section explaining `/guard` with example. Added `/guard` row to greenfield vs brownfield comparison table.
- **`docs/core-concepts/planning-artifacts.md`** — Added `guard-state.md` and ideation artifacts to the `.planning/` directory tree.
- **`learnship/workflows/new-project.md`** — Added `/challenge` and `/guard` suggestions to the done banner.
- **`learnship/workflows/new-milestone.md`** — Added `/ideate`, `/challenge`, and `/guard` suggestions to the done banner.
- **`generate_images.py`** — Added `new_project_flow` image prompt (5-step flow: Questions → Research → Requirements → Roadmap → AGENTS.md). Updated `config_schema` prompt to include `commit_mode` and `validation` keys. Updated `extended_phase_loop` title from "optional" to "7-Step Phase Loop."
- **New image: `assets/new-project-flow.png`** — Generated diagram showing the full `/new-project` initialization flow.
- **Regenerated: `assets/config-schema.png`** — Now includes all 22 config keys.
- **Regenerated: `assets/extended-phase-loop.png`** — Updated title and framing.
- **`docs/contributing.md`** — Removed entire "Generating brand images" section (internal-only tool). Removed `generate_images.py` from the repository structure tree. Added `learnship/agents/` and `learnship/skills/` to the repo structure. Fixed test count from "146+" to "313+".

---

## [v2.0.4] — 2026-04-08

### Fixed

- **`/new-project` AGENTS.md generation** — Step 8 now explicitly lists which template sections must be copied verbatim (Soul, Principles, Platform Context, Skills, Regressions) vs which are fill-in (Title, Current Phase, Project Structure, Tech Stack). Includes a 9-point verification checklist to prevent agents from free-styling the file. Project-specific sections (Conventions, etc.) are allowed but only in the designated slot.
- **`/new-project` research decision** — Added 🔴 MANDATORY USER CHOICE gate. The agent is now explicitly forbidden from auto-deciding whether to research, even if the domain seems familiar. The user always decides.
- **`/new-milestone` research decision** — Same mandatory user choice gate and 🛑 STOP added to prevent agents from skipping the research question.

---

## [v2.0.3] — 2026-04-08

### Fixed

- **`docs/configuration.md`** — Added missing `planning.commit_mode` key to schema and documentation section.
- **`README.md`** — Added `planning.commit_mode`, `parallelization`, `test_first` to Core Settings table. Removed duplicate `test_first` from v2.0 Settings. Updated phase loop framing from "core 4 + 3 optional" to "7-step loop".
- **`docs/index.md`** — Workflow Engine card shows full 7-step loop instead of 4-step.
- **`docs/workflow-reference/core.md`** — "core 4-step loop" comment replaced with "7-step loop".
- **`docs/core-concepts/phase-loop.md`** — Description and framing updated to 7-step loop as the standard.

---

## [v2.0.2] — 2026-04-08

### Fixed

- **`/new-project` config completeness** — Now asks about model profile, test-first mode, review workflow, solutions search, ship pipeline, and auto-review. Writes all 22 config keys instead of 9. Done banner shows full 7-step phase loop.
- **`/settings` menu completeness** — Fallback config includes all v2 keys. Menu expanded from 10 to 17 items covering test-first, review, solutions search, auto-review, and ship pipeline options. Save template writes full config schema.
- **`/verify-work` auto-review** — Now reads `review.auto_after_verify` from config. If true, auto-triggers `/review` after UAT passes. If false, shows recommended next steps including `/review`, `/ship`, and `/compound`.
- **`/new-milestone` config upgrade** — New Step 6b detects missing v2 config keys and offers to merge defaults for projects started before v2.
- **`/health` config check** — Expanded from 4 top-level keys to all v2 keys including nested `workflow.review`, `workflow.solutions_search`, `review.auto_after_verify`, `ship.*`, `planning.commit_mode`.
- **`AGENTS.md` template** — Phase loop updated from 4-step to full 7-step: discuss → plan → execute → verify → review → ship → compound.
- **`/new-milestone` done banner** — Shows full 7-step phase loop instead of truncated 3-step.

---

## [v2.0.1] — 2026-04-08

### Changed

- **Credits & Inspiration** — Added compound-engineering, superpowers, and gstack to credits in README and docs/contributing.md. Updated get-shit-done URL to current org.

---

## [v2.0.0] — The Compounding Harness

**Released:** 2026-04-08

### Added

- **`/compound` workflow** — Capture a recently solved problem or learned pattern while context is fresh. Creates structured documentation in `.planning/solutions/` with YAML frontmatter for searchability. Full mode (parallel research, overlap detection, dedup) and lightweight mode (single pass, fewer tokens). Integrates with `@agentic-learning` for spaced review.

- **`/review` workflow** — Multi-persona code review through six lenses: correctness, testing, security, performance, maintainability, and adversarial. Produces severity-ranked (P0-P3) findings with confidence scores (0.0-1.0). Three modes: interactive (default), report-only, autofix. Conditional persona selection based on diff content.

- **`/challenge` workflow** — Product and engineering challenge gate. Asks forcing questions through two lenses to determine whether a proposal is worth building before investing in planning. Verdicts: proceed, rethink, or reduce scope. Records decisions to DECISIONS.md.

- **`/ship` workflow** — End-to-end ship pipeline: detect test runner → run tests → lint → stage → conventional commit → push → create PR with auto-description. Closes the loop from verified code to production-ready PR.

- **`/ideate` workflow** — Codebase-grounded divergent ideation. Scans for TODOs, test gaps, hotspots, and friction points. Generates 15-25 ideas across four thinking frames (user pain, inversion, assumption-breaking, leverage). Adversarial filter eliminates weak ideas, presents top 5-7 ranked survivors.

- **`/guard` workflow** — Safety mode for sensitive phases. Warns before destructive commands, locks file scope to prevent accidental changes outside the working area. Persists guard state across sessions via `.planning/guard-state.md`.

- **`/sync-docs` workflow** — Scans documentation against recent code changes to detect stale sections, outdated references, and drift. Auto-fixes simple cases (renamed references, updated paths), flags complex ones for manual review.

- **`solution-writer` agent** (inline + dispatch) — Analyzes solved problems, classifies by track (bug vs knowledge) and category, writes structured solution documents with YAML frontmatter. Performs overlap detection across five dimensions.

- **`code-reviewer` agent** (inline + dispatch) — Reviews code through persona-specific lenses. Returns structured findings with severity and confidence. Read-only — does not edit files.

- **`challenger` agent** (inline + dispatch) — Stress-tests proposals through product and engineering forcing questions. Returns verdicts with evidence-based rationale.

- **`ideation-agent`** (inline + dispatch) — Generates codebase-grounded improvement ideas through assigned thinking frames. Pushes past obvious first ideas.

- **`solution-schema.md` reference** — YAML frontmatter schema for `.planning/solutions/`, including tracks, required fields, category mapping, and templates.

- **TDD mode** — Opt-in via `"test_first": true` in config. Executors (both inline and dispatch) use red-green-refactor cycle: write failing test → verify red → write minimum code → verify green → refactor → commit.

### Changed

- **Phase loop extended** — `discuss-phase` → `plan-phase` → `execute-phase` → `verify-work` → `/review` → `/ship` → `/compound`

- **`plan-phase` Step 2b** — New step: search `.planning/solutions/` for prior art before research. Surfaces relevant past solutions to avoid reinventing known approaches.

- **`debug` Step 9** — Now suggests `/compound` after resolving a fix to capture the problem, root cause, and solution while context is fresh.

- **`verify-work` Step 6** — Suggests `/compound` after successful UAT to capture notable patterns from the phase.

- **`knowledge-base` Step 2** — Now reads `.planning/solutions/` as an additional source. Step 3 extracts knowledge items from compounded solutions (bug track → lesson, knowledge track → pattern/anti-pattern).

- **`milestone-retrospective` Step 2b** — New quantitative summary section with metrics: phases completed, total commits, LOC changed, test file ratio, debug sessions, duration.

- **`execute-phase` Step 2c** — TDD mode check and banner when `test_first` is `true`.

- **AGENTS.md template** — Platform Context updated with solutions store reference and extended phase loop. Skills section includes Solutions Store with `/compound` and `/plan-phase` search integration.

- **`planning-config.md`** — Added v2.0.0 configuration options documentation: `test_first`, `workflow.review`, `workflow.solutions_search`, `review.auto_after_verify`, `ship.auto_test`, `ship.conventional_commits`, `ship.pr_template`.

- **`model-profiles.md`** — Added 4 new agent rows: solution-writer (sonnet/sonnet/haiku), code-reviewer (opus/sonnet/sonnet), challenger (opus/sonnet/sonnet), ideation-agent (opus/sonnet/haiku).

- **`help.md`** — Added "Compounding & Quality" section with all 7 new workflows. Updated workflow count to 49.

- **`gen-commands.js`** — Added 7 new workflow entries to WORKFLOWS array. Updated comment to 49 workflows.

- **`bin/install.js` CODEX_AGENT_SANDBOX** — Added 4 new agents: solution-writer (workspace-write), code-reviewer (read-only), challenger (read-only), ideation-agent (read-only).

### Tests

- **`validate_workflows.sh`** — Minimum workflow count raised from 32 to 39. Added 7 required workflows: compound, review, challenge, ship, ideate, guard, sync-docs.
- **`validate_multiplatform.sh`** — Expected command wrapper count raised from 42 to 49. Expected workflow file count raised from 42 to 49. Required agents list expanded to include 4 new dispatch agents. Inline persona check expanded to 9 personas.

---

## [v1.9.24] — Docs, images, and repo URL corrections

**Released:** 2026-03-27

### Fixed

- **Upstream repo URL corrected: `agentic-learn` → `agentic-learning`** — All references to `FavioVazquez/agentic-learn` updated to the correct `FavioVazquez/agentic-learning` across `sync-upstream-skills.md` (both copies), `README.md`, `CHANGELOG.md`, `docs/contributing.md`, `docs/skills/agentic-learning.md`, `docs/workflow-reference/maintenance.md`, and `tests/validate_multiplatform.sh`.

- **Claude Code skills path in sync workflow** — `sync-upstream-skills.md` Step 8 and Step 10 summary referenced the old `~/.claude/plugins/learnship/` path; corrected to `~/.claude/skills/`.

- **`docs/index.md` platform badge** — Badge read `platforms-5`; corrected to `platforms-6` (Windsurf, Claude Code, Cursor, OpenCode, Gemini CLI, Codex CLI).

- **`docs/skills/agentic-learning.md` platform table** — Claude Code was grouped with "context file" platforms; now has its own row reflecting native skill installation at `~/.claude/skills/` with `/agentic-learning [action]` invocation.

- **`docs/platform-guide/claude-code.md`** — Updated Skills section to reflect native `~/.claude/skills/` installation and `/agentic-learning` slash command syntax.

### Updated

- **6 brand images regenerated** — Stale images updated to reflect Claude Code native skill support and corrected details:
  - `install.png` — version `v1.9.0` → `v1.9.23`
  - `skills-overview.png` — 2-column → 3-column layout separating Claude Code (native `/slash`) from Windsurf (native `@invoke`) and context-file platforms
  - `platform-comparison.png` — Claude Code Skills cell: `context file` → `native skill`
  - `agentic-learning-actions.png` — title and rows use platform-neutral `agentic-learning` instead of Windsurf-specific `@agentic-learning`
  - `impeccable-commands.png` — footer updated: Claude Code now listed alongside Windsurf as native skill platform
  - `how-it-works.png` — Design System column: `18 steering commands` → `21 steering commands`

- **`generate_images.py` prompts** — Updated all 6 stale prompts to match the above corrections. Python environment setup added (`requirements.txt`, `.venv/`) with both gitignored.

---

## [v1.9.23] — Fix skills not installed to ~/.claude/skills/ for Claude Code

**Released:** 2026-03-27

### Fixed

- **`agentic-learning` and `impeccable` not available as native Claude Code skills** — The installer (`installClaudePlugins`) was writing skills to `~/.claude/plugins/learnship/skills/`, which is not a location Claude Code reads for user skills. Claude Code only discovers user skills from `~/.claude/skills/<skillname>/SKILL.md`. Skills were on disk but invisible to Claude Code's skill system.

  **Fix:** Renamed `installClaudePlugins` → `installClaudeSkills` and changed the target from `plugins/learnship/skills/` to `skills/` (i.e. `~/.claude/skills/<skillname>/`). Both `agentic-learning` and `impeccable` now install correctly and appear immediately in Claude Code's available skill list.

- **`@mention` invocation hints in skill descriptions** — The `description` field in `agentic-learning/SKILL.md` ended with "Invoke with @agentic-learning followed by one of: ..." and the generated `impeccable/SKILL.md` description said "Invoke with @impeccable followed by one of: ...". `@mention` is Windsurf-native syntax and does nothing in Claude Code. Claude Code discovers skills by matching the description against user intent — the `@mention` line was noise and could confuse the matcher.

  **Fix:** The `@mention` invocation hint is stripped from `agentic-learning`'s description during Claude Code install. The generated `impeccable` description now ends with "Actions: adapt, animate, ..." instead of "Invoke with @impeccable followed by one of: ...".

- **Legacy `plugins/learnship/` directory not cleaned up on reinstall** — Old installs left `~/.claude/plugins/learnship/` in place (it was never read by Claude Code). The new installer removes it during install and uninstall for backward compatibility.

- **AGENTS.md skills block updated for Claude Code** — The `<!-- LEARNSHIP_SKILLS_BLOCK -->` block generated by `rewriteAgentsMd()` for Claude Code now correctly states that skills are natively available at `~/.claude/skills/` and can be invoked via the Skill tool, while keeping the fallback instruction to read from `learnship/skills/`.

- **Uninstall now removes `skills/agentic-learning/` and `skills/impeccable/`** as well as the legacy `plugins/learnship/` directory if present.

---

## [v1.9.22] — Windows/PowerShell compatibility: replace python3 and bash-only commands

**Released:** 2026-03-25

### Fixed

- **`python3` removed from all workflows** — Every `python3 -c "import os; ..."` file-existence check replaced with `node -e "require('fs').existsSync(...)"` — Node.js is a guaranteed dependency on all platforms; `python3` is not present on Windows by default. Affected: `health`, `new-project`, `quick`, `resume-work`, `progress`, `next`, `ls`, `settings`, `set-profile`, `validate-phase`, `research-phase`, `remove-phase`, `insert-phase`, `add-phase`, `discuss-milestone`, `plan-milestone-gaps`, `references/planning-config.md` (~32 occurrences).
- **`mkdir -p` removed from all workflows** — Replaced with `node -e "require('fs').mkdirSync('...', {recursive:true})"` — `mkdir -p` is not available in PowerShell. Affected: `add-todo`, `debug`, `complete-milestone`, `discuss-phase`, `plan-phase`, `insert-phase`, `map-codebase`, `cleanup`, `plan-milestone-gaps`, `sync-upstream-skills`, `update` (13 occurrences).
- **`xargs ls -t | head -N` removed** — Replaced with `node -e` sort-by-mtime equivalent — `xargs` is not available in PowerShell. Affected: `ls`, `progress`, `pause-work`, `transition` (4 occurrences).
- **`head -N` / `tail -N`** — Inline PowerShell comments added: `# PowerShell: ... | Select-Object -First N / -Last N`. Affected: 25+ occurrences across 15 workflows.
- **`sort -V`** — PowerShell equivalents added as inline comments (`Sort-Object Name`). Affected: `add-phase`, `new-milestone`, `discuss-milestone`, `milestone-retrospective`, `complete-milestone`, `plan-milestone-gaps`.
- **`2>/dev/null`** — Inline `# PS: 2>$null` comments added where relevant.
- **`python3` in `release.md`** — JSON escaping for GitHub API now uses `node -e` instead of `python3`.
- **`grep -rl | head`** — PowerShell `Select-String` equivalents added as inline comments in `discovery-phase`, `audit-milestone`, `agents/debugger`.
- **`npm test 2>&1 | tail -5`** — PowerShell equivalent added as inline comment in `agents/verifier`.

### Changed

- All `learnship/workflows/` mirror copies synced with `.windsurf/workflows/` changes.
- `learnship/agents/` mirror copies synced with `agents/` changes.
- `references/planning-config.md` and its mirror updated.

---

## [v1.9.21] — Fix new-project ceremony: research skipped, AGENTS.md skipped, wrong next step

**Released:** 2026-03-24

### Fixed

- **Research step (Step 5) bypassed after PROJECT.md approval** — The AI treated Step 4 → Step 5 as a narrative flow-through rather than a mandatory gate. It would write REQUIREMENTS.md and ROADMAP.md immediately after PROJECT.md was confirmed, skipping the research question entirely. Root cause: no hard STOP gate existed *between* steps, only *within* them.

- **AGENTS.md (Step 8) skipped after roadmap approval** — The roadmap approval in Step 7 created a natural "ceremony complete" feeling. With `commit_mode: auto`, the git commit further reinforced this. The AI would display the Step 9 done banner and suggest next steps without ever running Step 8. The `🔴 MANDATORY` notice existed but had nothing to anchor it structurally between Step 7 and Step 9.

- **Step 9 recommended `/plan-phase` instead of `/discuss-phase`** — The closing message was paraphrased as "Ready to start Phase 1? Run /plan-phase or /execute-phase" — dropping `discuss-phase` entirely. `discuss-phase` is mandatory before `plan-phase` as it writes `CONTEXT.md` that planning depends on.

  **Fixes:**
  - `new-project.md`: Added **9-step mandatory checklist** at the top of the workflow — the AI must check off each step before proceeding. Prevents silent skipping.
  - `new-project.md` after Step 4 commit: Added hard `🛑 STOP — Step 4 complete. You MUST now ask the research question (Step 5) before writing any other file.`
  - `new-project.md` Step 5: Rewrote the research question to be direct — "Before I write the requirements — do you want me to research the domain ecosystem first?" with explicit gate: "Do not write REQUIREMENTS.md yet."
  - `new-project.md` after Step 7 commit: Added hard `🛑 STOP — Step 7 complete. You MUST now generate AGENTS.md (Step 8) before anything else. Do not display the done banner.`
  - `new-project.md` Step 9: Locked next step to `▶ Next: /discuss-phase 1 — start here, not /plan-phase` with explicit explanation of the phase loop.
  - `.windsurf/workflows/new-project.md`: Regenerated from source with all fixes applied.
  - `tests/validate_multiplatform.sh`: Updated Step 4→5 gate test pattern; added 3 new tests (Step 7→8 gate, discuss-phase next, mandatory checklist).

---

## [v1.9.20] — Fix ceremony bypass when user sends task without running /new-project first

**Released:** 2026-03-23

### Fixed

- **Cascade solves tasks directly when user never ran `/new-project`** — The ceremony bypass reported in v1.9.19 had a deeper root cause that the previous fix didn't address. The user's friend opened Windsurf on an existing codebase and typed a bug fix request directly — never invoking `/new-project` at all. Since `AGENTS.md` doesn't exist yet (it's created by `/new-project`), the routing protocol in `AGENTS.md` never loaded. Cascade saw a codebase, a task, and no learnship gate — and solved the bug directly.

  **Root cause:** `SKILL.md` (the global Windsurf skill loaded in every session) only *suggested* `/new-project` when relevant — it had no hard gate blocking task implementation when `.planning/PROJECT.md` didn't exist. The routing protocol only lived in `AGENTS.md`, which requires `/new-project` to have already run.

  **Fixes:**
  - `SKILL.md`: Added **"Mandatory Gate — No Project, No Work"** section. Before responding to any message, check if `.planning/PROJECT.md` exists. If not: block the task, tell the user to run `/new-project` first, and stop. Explicitly: "Do not offer to help with the task. Do not say 'but I can also just fix it directly.'"
  - `.windsurf/workflows/new-project.md`: Regenerated from source — was missing all three v1.9.19 fixes (routing protocol suspension notice, `HAS_CODE` codebase detection, Step 1b codebase scan, Exchange 1 detailed-answer warning). The Windsurf pre-generated copy had never been updated after v1.9.19 merged.

---

## [v1.9.19] — Fix new-project ceremony bypass on existing codebases

**Released:** 2026-03-23

### Fixed

- **`/new-project` ceremony bypassed when user gives a detailed answer to "What do you want to build?"** — Three compounding bugs caused the full questioning → requirements → roadmap ceremony to be skipped:

  1. **Routing protocol intercepted Exchange 1 answers.** The `AGENTS.md` routing protocol fires on every user message. When the user pastes a detailed prompt in answer to "What do you want to build?", the AI pattern-matched it as a task/feature request and either re-routed to a workflow or started implementing directly — bypassing all subsequent exchanges.

  2. **Detailed ANSWER_1 was treated as sufficient to skip Exchanges 2–4.** The Exchange 1 `🛑 STOP` gate only said "wait for the answer" — it didn't explicitly forbid treating a thorough answer as a full replacement for the three follow-up exchanges. AI models infer: detailed answer → enough context → proceed to Step 4.

  3. **No existing codebase detection.** With real code already in the directory, the AI had visible context from IDE/tool reads and felt the ceremony was redundant — skipping straight to implementation.

  **Fixes:**
  - `learnship/workflows/new-project.md` Step 1: Added explicit **"Routing protocol suspended"** notice — every user message during `/new-project` is a workflow answer, not a routable task.
  - `learnship/workflows/new-project.md` Step 1: Added **existing codebase detection** (`HAS_CODE` check). If files exist, sets `EXISTING_CODEBASE = true` with an explicit guard: "Do NOT use existing code as an excuse to skip or shorten the questioning ceremony."
  - `learnship/workflows/new-project.md` Step 1b: New **codebase scan step** — runs `find` to map structure, used only to sharpen follow-up questions, never to infer intent.
  - `learnship/workflows/new-project.md` Exchange 1: Added `⚠️` warning: "A detailed answer to Exchange 1 does NOT satisfy Exchanges 2–4. No matter how thorough — it is raw material for follow-ups, not a replacement for them."
  - `learnship/templates/agents.md` routing protocol: Added **Step 0** — explicit check: "If `/new-project` is currently in progress, the user's message is an answer to a workflow question. Do NOT apply the routing protocol."
  - `learnship/templates/agents.md` examples: Added counter-example: "`/new-project` asked 'What do you want to build?' and user replies with a detailed description → ❌ Don't treat as a task to route → ✅ It is ANSWER_1. Record it and ask Exchange 2."

---

## [v1.9.18] — Fix @agentic-learning and @impeccable not working on non-Windsurf platforms

**Released:** 2026-03-20

### Fixed

- **`@agentic-learning` and `@impeccable` fail on all non-Windsurf platforms** — `@mention` skill dispatch is a Windsurf-native mechanism. On Claude Code, Gemini CLI, OpenCode, Codex, and Cursor, typing `@agentic-learning either-or` does nothing — the AI gets no context and either errors with "isn't installed" or silently ignores the invocation. The skills ARE installed on disk but the AI has no mechanism to auto-load them from an `@mention`.

  **Root cause:** The `AGENTS.md` template had a `## Skills` section that contained only project-level notes (CHANGELOG discipline, Decisions Register) but no instructions about where skill files live or what to do with `@skill-name` syntax on non-Windsurf platforms.

  **Fix:** Added a `<!-- LEARNSHIP_SKILLS_BLOCK -->` marker to `learnship/templates/agents.md`, replaced at install time by `rewriteAgentsMd()` with platform-specific instructions:
  - **Windsurf:** "Windsurf loads `@agentic-learning` natively — invoke as normal."
  - **Claude Code / Gemini / OpenCode / Codex:** "There is no native @mention dispatch. When `@agentic-learning <action>` is mentioned, read `[path]/skills/agentic-learning/SKILL.md`, find the action section, and execute those instructions directly. Do NOT say it isn't installed."
  - **Cursor:** Added the same explicit instructions to `cursor-rules/learnship.mdc` (Cursor doesn't go through `install.js`).

  Every new project's `AGENTS.md` (generated from the template during `/new-project`) now contains the correct skill invocation instructions for the platform it was installed on. The AI reads `AGENTS.md` at the start of every session, so the instructions are always present.

---

## [v1.9.17] — Fix parallelization question missing on all platforms

**Released:** 2026-03-20

### Fixed

- **Parallelization question never shown during `/new-project`** — The `<!-- LEARNSHIP_PARALLEL_BLOCK -->` marker in `new-project.md` was correctly replaced by `rewriteNewProject()` for Claude, OpenCode, Gemini, and Codex (all go through `copyDir`). But the Windsurf workflow copy loop used `fs.copyFileSync` — a raw file copy that bypasses all rewriting. The result: every platform installed with the raw HTML comment left in place, the AI ignored it, and `parallelization` silently defaulted to `false` for all platforms. Fixed by switching the Windsurf loop to read → `replacePaths` → `rewriteNewProject` → write, matching what `copyDir` does for every other platform.

---

## [v1.9.16] — Fix stale Claude Code content + remove dead agent files

**Released:** 2026-03-20

### Fixed

- **Claude Code shows "Windsurf-native" text after reinstall** — Pre-1.9.0 installs created `~/.claude/workflows/` (flat). Since 1.9.0, workflows live at `~/.claude/learnship/workflows/`. The old directory was never removed, so Claude Code commands referenced the stale file via `@~/.claude/learnship/workflows/ls.md` but the pre-1.9.0 `~/.claude/workflows/ls.md` was still there and being read first. Added explicit cleanup: `install.js` now removes `~/.claude/workflows/` on every Claude install if it exists.

- **`@./agents/` broken on Claude Code, Gemini, OpenCode, Codex** — Every ceremony workflow (`plan-phase`, `execute-phase`, `verify-work`, `debug`, `quick`, etc.) uses `@./agents/researcher.md` etc. as inline personas. `@./` resolves relative to the workflow file's directory (`learnship/workflows/`). Agents were installed at `learnship/agents/` — one level up, so `@./agents/` resolved to `learnship/workflows/agents/` which didn't exist. Fixed: `install.js` now copies `learnship/agents/` into `learnship/workflows/agents/` for all non-Windsurf platforms immediately after the main `learnship/` payload install. (Windsurf was already correct — it copies agents into `.windsurf/workflows/agents/`.)

- **Dead short-name agent files in `agents/` cluttering the install** — Five files (`agents/debugger.md`, `executor.md`, `planner.md`, `researcher.md`, `verifier.md`) existed in the repo root `agents/` directory with no YAML frontmatter. `installAgents()` only copies `learnship-*.md` prefixed files, so these were never installed to any platform. They caused confusion in Claude Code's file browser (appearing alongside the real `learnship-*.md` subagent dispatch files). Removed all five.

- **`test -f FILE` fails on Windows/PowerShell** — 18 workflows used POSIX `test -f`/`test -d` shell commands for file existence checks. On Windows (Windsurf on Windows, Cursor on Windows), the agent has no bash available and PowerShell doesn't recognize `test`. Replaced all simple existence checks with `python3 -c "import os; print(...)"` one-liners which work on Windows, macOS, and Linux. Complex bash blocks that use shell variables or loops (`health.md` internals, `update.md`, `sync-upstream-skills.md`) were left unchanged since they are Windsurf/bash-native internal tools.

### How the two `agents/` paths work (for reference)

| Path | Files | Purpose | Installed to |
|------|-------|---------|-------------|
| `agents/learnship-*.md` | `learnship-debugger.md`, `learnship-executor.md`, etc. | Subagent dispatch — YAML frontmatter, used when `parallelization: true` | `~/.claude/agents/learnship-*.md` |
| `learnship/agents/` | `debugger.md`, `executor.md`, etc. | Inline personas — loaded via `@./agents/X.md` in sequential ceremony mode | `~/.claude/learnship/agents/` (Claude), `.windsurf/workflows/agents/` (Windsurf) |

These are different things at different paths. No duplication.

### Tests added (5 new, 273 total)

- `install.js Claude block removes legacy workflows/ dir`
- `agents/debugger.md removed` (dead file)
- `agents/executor.md removed` (dead file)
- `agents/planner.md removed` (dead file)
- `agents/researcher.md removed` (dead file)
- `agents/verifier.md removed` (dead file)

---

## [v1.9.15] — Add inline agent personas — fix broken @./agents/ references in all ceremony workflows

**Released:** 2026-03-19

### Added

- **`learnship/agents/` directory with 5 inline persona files** — `researcher.md`, `planner.md`, `executor.md`, `verifier.md`, `debugger.md`. These are the sequential-mode personas that ceremony workflows invoke on non-subagent platforms (Windsurf, Gemini CLI, Cursor) via `@./agents/`. Previously this directory did not exist, causing all `@./agents/` references to silently fail.

### Fixed

- **`@./agents/` references silently failing on Windsurf** — `install.js` copied `templates/` and `references/` subdirs into `.windsurf/workflows/` so those `@./` references resolved, but `agents/` was not copied. Added `'agents'` to the Windsurf subdir copy loop — `learnship/agents/` now installs to `.windsurf/workflows/agents/` alongside templates and references.
- **Filename mismatch** — Ceremony workflows referenced `@./agents/researcher.md`, `@./agents/planner.md`, etc. The subagent-dispatch files live at `agents/learnship-phase-researcher.md` etc. (different names, different purpose). The new `learnship/agents/` files use the exact names the workflows reference.
- **`quick.md` Step 2 blocked on `ROADMAP.md` instead of `PROJECT.md`** — The `AGENTS.md` routing protocol routes small tasks to `/quick`, but `/quick` stopped if `ROADMAP.md` was missing. Fixed: check for `PROJECT.md` (the real project existence marker). If `PROJECT.md` exists but `ROADMAP.md` is absent, continue with a note in SUMMARY.md.

### Affected ceremonies (all now have working inline personas on all platforms)

- `plan-phase` — researcher + planner + verifier personas
- `execute-phase` — executor + verifier personas
- `execute-plan` — executor persona
- `verify-work` — debugger + planner + verifier personas
- `debug` — debugger + executor personas
- `quick` — planner + verifier + executor personas
- `audit-milestone` — verifier persona
- `research-phase` — researcher persona
- `map-codebase` — researcher persona
- `new-project` — planner persona
- `new-milestone` — researcher + planner personas
- `diagnose-issues` — debugger persona

### Tests added (7 new, 246 total)

- `learnship/agents/ directory exists`
- `learnship/agents/researcher.md exists`
- `learnship/agents/planner.md exists`
- `learnship/agents/executor.md exists`
- `learnship/agents/verifier.md exists`
- `learnship/agents/debugger.md exists`
- `install.js Windsurf block copies agents/ subdir`

---

## [v1.9.14] — Add Request Routing Protocol to AGENTS.md — prevent ceremony bypass on existing projects

**Released:** 2026-03-19

### Fixed

- **AI bypasses learnship ceremony on existing projects when user gives a specific prompt** — On an existing project (`.planning/PROJECT.md` exists), if a user typed a detailed task description, the AI would treat it as a direct coding request and implement the change immediately, skipping `/quick`, `discuss-phase`, `plan-phase`, and all planning ceremony. Root cause: `AGENTS.md` described learnship but had no intercept rule preventing direct execution.
  - **Fix:** Added **Request Routing Protocol** section to `learnship/templates/agents.md` — a mandatory decision tree that fires before the AI responds to ANY user message:
    1. Check if `.planning/PROJECT.md` exists — if not, stop and redirect to `/new-project`
    2. Classify the message — task/bug/feature → route; pure question/discussion → answer normally
    3. Size-based routing — small tasks → propose `/quick` + wait for yes; medium/uncertain → propose `discuss-phase` + wait; large/cross-cutting → run `/ls` first, then recommend
    4. **Never self-route silently** — always name the workflow and reason, then wait for explicit confirmation before invoking
  - Examples of prohibited behavior now documented inline: fixing a bug directly, starting dark mode from a prompt, treating a pasted spec as an execution command
- **4 new tests** in `tests/validate_multiplatform.sh`:
  - `AGENTS.md template has Request Routing Protocol section`
  - `AGENTS.md routing protocol forbids direct code changes`
  - `AGENTS.md routing protocol requires explicit user confirmation before invoking workflow`
  - `AGENTS.md routing protocol has decision tree with quick/discuss-phase routes`

---

## [v1.9.13] — Structurally enforce new-project questioning ceremony (take 2)

**Released:** 2026-03-19

### Fixed

- **`new-project` still skipping ceremony after v1.9.12** — The `⚠ MANDATORY MINIMUM` advisory warning was insufficient; LLMs rationalize past advisory text when a user's first reply is specific. Root cause was structural: the questioning loop had no hard sequential checkpoints, only a soft "when you have enough" heuristic.
  - **Step 3 complete rewrite:** Replaced the open-ended questioning loop with 4 mandatory numbered exchanges (`Exchange 1` through `Exchange 4`), each followed by a `🛑 STOP. Wait for the user's answer.` and a named answer register (`ANSWER_1`…`ANSWER_4`). The AI cannot reach Step 4 without having explicitly received and recorded all four answers. Gate check added: verifies all four `ANSWER_N` are recorded before offering to write `PROJECT.md`.
  - **Step 4 confirmation gate hardened:** Wording changed to exactly match what a `grep` test can verify — `"Reply **yes** to continue"` — and a second `🛑 STOP` added explicitly blocking progression to Step 5 until the research question is asked and answered.
  - **Steps 5, 6, 7 STOP gates:** Upgraded from `⚠` advisory text to the `🛑 STOP.` pattern used in the rest of the workflow for consistency.
- **Tests added** (5 new checks in `tests/validate_multiplatform.sh`):
  - `new-project has 4 numbered question exchanges` — verifies Exchange 1–4 exist
  - `new-project tracks ANSWER_1..ANSWER_4` — verifies named answer registers
  - `new-project Step 4 has explicit user-confirmation gate` — verifies `Do not proceed to Step 5` + `Reply yes to continue`
  - `new-project has STOP gate between PROJECT.md confirmation and research decision`
  - `.windsurf/workflows/new-project.md has structural gates (mirror in sync)`
- Synced fix to both `learnship/workflows/new-project.md` and `.windsurf/workflows/new-project.md`.

---

## [v1.9.12] — Fix new-project skipping full ceremony on detailed first answer

**Released:** 2026-03-19

### Fixed

- **`new-project` collapses ceremony when user gives a detailed first answer** — Step 3 lacked a hard minimum: if the user's first reply was specific and detailed, the AI would self-conclude it had "enough context", skip to PROJECT.md, then silently collapse the remaining steps (research decision, requirements gathering, roadmap) into a direct code change. Root cause: no required minimum of follow-up questions before the AI could proceed.
  - **Step 3 fix:** Added explicit `⚠ MANDATORY MINIMUM` gate: AI must ask **at least 3 follow-up questions** after the user's first answer before being allowed to propose writing PROJECT.md. No exceptions regardless of how detailed the initial response is.
  - **Step 4 fix:** Added mandatory `⚠ STOP` after writing PROJECT.md: AI must show the full file to the user and receive explicit confirmation before proceeding to the research decision. A brief "ok" or silence does not count as confirmation.
- Synced fix to both `learnship/workflows/new-project.md` and `.windsurf/workflows/new-project.md`.

---

## [v1.9.11] — Sync 3 new impeccable skills from upstream (arrange, typeset, overdrive)

**Released:** 2026-03-19

### Added

- **`@impeccable arrange`** — New skill: fix layout, spacing, and visual rhythm. Tackles monotonous grids, inconsistent spacing, and weak visual hierarchy. Includes squint test, spacing system guidance, Flexbox-vs-Grid decision framework, card grid anti-patterns.
- **`@impeccable typeset`** — New skill: fix font choices, hierarchy, sizing, weight consistency, and readability. Turns default-looking Inter/Roboto text into intentional, well-crafted type. Includes fluid-vs-fixed scale guidance, web font loading, OpenType details.
- **`@impeccable overdrive`** — New skill: push interfaces past conventional limits with technically ambitious implementations — shaders, 60fps virtual tables via virtual scrolling, spring physics on dialogs, scroll-driven animations, WebGPU. Proposes 2-3 directions before building; requires user confirmation.
- **`frontend-design` Context Gathering Protocol** — Added the upstream "Context Gathering Protocol" section to `frontend-design/SKILL.md`, making the 3-step context-gathering order (instructions → `.impeccable.md` → teach-impeccable) explicit for all design skills.

### Fixed

- **Broken `reference/` links in `arrange` and `typeset`** — Both skills referenced `reference/spatial-design.md` and `reference/typography.md` from their own directory (which doesn't exist). Fixed to `../frontend-design/reference/spatial-design.md` and `../frontend-design/reference/typography.md`.
- **`typography.md` fluid type guidance** — Updated to upstream's more precise version: distinguishes "use fluid type for marketing headings" vs "use fixed rem scales for app UIs" (no major app design system uses fluid type in product UI).

### Changed

- **Root `impeccable/SKILL.md`** — Updated action count 18→21, added `arrange`, `typeset`, `overdrive` to the Actions list.
- **`install.js` `SUB_ACTION_ORDER`** — Added `arrange`, `overdrive`, `typeset` so Claude Code plugin inlines all 21 sub-skill bodies correctly.
- **`audit/SKILL.md`** — Suggested command lists updated to include `/arrange`, `/typeset`, `/overdrive`.
- **`sync-upstream-skills` workflow** — Updated 18→21 throughout (expected list, banner text, integrity check).
- **`cursor-rules/learnship.mdc`** — Added `@impeccable arrange`, `@impeccable typeset`, `@impeccable overdrive` to the Design Quality section.
- **Tests** — Section 10/11 updated: `SUB_SKILLS` array has all 21, body-content checks assert `arrange`/`overdrive`/`typeset` inline content, size threshold raised to 60 000 chars.
- **README, docs** — All "18 commands"/"17 commands" references updated to 21 throughout (`docs/skills/impeccable.md`, `docs/getting-started/installation.md`, `docs/index.md`, `docs/platform-guide/*.md`).
- **Images** — `assets/impeccable-commands.png` regenerated with 21-command grid; `assets/skills-overview.png` regenerated showing `[21 sub-skills]` (was `[17 sub-skills]`). `generate_images.py` prompts updated to match.

---

## [v1.9.10] — Fix `@impeccable` not found in Claude Code

**Released:** 2026-03-18

### Fixed

- **`@impeccable critique` (and all other actions) returned "isn't installed as a skill"** — `installClaudePlugins` was writing a hollow 100-line index `SKILL.md` that listed sub-skills as markdown reference links (`[critique/SKILL.md](references/critique/SKILL.md)`). Claude Code does not follow those links when resolving `@mentions`, so the skill loaded with no actionable content. Fix: `installClaudePlugins` now builds a single **inlined** `SKILL.md` (~3000 lines) that concatenates all 18 sub-skill bodies under `## Action: \`<name>\`` headers — identical in approach to `agentic-learning` which already worked correctly.
- **`installClaudePlugins` exported for testing** — added to `LEARNSHIP_TEST_MODE` exports so section 10 tests can use the real function instead of a duplicated local simulation.
- **Section 10 tests updated** — replaced the stale local `runInstallClaudePlugins` clone with the real exported function; tests 7/8/9 now verify inlined content, real bodies, and clean frontmatter instead of the old reference-link approach.

### Platform impact

| Platform | Skill delivery | Change |
|---|---|---|
| **Claude Code** | `plugins/learnship/skills/impeccable/SKILL.md` — fully inlined | ✅ Fixed |
| **Windsurf** | `.windsurf/skills/impeccable/` — native sub-skill dirs | No change |
| **Cursor** | `skills/impeccable/` via `.cursor-plugin/plugin.json` + `.mdc` rule | No change |
| **OpenCode / Gemini / Codex** | `learnship/skills/impeccable/` via plain `copyDir` | No change |

---

## [v1.9.9] — Correct parallelization platform matrix (Gemini CLI sequential-only; Cursor 2.4+ parallel)

**Released:** 2026-03-18

### Fixed

- **Gemini CLI incorrectly offered the parallelization question** — Gemini CLI has subagents but parallel execution is not yet shipped (open GitHub issues #14963, #17749). `rewriteNewProject` now treats Gemini the same as Windsurf for Group D: auto-sets `parallelization: false` and explains why.
- **Cursor docs said "Parallel subagents: ❌ Not supported"** — Cursor 2.4 (released Oct 2025) introduced native parallel subagents. Updated `docs/platform-guide/cursor.md` capabilities table.
- **2 new tests added** for OpenCode and Codex parallel block; Gemini test corrected to assert question is absent.

### Verified parallel subagent support (from official docs):

| Platform | Parallel subagents |
|---|---|
| Claude Code | ✅ Yes — `Task()` tool |
| OpenCode | ✅ Yes |
| Codex CLI | ✅ Yes — explicit spawning, `max_concurrency` |
| Cursor | ✅ Yes — since 2.4 (Oct 2025), via `.cursor/rules/` workflows |
| Gemini CLI | ⚠️ Sequential only — parallel is an open issue, not shipped |
| Windsurf | ❌ No subagents |

---

## [v1.9.8] — Fix platform-specific gitignore and parallelization question via install-time rewriting

**Released:** 2026-03-18

### Fixed

- **`.windsurf/` was added to `.gitignore` on Claude Code installs** — the gitignore bash block was a multi-line commented snippet; agents ran the first uncommented line (`.claude/`) on Claude Code, but the Windsurf-installed workflow kept `.windsurf/` commented out. Now `install.js` rewrites the gitignore command at install time to a single exact line per platform (e.g. `grep -q '.claude/' .gitignore || echo '.claude/' >> .gitignore` for Claude Code, `.windsurf/` for Windsurf, etc.). No conditional prose for the agent to misinterpret.
- **Parallelization question not asked on Claude Code** — the `If PLATFORM is WINDSURF skip / else ask` conditional prose was too ambiguous for agents. `install.js` now rewrites Group D at install time: non-Windsurf platforms get the question unconditionally; Windsurf gets a note saying parallelization is automatically `false`.
- **Platform label now injected at install time** — Step 1 states the exact platform name and config dir, removing any runtime detection logic entirely.
- **8 new unit tests** added for `rewriteNewProject()` covering all platforms (gitignore dir, parallel block presence/absence, no raw markers remaining).

---

## [v1.9.7] — Fix platform detection using file path table (not env vars)

**Released:** 2026-03-18

### Fixed

- **Platform detection was unreliable on multi-platform machines** — env-var detection returned `WINDSURF` on any machine with `~/.codeium/` installed, even when running inside Claude Code. Detection now uses a simple path-segment lookup table: the agent inspects the path of the file it is reading (e.g. `.../.claude/learnship/workflows/new-project.md`) and maps the directory segment to the platform. No bash, no env vars, not affected by `replacePaths()`.

---

## [v1.9.6] — Fix all 42 Claude Code command wrappers pointing to wrong workflow path

**Released:** 2026-03-18

### Fixed

- **All 42 Claude Code commands were silently broken** — every command wrapper in `commands/learnship/` referenced `@~/.claude/workflows/<name>.md` but the actual install path is `@~/.claude/learnship/workflows/<name>.md`. Claude Code was reading a non-existent file and falling back to its own (incomplete) knowledge for every command — `/learnship:new-project`, `/learnship:execute-phase`, `/learnship:ls`, and all others. All 42 paths corrected to `@~/.claude/learnship/workflows/`.

---

## [v1.9.5] — new-project: platform detection + correct parallelization question per platform

**Released:** 2026-03-18

### Fixed

- **`new-project` didn't ask parallelization question on Claude Code** — Step 1 now detects the running platform (Claude Code, OpenCode, Gemini CLI, Codex CLI, Windsurf) by checking which config directory contains the workflow file. Group D parallelization question is now gated with an explicit `If PLATFORM is CLAUDE/OPENCODE/GEMINI/CODEX: Ask this` / `If PLATFORM is WINDSURF: Skip, set false` structure — replacing the weak hint that agents ignored.
- **`new-project` was adding `.windsurf/` to `.gitignore` on all platforms** — now adds the correct platform-specific directory (`.claude/`, `.opencode/`, `.gemini/`, `.codex/`, or `.windsurf/`) based on detected platform.
- **Step 9 completion message** — now shows the detected platform and parallelization setting as confirmation.
- Both `learnship/workflows/new-project.md` and `.windsurf/workflows/new-project.md` updated in sync.

---

## [v1.9.4] — Fix skills not installing on Claude Code, OpenCode, Gemini, Codex

**Released:** 2026-03-18

### Fixed

- **Skills install failure on all non-Windsurf platforms** — `bin/install.js` was looking for skills at `.windsurf/skills/` (a Windsurf-specific path) instead of the repo-root `skills/` directory. This caused an `ENOENT` crash during `npx learnship --claude` (and all other platforms). Skills now install correctly for all platforms.

---

## [v1.9.3] — Fix npx learnship showing Windsurf-only installer

**Released:** 2026-03-18

### Fixed

- **`npx learnship` was Windsurf-only** — `bin/learnship.js` was calling `install.sh` (the old Windsurf-only shell script) instead of `bin/install.js` (the full multi-platform Node.js installer). Running `npx learnship` would show only a Windsurf prompt and fail with a source-path error. Now correctly delegates to `bin/install.js`, showing the full interactive platform selector (Windsurf, Claude Code, OpenCode, Gemini CLI, Codex CLI).

---

## [v1.9.2] — Cursor plugin compliance + housekeeping

**Released:** 2026-03-18

### Fixed

- **Cursor `plugin.json`** — added required `displayName` field; added `commands` field pointing to `commands/learnship`; fixed `logo` to reference `assets/logo.png` (PNG with background plate) instead of the SVG.
- **`hooks-cursor.json`** — replaced invalid `sessionStart` hook type (not supported by Cursor) with `beforeSubmitPrompt`; removed spurious `"version": 1` field not in Cursor spec.
- **Author email** — corrected `favio.vazquez@gmail.com` → `favio.vazquezp@gmail.com` across all plugin manifests (`.claude-plugin/plugin.json`, `.cursor-plugin/plugin.json`, `marketplace/.claude-plugin/marketplace.json`).
- **Test suite** — updated hooks test to expect `beforeSubmitPrompt` instead of `sessionStart`.

### Added

- **`assets/logo.png`** — 512×512 PNG logo (dark background, `/ls` in green) for Cursor marketplace submission.
- **`PRIVACY.md`** — privacy policy for Anthropic Claude Code Verified Status; learnship collects no user data.

---

## [v1.9.1] — Fix new-project workflow skipping steps + auto npm publish

**Released:** 2026-03-18

### Fixed

- **`new-project` workflow skipping steps 5–8** — agents were jumping from questioning directly to building, bypassing the research decision, interactive requirements selection, roadmap approval, and `AGENTS.md` generation. Added explicit `⚠ STOP` gates after Steps 4, 5, 6, and 7 instructing the agent not to proceed until the user responds at each gate.
- **`AGENTS.md` never written** — root cause was the above skip. Step 8 now carries a `🔴 MANDATORY` marker making it unambiguous that it must always be executed before Step 9, regardless of how the agent perceives the session state.

### Added

- **GitHub Action: auto npm publish** (`.github/workflows/publish.yml`) — triggers on any `v*` tag push. Runs the full test suite first (`tests/run_all.sh`), verifies the tag matches `package.json` version, then runs `npm publish --access public` using the `NPM_TOKEN` repo secret. No more manual `npm publish` after tagging.

---

## [v1.9.0] — Multi-platform distribution: marketplaces, hooks, session context injection, npm publish

**Released:** 2026-03-18

### Added

- **Claude Code plugin manifest** (`.claude-plugin/plugin.json`): learnship is now a native Claude Code plugin. Install via `/plugin marketplace add FavioVazquez/learnship-marketplace` + `/plugin install learnship@learnship-marketplace`.
- **Claude Code community marketplace** (`marketplace/.claude-plugin/marketplace.json` + `FavioVazquez/learnship-marketplace` repo): enables community marketplace discovery in Claude Code.
- **Cursor plugin manifest** (`.cursor-plugin/plugin.json`) and rules (`cursor-rules/learnship.mdc`): full Cursor plugin with skills, rules, and agents. Install via `/add-plugin learnship` in Cursor.
- **Cursor platform guide** (`docs/platform-guide/cursor.md`): dedicated documentation page for Cursor, covering install, workflows, skills, hooks, and capabilities.
- **Gemini CLI native extension** (`gemini-extension.json`): enables `gemini extensions install https://github.com/FavioVazquez/learnship` as a zero-terminal install path.
- **npm publish prep**: `publishConfig.access = "public"`, `.npmignore`, new manifests in `files`. `npx learnship` is now the canonical install command replacing the old `npx github:` form.
- **Session-start hooks** (`hooks/session-start`, `hooks/hooks-cursor.json`, `hooks/hooks-claude.json`): bash hook that injects learnship context (`SKILL.md`) at every session start for Claude Code and Cursor. Correctly emits `hookSpecificOutput.additionalContext` for Claude Code and `additional_context` for Cursor — no double-injection.
- **Platform-neutral `skills/` directory**: skills now live at `skills/` (not `.windsurf/skills/`) in the published package, eliminating confusing Windsurf-branded paths in Cursor and Claude Code plugin manifests. `.windsurf/skills/` retained for Windsurf native install.
- **Cursor added as 6th platform** throughout: README badge, platform table, `docs/index.md`, `mkdocs.yml` nav, all image prompts regenerated.
- **8 brand images regenerated**: `install`, `platform-comparison`, `impeccable-commands`, `skills-overview`, `how-it-works`, `phase-loop`, `vibe-vs-agentic`, `quick-start-flow` — all updated for `npx learnship`, 6 platforms, 18 impeccable commands.
- **39 new tests** (Sections 15, 19, 20): plugin manifest validation, `skills/` directory sync, hooks structure + executable bit + shebang, plugin-root paths in hook manifests, runtime execution tests for `session-start` across all three modes (Cursor, Claude Code, fallback) — validates valid JSON output, correct keys per platform, no double-injection, learnship keywords in context, graceful exit when `SKILL.md` missing.

### Fixed

- **Critical: double `learnship/learnship/` path bug** in all 42 `commands/learnship/` source files. Command files referenced `@~/.claude/learnship/workflows/` but `replacePaths()` replaces `~/.claude/` → `pathPrefix` (which is already `~/.claude/learnship/`), producing `learnship/learnship/` on every non-Windsurf platform. This silently broke every workflow command — `/new-project`, `/ls`, all 42 — on Claude Code, OpenCode, Gemini CLI, and Codex CLI. `AGENTS.md` was never generated because `/new-project` couldn't load its workflow file. Fixed by changing all source references to `@~/.claude/workflows/` (no `learnship/` prefix).
- **Hook manifest command paths**: changed from relative `./hooks/session-start` to `"${CLAUDE_PLUGIN_ROOT}/hooks/session-start"` and `"${CURSOR_PLUGIN_ROOT}/hooks/session-start"` — relative paths break when plugins are installed globally.
- **`hooks-claude.json` format**: corrected to match Claude Code's actual hook schema (`description` + inner `hooks` array with `type: "command"`).

### Changed

- **`npx github:FavioVazquez/learnship` → `npx learnship`** across README and all 7 platform docs pages.
- **Plugin manifests**: `skills` field changed from `.windsurf/skills` → `skills` (platform-neutral); `hooks` field added to both Claude Code and Cursor manifests.
- **`package.json` `files`**: `.windsurf/skills` replaced with `skills` and `hooks` added.
- **Post-install message** in `bin/install.js` now explicitly tells users to run `/new-project` to generate `AGENTS.md` — it is not created by the installer.
- **Platform guides for OpenCode, Gemini CLI, Codex CLI**: added `AGENTS.md` auto-loading tip (not auto-loaded on these platforms the way it is on Windsurf/Claude Code/Cursor); fixed 17 → 18 impeccable sub-skills count.
- **`impeccable` command count**: 17 → 18 throughout (`frontend-design` command added previously but count was stale in README, docs, and image prompts).
- **`docs/index.md`**: 5 → 6 platforms, Cursor badge added, 17 → 18 impeccable count.
- **`mkdocs.yml` `site_description`**: updated to include Cursor.

---

## [v1.8.0] — impeccable integration: automatic UI standards and milestone recommendations

**Released:** 2026-03-14

### Added

- **`execute-phase` UI detection (Step 2b):** Before executing any phase, learnship now scans plan objectives and file paths for UI/frontend signals (`component`, `page`, `layout`, `tailwind`, `.tsx`, `.jsx`, etc.). When detected, it activates `@impeccable frontend-design` principles as active execution guidance — typography, color, layout, and component standards applied as constraints during execution, not as a post-hoc review. Displays a `UI PHASE DETECTED` banner and carries principles through every task in the phase.
- **Post-action milestone recommendation in `@impeccable`:** After any impeccable action that produces recommendations (`audit`, `critique`, `polish`, `normalize`, `harden`, `adapt`, `optimize`, `bolder`, `quieter`, `colorize`, `clarify`, `delight`, `onboard`, `animate`, `distill`, `extract`), the agent now always closes with a suggestion to run `/new-milestone` to create a dedicated "UI Polish" milestone — turning recommendations into versioned, traceable phases with plans and commits. Setup actions (`teach-impeccable`, `frontend-design`) are exempt.
- **9 new tests in `validate_multiplatform.sh`** covering both integration behaviors, sync between `.windsurf/` and `learnship/` copies, and docs/README coverage.
- **Docs updated** (`docs/skills/impeccable.md`) with a new "learnship integration" section documenting both behaviors.
- **README updated** with integration description in the Design System section.

---

## [v1.7.1] — Fix AGENTS.md not generated on Windsurf new-project

**Released:** 2026-03-14

### Fixed

- **Windsurf installer** now copies `templates/` and `references/` subdirectories into `workflows/` so `@./templates/agents.md` and `@./references/questioning.md` references resolve correctly on Windsurf. Previously, `new-project` Step 8 silently skipped writing `AGENTS.md` because the template file path was broken on Windsurf (other platforms were unaffected).
- **Tests** — added coverage for `learnship/templates/agents.md` and `learnship/references/questioning.md` existence

---

## [v1.7.0] — Full documentation site (MkDocs + GitHub Pages)

**Released:** 2026-03-14

### Added

- **Full documentation site** at `https://faviovazquez.github.io/learnship/` — built with MkDocs Material theme
- **`mkdocs.yml`** — complete site config with Material theme, custom brand CSS, tabbed content, admonitions, mermaid diagrams, search, and dark/light mode
- **`docs/`** — 26 pages covering everything:
  - Getting Started: installation, first project walkthrough, the 5 commands
  - Platform Guide: dedicated pages for all 5 platforms (Windsurf, Claude Code, OpenCode, Gemini CLI, Codex CLI)
  - Core Concepts: phase loop, context engineering, planning artifacts, agentic vs vibe coding
  - Skills: full reference for all 11 `@agentic-learning` actions and all 17 `impeccable` commands
  - Workflow Reference: all 42 workflows organized across 7 category pages
  - Configuration: full `config.json` schema reference
  - Examples: greenfield, brownfield, quick tasks, multi-session patterns
  - Contributing guide
- **`.github/workflows/docs.yml`** — auto-deploys to GitHub Pages on every push to `main` that touches `docs/` or `mkdocs.yml`
- **8 new image definitions** in `generate_images.py` (keys: `agentic_learning_actions`, `impeccable_commands`, `platform_comparison`, `planning_artifacts`, `config_schema`, `parallel_execution`, `skills_overview`, `milestone_lifecycle`) — 16 total
- **`docs/stylesheets/extra.css`** — brand CSS: hero section, card grids, platform badges, command pills, learn badges, typography
- **Test section [13]** — 10 new checks in `tests/validate_multiplatform.sh` verifying mkdocs config, all platform pages, all 11 learning actions documented, docs workflow, README link, and image count — **156 total passing**
- **README** — added docs badge + `📚 Full Docs` link + "What is learnship / What problem / Who is it for" sections with agent harness and progressive disclosure framing
- **`docs/index.md`** — full "What is learnship / What problem / Who is it for" context sections explaining learnship as an agent harness using progressive disclosure
- **`assets/logo.svg`** — `/ls` monospace wordmark (white, transparent background)
- **`assets/favicon.svg`** — crisp SVG favicon: dark rounded background + white `/ls` text, infinitely sharp at any size
- **`docs/assets`** — symlinked to `assets/` root — single source of truth, no duplication between README and docs images

### Fixed

- Docs hero badges all use `for-the-badge` style with `labelColor=555555` for visual consistency
- Platform and workflows badges now clickable with correct MkDocs URL paths
- `docs.yml` CI workflow pins `mkdocs-material<2` and resolves `docs/assets` symlink before build
- Test section [13]: replaced gitignored `generate_images.py` check with `assets/` PNG count check
- `new-project.md` — added parallelization question for non-Windsurf platforms during setup

---

## [v1.6.3] — Deep agentic-learning integration across all workflow phases

**Released:** 2026-03-14

### Changed

All 11 core workflows now surface contextually matched `@agentic-learning` actions at every phase transition — not just one tail tip, but 2-3 options matched to what just happened:

- **`execute-phase`** — Learning Checkpoint now offers `reflect` + `quiz` + `interleave`. Active recall on what was built, gaps in understanding surfaced before they become next-phase bugs.
- **`plan-phase`** — Now offers `explain-first` + `cognitive-load` + `quiz`. Validate the mental model before touching code, not after.
- **`research-phase`** — Now offers `learn` + `explain-first` + `quiz`. Three retrieval actions while new domain knowledge is at peak freshness.
- **`discuss-phase`** — Now offers `either-or` + `brainstorm` + `explain-first`. Decision journaling plus blind-spot surfacing and model validation before locking context.
- **`verify-work`** — Now has separate learning paths: pass path (`space` + `quiz`) and bug-found path (`learn` + `space`). Bugs during UAT are treated as learning opportunities, not just defects.
- **`debug`** — Replaced single `either-or` with `learn` + `struggle` + `either-or`. Bugs are the highest-signal learning moments — each now explicitly drives retrieval and re-investigation.
- **`quick`** — Removed overly narrow "technically complex" condition. Now offers `struggle` + `learn` + `either-or` for any completed task with a matching rationale.
- **`pause-work`** — **New Learning Checkpoint added.** Session transitions are when learning decays fastest. Now offers `space` + `reflect` before the session ends.
- **`resume-work`** — **New Learning Checkpoint added.** Returning after a break now offers `quiz` + `space` to warm up before diving in.
- **`new-milestone`** — Added missing `manual` branch to Learning Checkpoint.
- **`debug`** — Added missing `manual` branch to Learning Checkpoint.
- All `.windsurf/workflows/` changes synced to `learnship/workflows/`.

### Added

- **Test section [12]** — 14 new checks in `tests/validate_multiplatform.sh` verifying:
  - All 13 key workflows have a Learning Checkpoint section
  - All checkpoints read `learning_mode` and have both `auto` + `manual` branches
  - Per-workflow action coverage (reflect/quiz/interleave in execute-phase, etc.)
  - All 11 `@agentic-learning` actions (`learn`, `quiz`, `reflect`, `space`, `brainstorm`, `explain-first`, `struggle`, `either-or`, `explain`, `interleave`, `cognitive-load`) referenced somewhere in the suite
  - Source/installed copies in sync for all 9 modified workflows

---

## [v1.6.2] — Subagent dispatch for plan-phase, execute-phase, and debug

**Released:** 2026-03-14

### Changed

- **`plan-phase` workflow** — Now reads `parallelization` from `.planning/config.json`. When `true`, spawns three dedicated subagents (`learnship-phase-researcher`, `learnship-planner`, `learnship-plan-checker`) each with a fresh context budget. When `false` (default), all stages run inline using agent persona files (unchanged behavior).
- **`execute-phase` workflow** — Now reads `parallelization` from `.planning/config.json`. When `true`, dispatches each plan in a wave to a dedicated `learnship-executor` subagent; spawns all wave plans before waiting. When `false` (default), sequential persona-based execution unchanged.
- **`debug` workflow** — Now reads `parallelization` from `.planning/config.json`. When `true`, spawns a dedicated `learnship-debugger` subagent with a fresh context budget for deep root-cause investigation. When `false` (default), inline debugger persona unchanged.
- Both `.windsurf/workflows/` and `learnship/workflows/` copies updated in sync.

---

## [v1.6.1] — Platform-agnostic language sweep

**Released:** 2026-03-12

### Added

- **`/sync-upstream-skills` workflow** — New workflow that pulls the latest skill content from both upstream repos into learnship's skill tree, then re-runs the installer so all platforms receive the update:
  - `FavioVazquez/agentic-learning` → replaces `.windsurf/skills/agentic-learning/SKILL.md` + `references/` verbatim
  - `pbakaus/impeccable` → replaces each of the 18 sub-skill dirs under `.windsurf/skills/impeccable/` from `source/skills/`
  - **Preserves** `.windsurf/skills/impeccable/SKILL.md` (learnship's own dispatcher — not in upstream)
  - Backs up current skills before overwriting; auto-restores on integrity failure
  - Re-runs `node bin/install.js --all` to propagate to Claude Code plugins, Windsurf, and context-file platforms
  - Prompts to review if upstream added new actions/sub-skills that need learnship's dispatcher updated

### Changed

- **`SKILL.md`** (root) — "Windsurf-native platform" → "multi-platform agentic engineering system"; workflow list intro updated to mention all platforms.
- **`templates/agents.md`** + **`learnship/templates/agents.md`** — "Windsurf reads this file" → "Your AI agent reads this file".
- **`learnship/workflows/ls.md`** + **`.windsurf/workflows/ls.md`** — "Windsurf-native platform" → "multi-platform agentic engineering system".
- **`learnship/workflows/new-project.md`** + **`.windsurf/workflows/new-project.md`** — "Windsurf reads this every conversation" → "your AI agent reads this every conversation".
- **`learnship/workflows/execute-phase.md`** — sequential mode comment now says "Windsurf, Gemini CLI" (was "Windsurf, Gemini").
- **`agents/learnship-executor.md`** — "Windsurf/Codex projects" → "Windsurf, Codex, or any platform that uses AGENTS.md".
- **`CONTRIBUTING.md`** — "Windsurf slash commands" → "slash commands"; "Windsurf's command palette" → "the agent's command palette"; "Windsurf-native rules" section heading → "Workflow rules"; testing instructions updated to show multi-platform install; "Windsurf-native" philosophy bullet → "Platform-native".
- **`README.md`** — repository structure comments updated: "Windsurf slash commands" → "slash commands"; skill native platform comments updated to include Claude Code; "non-Windsurf" → "OpenCode/Gemini/Codex".
- **`.windsurf/skills/agentic-learning/SKILL.md`** + **`.windsurf/skills/impeccable/SKILL.md`** — `compatibility` field updated to include Claude Code.
- **`publish-first-release.md`** — "Windsurf-native platform" → "multi-platform agentic engineering system".

---

## [v1.6.0] — Claude Code native plugin skills

**Released:** 2026-03-12

### Added

- **`bin/install.js` — `installClaudePlugins()`** — New function that installs skills as a native Claude Code plugin under `~/.claude/plugins/learnship/`. Creates exactly **2 skills**:
  - `skills/agentic-learning/` — full copy with `SKILL.md` + `references/`
  - `skills/impeccable/` — root `SKILL.md` (dispatcher) + all 18 sub-skills copied into `references/`: `adapt`, `animate`, `audit`, `bolder`, `clarify`, `colorize`, `critique`, `delight`, `distill`, `extract`, `frontend-design`, `harden`, `normalize`, `onboard`, `optimize`, `polish`, `quieter`, `teach-impeccable`
  - `.claude-plugin/plugin.json` — plugin manifest
- **`.windsurf/skills/impeccable/SKILL.md`** — New root skill file. Links to sub-skills using sibling paths (`adapt/SKILL.md`) which work for Windsurf. The installer rewrites these to `references/adapt/SKILL.md` when copying to the Claude Code plugin dir.
- **Uninstall** — `plugins/learnship/` is now removed on `--uninstall` for the `claude` platform.
- **Section [10] tests** — 10 new checks verifying plugin structure, manifest fields, two-skill count, path rewriting, all 18 references, no flattening, and uninstall guard. Test suite now covers **113 checks, 0 failures**.

### Notes

- The existing `learnship/skills/` context file copy is preserved for backwards compatibility.
- Windsurf reads `impeccable/SKILL.md` directly with correct sibling-relative paths.
- Claude Code gets the same content with paths rewritten to `references/` to match the installed layout.

---

## [v1.5.3] — Fix skills missing on npx install

**Released:** 2026-03-10

### Fixed

- **`package.json`** — Added `.windsurf/skills` to the `files` array. It was missing, so `npx github:FavioVazquez/learnship` stripped the skills directory entirely — `fs.existsSync(skillsSrc)` returned false and skills were silently skipped for all platforms.
- **`package.json`** — Bumped version to `1.5.3` so the banner correctly displays the current version.
- **`tests/validate_multiplatform.sh`** — Added regression test in section [1]: verifies `package.json` `files` includes `.windsurf/skills`. **103 checks, 0 failures**.

---

## [v1.5.2] — Fix skills not installed for Windsurf

**Released:** 2026-03-09

### Fixed

- **`bin/install.js`** — Skills (`agentic-learning`, `impeccable`) were not installed for Windsurf at all. The guard `platform !== 'windsurf'` was wrong — Windsurf needs skills copied to `targetDir/skills/` (i.e. `.windsurf/skills/`) so Cascade can invoke them natively. Other platforms still get them at `learnship/skills/` as context files.
- **`tests/validate_multiplatform.sh`** — Updated test 7 in section [9] to verify Windsurf gets skills at `skills/` (native) and others at `learnship/skills/`. **102 checks, 0 failures**.

---

## [v1.5.1] — Fix local Windsurf install path

**Released:** 2026-03-09

### Fixed

- **`bin/install.js`** — Local Windsurf install (`--windsurf --local`) was writing to `.codeium/windsurf/` inside the project instead of `.windsurf/`. Cascade reads `.windsurf/workflows/` — commands were installed but never loaded. Fixed `getDirName('windsurf')` to return `.windsurf` (global install correctly uses `~/.codeium/windsurf/` via `getGlobalDir` and was unaffected).
- **`tests/validate_multiplatform.sh`** — Added regression test: local Windsurf install path must be `.windsurf/` not `.codeium/windsurf/`. Test suite now covers **102 checks, 0 failures**.

---

## [v1.5.0] — Skills on all platforms, purple ASCII banner, 101-check test suite

**Released:** 2026-03-09

### Added

- **Skills installed on all non-Windsurf platforms** — `agentic-learning` and `impeccable` are now copied to `learnship/skills/` as context files during install on Claude Code, OpenCode, Gemini CLI, and Codex CLI. The AI reads and applies the learning techniques and design standards automatically. Windsurf keeps native `@invoke` support unchanged.
- **Purple ASCII art banner** — `npx github:FavioVazquez/learnship` now displays a full ASCII art `learnship` logo in purple (distinct from GSD's cyan) with the slogan `Learn as you build. Build with intent.` and all 5 platform names.
- **Section [9] skills tests** — 7 new checks in `tests/validate_multiplatform.sh` verifying skills source structure, copy correctness, SKILL.md content, impeccable sub-skills, and the Windsurf guard. Test suite now covers **101 checks total, 0 failures**.

### Changed

- **README: platform capabilities table** — Added `Skills (native @invoke)` and `Skills (context files)` rows showing per-platform support.
- **README: Learning Partner section** — Added per-platform table explaining how `agentic-learning` works on each platform.
- **README: Design System section** — Added per-platform table explaining how `impeccable` works on each platform.
- **README: repository structure** — Accurate skill count (14 impeccable sub-skills), context files note for non-Windsurf platforms.
- **`generate_images.py`** — `install.png` and `agents-md.png` prompts updated to be platform-agnostic (purple ASCII art, all 5 platforms listed, no Windsurf-specific copy).
- **`assets/install.png`** — Regenerated: purple ASCII art banner, `~/.claude/learnship/` install path, all 5 platforms in annotation panel.
- **`assets/agents-md.png`** — Regenerated: subtitle now reads "Your AI agent reads this file automatically" (no Windsurf mention).

### Removed

- **`.windsurf/skills/frontend-design/`** — Deleted top-level duplicate. The canonical `frontend-design` skill lives at `impeccable/frontend-design/` and is already referenced by all impeccable sub-skills.

---

## [v1.4.0] — Multi-platform support: Claude Code, OpenCode, Gemini CLI, Codex CLI

**Released:** 2026-03-08

### Added

- **Multi-platform installer** — `bin/install.js` Node.js installer replacing bash-only `install.sh`. Supports `--windsurf`, `--claude`, `--opencode`, `--gemini`, `--codex`, `--all` flags with `--global`/`--local` scope.
- **`commands/learnship/`** — 42 Claude Code format command wrappers (`/learnship:ls`, `/learnship:new-project`, etc.) auto-converted to platform-specific formats at install time.
- **`learnship/`** — Payload directory with all 42 workflows, references, and templates installed to each platform's config dir.
- **`agents/learnship-executor.md`** — Spawnable plan executor for Claude Code, OpenCode, Codex (atomic per-task commits, SUMMARY.md, STATE.md updates).
- **`agents/learnship-planner.md`** — Spawnable planner agent for phase plan creation.
- **`agents/learnship-phase-researcher.md`** — Spawnable research agent for pre-planning domain investigation.
- **`agents/learnship-plan-checker.md`** — Spawnable plan verifier (goal coverage, requirements, wave correctness).
- **`agents/learnship-verifier.md`** — Spawnable phase verifier (must_haves, integration links, requirement traceability).
- **`agents/learnship-debugger.md`** — Spawnable debugger with scientific method root-cause investigation.
- **Platform-enhanced workflows** — `execute-phase`, `plan-phase`, and `debug` now detect `parallelization` in config and spawn real subagents on capable platforms (Claude Code, OpenCode, Codex). Sequential fallback always available.
- **`tests/validate_multiplatform.sh`** — Full multi-platform test suite: installer, command wrappers, learnship/ payload, agent files, conversion functions.
- **README Platform Support section** — Install commands and capability matrix for all 5 platforms.

### Platform command format

| Platform | Commands | Invoked as |
|----------|----------|-----------|
| Windsurf | `.windsurf/workflows/` | `/ls`, `/new-project` |
| Claude Code | `commands/learnship/` | `/learnship:ls` |
| OpenCode | `command/learnship-*.md` | `/learnship-ls` |
| Gemini CLI | `commands/learnship/*.toml` | `/learnship:ls` |
| Codex CLI | `skills/learnship-*/` | `$learnship-ls` |

---

## [v1.3.2] — Fix Mermaid \n rendering and npm badge

**Released:** 2026-03-08

### Fixed

- **`README.md`** — All Mermaid node label `\n` replaced with `<br/>` so line breaks render correctly in GitHub and Windsurf
- **`README.md`** — npm badge replaced with GitHub release badge (package not on npm; badge was showing "not found")

---

## [v1.3.1] — Full consistency audit: /ls and /next propagated everywhere

**Released:** 2026-03-08

### Fixed

- **`help.md`** — `/ls` and `/next` added to Navigation table; Quick Reference "after a break" updated; count updated 40+ → 42
- **`transition.md`** — two `/progress` refs replaced with `/ls` and `/next`
- **`templates/agents.md`** — `/progress` ref replaced with `/ls`
- **`install.sh`** — `/ls` and `/next` added to post-install Quick Reference; both added to uninstall cleanup list
- **`README.md`** — Workflow Reference callout updated 40+ → 42
- **`publish-first-release.md`** — workflow count updated 40 → 42

---

## [v1.3.0] — Simplified UX, smarter entry points, Gemini-generated image

**Released:** 2026-03-08

### Added

- **`/ls` workflow** — new primary entry point: shows project status + next step + offers to run it immediately; bootstraps new users to `/new-project` automatically
- **`/next` workflow** — auto-pilot: reads project state and runs the correct next workflow without user needing to remember command names
- **`assets/quick-start-flow.png`** — Gemini Imagen-generated diagram showing the 5-command entry surface with `/ls` as hub
- **`tests/validate_ux.sh`** — new test suite (24 checks) validating `/ls`, `/next`, README documentation, `help.md` Start Here block, and `SKILL.md` references

### Changed

- **README fully restructured** — new-user path first (install → `/ls` → 5 commands → phase loop → how it works), advanced reference below; all 8 images wired to their correct sections; emoji section headings; duplicate sections removed
- **`progress.md` Step 5** — now offers to run the next workflow immediately after displaying it
- **`help.md`** — new "Start Here" table with the 5 essential commands at the top
- **`resume-work.md`** — enriched description with natural language triggers ("continue", "where were we", "pick up where we left off")
- **`SKILL.md`** — `/ls` and `/next` added as primary entry points in workflow suggestions table
- **`tests/validate_workflows.sh`** — `ls.md` and `next.md` added to required workflows; minimum count bumped 30 → 32
- **`tests/validate_package.sh`** — `assets/quick-start-flow.png` added to required assets
- **`tests/run_all.sh`** — `validate_ux.sh` registered as Suite 4
- **`generate_images.py`** — `quick_start_flow` image definition added
- Badge count updated: 40 → 42 workflows

---

## [v1.2.2] — Complete parallel/agent accuracy sweep

**Released:** 2026-03-08

### Fixed

- **`help.md`** — "Wave-based parallel execution" → "Wave-ordered execution"; "in parallel" removed from diagnose-issues description
- **`new-project.md`** — "Spawn 4 parallel research efforts (as subagents or sequential deep reads)" → "Run 4 research passes sequentially"
- **`agents/planner.md`** — wave frontmatter comment, Wave 1 description, and file-conflict rule all use "independent" / "dependency ordering" instead of "parallel"
- **`agents/debugger.md`** — "diagnosing multiple UAT gaps in parallel" → "diagnosing multiple UAT gaps"
- **`references/model-profiles.md`** — "Orchestrators resolve model before spawning" / "Pass model parameter to Task call" replaced with plain resolution logic
- **`references/ui-brand.md`** — "Spawning 4 researchers in parallel" → "Running 4 research passes"; section renamed from "Spawning Indicators" to "Activity Indicators"
- **`references/verification-patterns.md`** — "verification subagent" → "verification step"
- **`SKILL.md`** — wrong skill commands (`/motion`, `/tokens`, `/brand`) replaced with real 17 impeccable commands; "subagent contexts" → plain language

---

## [v1.2.1] — Accuracy pass: correct promises, real skill commands

**Released:** 2026-03-08

### Fixed

- **README `## Design System`** — replaced 13 fictional commands (`/motion`, `/tokens`, `/brand`, `/typography`, etc.) with the 17 real impeccable skill commands (`/audit`, `/critique`, `/polish`, `/normalize`, `/colorize`, `/animate`, `/bolder`, `/quieter`, `/distill`, `/clarify`, `/optimize`, `/harden`, `/delight`, `/extract`, `/adapt`, `/onboard`, `/teach-impeccable`)
- **README file tree** — `skills/` entry updated to show `impeccable/` subfolder with skill breakdown
- **All workflows (44 occurrences)** — `AGENTIC DEV ►` banner prefix replaced with `learnship ►` (missed in v1.2.0 sweep)
- **`execute-phase.md`** — removed false parallelism claims; wave model accurately described as dependency-ordered sequential execution
- **`plan-phase.md`** — "run in parallel" → "independent, execute in any order"
- **`map-codebase.md`** — "parallel agents" → "structured analysis"; banner updated
- **`diagnose-issues.md`** — "in parallel" removed from frontmatter description
- **README diagrams and tables** — all `parallel execution` / `parallel agents` language replaced with accurate Windsurf single-agent equivalents
- **`impeccable/audit` and `impeccable/critique`** — `{{available_commands}}` placeholder resolved to full list of real skill commands

---

## [v1.2.0] — Original Work: GSD scrubbed, impeccable skill integrated

**Released:** 2026-03-08

### Added

- **`frontend-design` skill** — now uses the full upstream [impeccable](https://github.com/pbakaus/impeccable) skill by @pbakaus: all 7 domain-specific reference files (typography, color, spatial, motion, interaction, responsive, ux-writing) with their complete content and 17 commands (`/audit`, `/critique`, `/polish`, `/colorize`, `/animate`, etc.)
- **`SKILL.md`** attribution updated to credit pbakaus/impeccable correctly

### Changed

- **All GSD/get-shit-done references removed** — learnship is now fully original work:
  - `references/model-profiles.md` — agent names renamed (e.g. `gsd-planner` → `planner`), Claude Code-specific notes removed
  - `references/planning-config.md` — `gsd-tools.cjs` binary calls replaced with plain `git` + `python3` bash commands; branch templates no longer prefixed with `gsd/`
  - `references/git-integration.md` — all `gsd-tools.cjs` commit commands replaced with plain `git add` + `git commit`
  - `references/ui-brand.md` — `GSD ►` banner prefix replaced with `learnship ►`
  - `references/verification-patterns.md` — stale `~/.claude/get-shit-done/` path reference removed
  - `templates/state.md` — `/gsd:add-todo` → `/add-todo`, `/gsd:check-todos` → `/check-todos`
  - `templates/project.md` — `/gsd:map-codebase` → `/map-codebase`
  - `.windsurf/workflows/quick.md` — frontmatter description updated
  - `CONTRIBUTING.md` — `gsd-tools.cjs` binary call guidance removed
  - `README.md` — impeccable credit URL corrected to `pbakaus/impeccable`

### Fixed

- **`SKILL.md`** — removed `{{model}}` Claude-specific template variable (not supported in Windsurf)

---

## [v1.1.0] — Install & Workflow Fixes

**Released:** 2026-03-08

### Added

- **`new-project`** — `.windsurf/` is now automatically added to `.gitignore` on every new and existing project, preventing AI platform files from being tracked in user repos
- **`new-project`** — new `commit_mode` configuration option: `auto` (default, commit after each workflow step) or `manual` (skip all git commits, user commits when ready)
- **`templates/config.json`** — new `commit_mode` field with default `auto`
- **Tests** — 3 test suites (`validate_package.sh`, `validate_workflows.sh`, `validate_skills.sh`) with 50 automated checks covering all required files, all 39 workflows, skills structure, and installer
- **CI** — GitHub Actions: 3 jobs — `test`, `lint-shell` (shellcheck), `validate-json`; `npm test` runs the full suite
- **`LICENSE`** — MIT license file
- **`CODE_OF_CONDUCT.md`** — Contributor Covenant

### Fixed

- **`npx` installer** — project install now correctly targets the user's working directory instead of the npx cache (`INIT_CWD` → `LEARNSHIP_INSTALL_CWD`)
- **`install.sh`** — added `realpath` guard to prevent `cp: same file` errors
- **README** — Mermaid diagram node labels now use `<br/>` instead of `\n` (GitHub requires `<br/>` for line breaks inside nodes)
- **README** — CI badge includes `?branch=main` and links to the workflow run page
- **CI** — `run_all.sh` exit code fixed: `set -e` + `((VAR++))` caused false failure when counter was 0

---

## [v1.0.0] — Initial Public Release

**Released:** 2026-03

### Platform

**40 workflows** across the full development lifecycle:

*Core phase loop:*
- `new-project` — full project initialization: questioning → research → requirements → roadmap
- `discuss-phase` — capture implementation decisions before planning
- `plan-phase` — research + create + verify plans for a phase
- `execute-phase` — wave-based parallel execution of all plans
- `verify-work` — manual UAT with auto-diagnosis and fix planning
- `complete-milestone` — archive milestone, tag release, prepare next version
- `new-milestone` — start next version cycle

*Milestone management:*
- `discuss-milestone` — capture goals and anti-goals before starting a milestone
- `add-phase`, `insert-phase`, `remove-phase` — roadmap surgery
- `audit-milestone` — requirement coverage, integration check, stub detection
- `plan-milestone-gaps` — create fix phases from audit findings
- `milestone-retrospective` — 5-question retrospective + spaced review

*Codebase intelligence:*
- `map-codebase` — parallel brownfield analysis (STACK, ARCHITECTURE, CONVENTIONS, CONCERNS)
- `research-phase` — standalone phase research
- `discovery-phase` — structured codebase discovery before planning
- `list-phase-assumptions` — surface intended approach before planning starts

*Execution:*
- `execute-plan` — run a single PLAN.md in isolation
- `quick` — ad-hoc task with atomic commits and state tracking

*Quality & debugging:*
- `debug` — systematic triage → diagnose → fix with persistent session state
- `validate-phase` — retroactive test coverage audit
- `add-tests` — generate unit and E2E tests post-execution
- `diagnose-issues` — batch-diagnose multiple UAT issues in parallel

*Context & knowledge:*
- `transition` — write full handoff document for collaborator or fresh session
- `knowledge-base` — aggregate decisions and lessons into KNOWLEDGE.md
- `decision-log` — ad-hoc architectural decision capture into DECISIONS.md

*Navigation:*
- `progress` — status overview and smart routing
- `pause-work` — save handoff state mid-phase
- `resume-work` — restore full context and continue

*Task management:*
- `add-todo`, `check-todos` — capture and act on ideas mid-session

*Maintenance & config:*
- `health` — project health check with optional `--repair`
- `cleanup` — archive completed milestone phase directories
- `settings` — interactive config editor
- `update` — self-update the platform
- `set-profile` — quick model profile switch
- `reapply-patches` — merge local edits back after an update

*Meta:*
- `help` — show all workflows with descriptions

### Skills

- `agentic-learning` — 11-action neuroscience-backed learning partner (integrated at every workflow checkpoint)
- `frontend-design` — impeccable UI design system with 7 reference files and 17 steering commands

### AGENTS.md System

- `templates/agents.md` — universal project template: Soul + 10 Principles + Platform Context
- `new-project` generates `AGENTS.md` at project root — Windsurf reads it every conversation
- `plan-phase`, `execute-phase`, `debug`, `complete-milestone`, `new-milestone` auto-update it

### Decision Intelligence Layer

- `.planning/DECISIONS.md` — structured cross-phase decision register with DEC-XXX IDs
- `decision-log` — ad-hoc decision capture from any conversation
- `discuss-phase` and `plan-phase` read DECISIONS.md — planner never contradicts active decisions

### Agent Personas

- `planner`, `researcher`, `executor`, `verifier`, `debugger` — 5 specialized agent roles

### Reference Files & Templates

- 8 reference files covering questioning, verification, git, config, model profiles, UI brand, learning design, design commands
- 7 document templates for `.planning/` artifacts and AGENTS.md
