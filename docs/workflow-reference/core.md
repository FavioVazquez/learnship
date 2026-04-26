---
title: Core Workflow
description: "Reference for the 8 core learnship workflows: new-project through complete-milestone."
---

# Core Workflow

These 8 workflows form the backbone of every learnship project. They take you from zero to shipped.

![Milestone lifecycle](../assets/milestone-lifecycle.png)

---

## `/new-project`

Initializes a new project with full spec-driven scaffolding.

**What it does:**
1. Structured questioning about what you're building, why, and for whom (standard: 4 exchanges; `--deep`: grill-me style until full shared understanding)
2. Domain research: stack recommendations, architecture patterns, pitfalls
3. Writes `AGENTS.md`, `.planning/PROJECT.md`, `.planning/REQUIREMENTS.md`
4. Proposes a phase-by-phase `ROADMAP.md` for your approval

**Flags:**
- `--deep` — activates grill-me questioning for Step 3: walks every open branch until shared understanding is reached, producing a richer `PROJECT.md`. (v2.3.4)

**When to use:** Start of any new project, greenfield or brownfield (after `/map-codebase`).

**Learning checkpoint:** `@agentic-learning brainstorm [topic]`: surface blind spots before planning starts.

---

## `/discuss-phase [N]`

Captures implementation decisions for phase N before any planning begins.

**What it does:**
1. Reads your roadmap, prior `DECISIONS.md`, and domain-aware probes
2. Identifies gray areas and asks targeted questions with scope guardrails (v2.1)
3. Writes `CONTEXT.md` with domain, decisions, specifics, canonical refs, and deferred ideas
4. Writes `DISCUSSION-LOG.md` as an audit trail of all options considered (v2.1)

**Flags:**
- `--deep` — grill-me style questioning: walks every decision branch until shared understanding is reached, with a recommended answer per question. Produces a richer `CONTEXT.md`. (v2.3.4)

**Config:** Set `workflow.discuss_mode: "deep"` in `config.json` to make deep mode the default without passing the flag.

**When to use:** Before every `/plan-phase`. Skipping this is the #1 source of misaligned plans.

**Learning checkpoint:** `either-or` · `brainstorm` · `explain-first`

---

## `/plan-phase [N]`

Researches the domain and creates executable plans for phase N.

**What it does:**
1. Reads `CONTEXT.md`, `DECISIONS.md`, and `AGENTS.md`
2. Runs domain research if `workflow.research: true`
3. Creates 2–4 `PLAN.md` files as **vertical slices** — each plan delivers one demoable user-facing behavior end-to-end (data → logic → API → UI → test) (v2.3.4)
4. Runs a verification loop (up to 3 passes) checking for gaps, including horizontal slice detection

**Vertical slice planning:** Each plan is a tracer bullet — completable and demoable independently. Horizontal plans (all-schema, all-API, all-UI) are flagged by the plan-checker and require revision. Single-layer phases (migration, style pass) set `single_layer_justified: true` in the plan's frontmatter.

**Output:** `.planning/phases/N-*/N-01-PLAN.md`, `N-02-PLAN.md`, etc.

**When to use:** After `/discuss-phase N` is complete.

**Learning checkpoint:** `explain-first` · `cognitive-load` · `quiz`

---

## `/execute-phase [N]`

Executes all plans for phase N in wave order with atomic commits.

**What it does:**
1. Reads all `PLAN.md` files for the phase
2. Groups plans into waves (independent plans → same wave, dependent → next wave)
3. Executes each task with an atomic git commit
4. Writes `SUMMARY.md` for each plan

**Flags:** `--wave N` to execute only wave N (v2.1). Context window scaling adapts read depth automatically.

**When to use:** After `/plan-phase N` is complete.

**Parallel option:** Set `"parallelization": { "enabled": true }` to dispatch each plan to its own subagent (Claude Code, OpenCode, Gemini CLI, Codex CLI). Up to 5 concurrent agents per wave.

**Learning checkpoint:** `reflect` · `quiz` · `interleave`

---

## `/verify-work [N]`

Manual UAT for phase N with goal-backward verification, agent-assisted diagnosis, and fix planning.

**What it does:**
1. Shows what was built and the acceptance criteria
2. You test it manually
3. You report any issues in plain language
4. Agent diagnoses root causes and creates targeted fix plans
5. You execute fixes and re-verify

**When to use:** After `/execute-phase N` completes.

**Learning checkpoint:**
- Pass: `space` · `quiz`
- Bugs found: `learn` · `space`

---

## `/audit-milestone`

Pre-release quality gate: requirement coverage, stub detection, integration check.

**What it does:**
1. Maps every REQ-ID from `REQUIREMENTS.md` to implementation
2. Scans for stubs, placeholders, and TODO markers
3. Checks integration between phases
4. Reports coverage gaps as a prioritized list

**When to use:** Before `/complete-milestone`. Don't skip this.

---

## `/complete-milestone`

Archives the milestone, creates a git tag, and advances the project to the next cycle.

**What it does:**
1. Archives all phase artifacts to `.planning/milestones/`
2. Writes a milestone summary
3. Creates a git tag (`v[version]`)
4. Advances `STATE.md` and `AGENTS.md` to the next milestone

**When to use:** After all phases are verified and `/audit-milestone` passes.

---

## `/new-milestone [name]`

Starts a new milestone version cycle.

**What it does:**
1. Reads the completed milestone's summary
2. Asks questions about the next milestone's goals (or reads `MILESTONE-CONTEXT.md` if present)
3. Creates a new `ROADMAP.md` for the next cycle

**When to use:** After `/complete-milestone`. Run `/discuss-milestone` first for better results.

**Learning checkpoint:** `brainstorm [milestone topic]`

---

## Common patterns

```bash
# Full phase lifecycle (7-step loop)
/discuss-phase N → /plan-phase N → /execute-phase N → /verify-work N → /review → /ship → /compound

# Same loop, one command per line:
/discuss-phase N
/plan-phase N
/execute-phase N
/verify-work N
/review              # multi-persona code review (v2.0)
/ship                # test → lint → commit → push → PR (v2.0)
/compound            # capture what you learned (v2.0)

# With explicit review before executing
/discuss-phase N
/plan-phase N
/list-phase-assumptions N    # preview the plan approach before committing
/execute-phase N

# Brownfield start
/map-codebase
/new-project                  # questions focus on what you're ADDING
# normal phase lifecycle
```

See [Compounding & Quality](compounding-quality.md) for the 7 new v2.0 workflows.
