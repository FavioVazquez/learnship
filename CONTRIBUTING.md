# Contributing to learnship

How to extend learnship — add new workflows, update agent personas, add templates, and contribute improvements.

---

## Repository Structure

```
.windsurf/
├── workflows/          # slash commands — one file per workflow
└── skills/
    ├── agentic-learning/   # Learning partner skill
    └── frontend-design/    # Design system skill

agents/                 # Agent persona files
references/             # Reference documents
templates/              # Document templates for .planning/ artifacts
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
- **No `AskUserQuestion` tool** — use plain prose to ask questions. The agent handles the conversation.
- **No `Task()` spawning syntax** — describe parallel work as "run these agents in parallel" in prose.
- **Learning checkpoints** — include at natural completion points where reflection adds value.

### 5. Agent persona reference

Workflows that adopt a specific role should reference the relevant persona:

```markdown
Using `@./agents/planner.md` as your planning persona, create...
Using `@./agents/researcher.md` in phase research mode, investigate...
```

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

Agent personas live in `agents/`. Each is a Markdown file that defines a role's responsibilities, inputs, outputs, and quality standards.

### Structure

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

### Naming

`agents/[role].md` — lowercase, single word or hyphenated.

Current personas: `planner.md`, `researcher.md`, `executor.md`, `verifier.md`, `debugger.md`.

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

## Testing a Workflow

To test a workflow:

1. Install locally: `npx . --windsurf --local` (or `--claude`, `--opencode`, etc.)
2. Open a test project in your target platform
3. Run `/your-workflow` (Windsurf) or the equivalent command
4. Walk through all steps, including error paths
5. Verify bash commands produce expected output
6. Verify the learning checkpoint fires correctly when `learning_mode: "auto"`

---

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

- **Platform-native** — workflows should feel natural in the target agent, not like ported scripts
- **Learning-integrated** — any significant workflow should have a learning checkpoint
- **Minimal prose** — workflow steps should be clear and scannable, not essays
- **Goal-backward** — every step should serve the workflow's stated goal
- **Atomic commits** — one logical change per commit
