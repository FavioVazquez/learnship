# Contributing to learnship

How to extend learnship — add new workflows, update agent personas, add templates, and contribute improvements.

---

## Repository Structure

```
learnship/
├── workflows/          # 57 source workflow files (the actual instructions)
├── agents/             # 17 source agent personas (inline format, no frontmatter)
├── references/         # Reference docs loaded by workflows
├── templates/          # Document templates for .planning/ artifacts
└── skills/             # Skills payload (agentic-learning + impeccable)

agents/                 # 17 published agent personas (with GSD-style frontmatter)
.windsurf/
├── workflows/          # Synced copy for Windsurf (with tool name conversions)
├── rules/              # 17 model_decision rules (agent personas for Windsurf)
└── skills/             # Native skills for Windsurf

commands/               # 57 Claude Code slash command wrappers
bin/install.js          # Multi-platform installer (6 platforms)
cursor-rules/           # Cursor .mdc rules
hooks/                  # Session hooks (Claude Code + Gemini CLI)
tests/                  # 511+ checks across 5 test suites
```

---

## Adding a New Workflow

### 1. Create the workflow file

Every workflow is a Markdown file in `.windsurf/workflows/`. The filename becomes the slash command.

```
.windsurf/workflows/my-workflow.md  →  /my-workflow
```

### 2. Required frontmatter

Every workflow must start with YAML frontmatter:

```markdown
---
description: One sentence explaining what this workflow does and when to use it
---
```

The `description` field appears in `/help` and in the agent's command palette.

### 3. Workflow structure

Follow this structure:

```markdown
---
description: [one sentence]
---

# Workflow Name

[2-3 sentence explanation of what this does, when to use it, and any prerequisites]

**Usage:** `workflow-name [arguments]`

## Step 1: [Step Name]

[Clear instructions. Use bash blocks for commands. Use prose for agent actions.]

## Step 2: [Step Name]

...

## Step N: Confirm

[What to display when done. Include ▶ Next: [workflow] to suggest the next step.]

---

## Learning Checkpoint

Read `learning_mode` from `.planning/config.json`.

**If `auto`:** Offer:

> 💡 **Learning moment:** [context]
>
> `@agentic-learning [action]` — [what it does here]
```

### 4. Workflow rules

- **No binary calls** — use bash and git commands directly, never external binaries.
- **Relative paths only** — reference platform files as `@./agents/planner.md`, not absolute paths.
- **Platform-native tool names** — use `AskUserQuestion` for interactive questions (install.js rewrites per platform). Use `Task()` for parallel subagent spawning. Both require parallelization checks.
- **Inline `<persona_context>` blocks** — every workflow that references an agent persona must include a `<persona_context>` block with core behavior instructions inline, so it works on all platforms.
- **Learning checkpoints** — include at natural completion points where reflection adds value.

### 5. Agent persona reference

Workflows that adopt a specific role use three layers:

```markdown
<!-- Layer 1: Inline persona context (works everywhere) -->
<persona_context>
You are now the **learnship researcher**. Your training data is stale — verify before asserting.
Use WebSearch for ecosystem discovery, WebFetch for official docs.
Tag confidence: HIGH/MEDIUM/LOW.
</persona_context>

<!-- Layer 2: File reference (Claude Code, OpenCode, etc.) -->
Read `@./agents/researcher.md` for the full persona definition.

<!-- Layer 3: Parallel path (platforms with Task() support) -->
If parallelization enabled: spawn dedicated researcher subagent via Task().
```

On Windsurf, `model_decision` rules in `.windsurf/rules/` provide native persona adoption — Cascade reads the matching rule when it encounters the persona name.

### 6. bash command style

Prefer simple bash over complex scripts:

```bash
# Good — readable and direct
test -f .planning/ROADMAP.md && echo "exists" || echo "missing"

# Good — explicit
git add .planning/STATE.md
git commit -m "docs: update state"

# Avoid — overly complex one-liners
```

---

## Adding an Agent Persona

Agent personas exist in **two locations** that must stay in sync:

1. **`learnship/agents/[role].md`** — source inline persona (no frontmatter). Used as `@./agents/` references in workflows.
2. **`agents/learnship-[role].md`** — published agent with GSD-style frontmatter (`name:`, `description:`, `tools:`, `color:`). Used by `install.js` for platform-specific installation.

### Source persona structure (`learnship/agents/`)

```markdown
# [Role] Agent

You are the [role]. Your job is to [core responsibility in one sentence].

## Core Responsibility

[2-3 sentences expanding on the role]

## What You Read First

[List of files to read before starting]

## [Main behavior sections]

...

## Output Format / Quality Standards

[What the output looks like, quality gates]
```

### Published persona structure (`agents/`)

```markdown
---
name: learnship-[role]
description: [One sentence for platform dispatch and Windsurf rule descriptions]
tools: Read, Bash, Glob, Grep
color: [blue|green|purple|orange|red]
---

<role>
[Full persona content — same as source but wrapped in <role> tags]
</role>
```

### Naming

- Source: `learnship/agents/[role].md` — lowercase, hyphenated
- Published: `agents/learnship-[role].md` — prefixed with `learnship-`

### After adding a new persona

1. Create both source and published versions
2. Add a `<persona_context>` block to every workflow that uses the persona
3. Add the persona to `WINDSURF_RULE_DESCRIPTIONS` in `bin/install.js`
4. Add a Codex sandbox entry in `CODEX_AGENT_SANDBOX_MAP` in `bin/install.js`
5. Sync `.windsurf/rules/` and `.windsurf/workflows/` by running the install
6. Update tests in `tests/validate_multiplatform.sh`

### Current personas (17)

`planner`, `researcher`, `project-researcher`, `research-synthesizer`, `phase-researcher`, `roadmapper`, `executor`, `verifier`, `debugger`, `plan-checker`, `solution-writer`, `code-reviewer`, `challenger`, `ideation-agent`, `security-auditor`, `doc-writer`, `doc-verifier`.

---

## Adding a Reference File

Reference files in `references/` provide domain knowledge that workflows and agents load for context.

```markdown
# [Topic] Reference

[Brief intro — what this is, when to read it]

---

## [Section]

[Content]
```

Reference files are linked from workflow steps:
```markdown
Read `@./references/verification-patterns.md` before verifying.
```

---

## Adding a Template

Templates in `templates/` are canonical source files for documents that workflows create in `.planning/`.

Templates use `[placeholder]` syntax for fields to fill in:

```markdown
---
phase: [N]
created: [YYYY-MM-DD]
---

# [Title]

[Content with [placeholder] fields]
```

Templates are copied by workflows:
```bash
cp templates/context.md ".planning/phases/[phase-dir]/[padded_phase]-CONTEXT.md"
```

---

## Updating a Skill

Skills live in `.windsurf/skills/`. Each skill has a `SKILL.md` (the main skill file) and optional `references/` or `reference/` subdirectory.

To update a skill:
1. Modify the relevant `SKILL.md` or reference file
2. Test by verifying Cascade loads the updated context
3. Update `CHANGELOG.md` with what changed

---

## Testing

### Manual testing

1. Install locally: `npx . --windsurf --local` (or `--claude`, `--opencode`, `--gemini`, `--codex`)
2. Open a test project in your target platform
3. Run `/your-workflow` (Windsurf) or the equivalent command
4. Walk through all steps, including error paths
5. Verify bash commands produce expected output
6. Verify the learning checkpoint fires correctly when `learning_mode: "auto"`

### Automated testing

```bash
bash tests/run_all.sh
```

511+ checks across 5 suites. All must pass before merging. The suite validates:
- Workflow content integrity and frontmatter
- Cross-platform install.js output for all 6 platforms
- Cursor .mdc rules correctness
- SKILL.md enforcement content
- Session-start hooks and agent persona coverage

---

## Commit Style

Follow the existing commit convention:

```
feat(workflows): add [workflow-name] workflow
feat(agents): add [role] agent persona
docs(references): add [topic] reference
fix(workflows): fix [workflow-name] [brief description]
chore: update CHANGELOG for v[X.Y]
```

---

## Platform Philosophy

Keep these principles when contributing:

- **Platform-native** — workflows should feel natural in the target agent, not like ported scripts. install.js handles tool name rewriting per platform automatically.
- **Cross-platform by default** — use inline `<persona_context>` blocks so persona adoption works on all 6 platforms, even those without `Task()` or `model_decision` rules.
- **Learning-integrated** — any significant workflow should have a learning checkpoint
- **Minimal prose** — workflow steps should be clear and scannable, not essays
- **Goal-backward** — every step should serve the workflow's stated goal
- **Atomic commits** — one logical change per commit
- **Test before merge** — `bash tests/run_all.sh` must pass with 0 failures
