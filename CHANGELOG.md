# Changelog

All notable changes to **learnship** are documented here.

This project uses [semantic versioning](https://semver.org/): `MAJOR.MINOR.PATCH`
- **MAJOR** — significant new capability layers or breaking changes
- **MINOR** — new workflows, skills, or agent personas
- **PATCH** — bug fixes to existing workflows

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
  - `FavioVazquez/agentic-learn` → replaces `.windsurf/skills/agentic-learning/SKILL.md` + `references/` verbatim
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
