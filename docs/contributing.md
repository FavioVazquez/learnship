---
title: Contributing
description: "How to extend learnship: add workflows, improve skills, submit PRs."
---

# Contributing

learnship is built in the open. Contributions: new workflows, skill improvements, platform support, bug fixes, and documentation: are welcome.

---

## Repository structure

```
learnship/
├── .windsurf/workflows/    # 57 workflows as slash commands (source of truth)
├── learnship/workflows/    # installed payload: must stay in sync with .windsurf/
├── .windsurf/skills/       # agentic-learning + impeccable native skills
├── agents/                 # 17 agent persona files (source of truth)
├── learnship/agents/       # installed agent payload: must stay in sync with agents/
├── learnship/skills/       # installed skills payload (agentic-learning + impeccable)
├── commands/               # Claude Code-style slash command wrappers
├── learnship/references/   # reference docs loaded by workflows
├── learnship/templates/    # document templates for .planning/ + AGENTS.md
├── tests/
│   └── run_all.sh               # full test suite (1200+ checks, 15 suites)
├── docs/                   # this documentation site (MkDocs)
├── bin/install.js          # multi-platform installer
└── install.sh              # shell installer wrapper
```

---

## Adding a new workflow

1. Create `.windsurf/workflows/[name].md` with YAML frontmatter:

    ```markdown
    ---
    description: One-line description of what this workflow does
    ---

    # Workflow Name

    [Steps...]

    ## Learning Checkpoint

    Read `learning_mode` from `.planning/config.json`.

    **If `auto`:** Offer:

    > 💡 **Learning moment:** [context-appropriate action]
    >
    > `@agentic-learning [action] [topic]`: [why this action, why now]

    **If `manual`:** Add quietly: *"Tip: `@agentic-learning [action]` to [benefit]."*
    ```

2. **Sync to installed payload:**

    ```bash
    cp .windsurf/workflows/[name].md learnship/workflows/[name].md
    ```

3. **Add to `help.md`** in both `.windsurf/workflows/` and `learnship/workflows/`.

4. **Add tests.** New workflows need at least:
    - File exists check in both locations
    - Source and installed copies are identical
    - Frontmatter description is present
    - Learning Checkpoint has both `auto` and `manual` branches

5. **Run the test suite:**

    ```bash
    bash tests/validate_multiplatform.sh
    ```

---

## Learning Checkpoint requirements

Every workflow **must** have a Learning Checkpoint at the end. Requirements verified by the test suite:

- `## Learning Checkpoint` section present
- Reads `learning_mode` from `.planning/config.json`
- Has `**If \`auto\`:**` branch with at least one `@agentic-learning` action
- Has `**If \`manual\`:**` branch with a quiet tip
- Action chosen matches the workflow context (see [Skills → Learning Partner](skills/agentic-learning.md))

---

## Syncing .windsurf/ and learnship/

The `.windsurf/workflows/` directory is the **source of truth**. `learnship/workflows/` is the installed payload that must stay in sync. The test suite checks every modified workflow for sync.

```bash
# Sync a single workflow
cp .windsurf/workflows/[name].md learnship/workflows/[name].md

# Sync all workflows
for f in .windsurf/workflows/*.md; do
  cp "$f" learnship/workflows/$(basename "$f")
done
```

---

## Versioning

learnship uses strict semver:

| Type | Bump | Examples |
|------|------|---------|
| Bug fixes, doc corrections, test additions, workflow enrichments | **PATCH** `x.x.N` | Fix a broken step, add learning actions |
| New workflows, new skills, new platforms | **MINOR** `x.N.0` | Add a new workflow file, new platform support |
| Breaking changes, major restructuring | **MAJOR** `N.0.0` | Change the planning artifact schema |

Every PR must include:
- Version bump in `package.json`
- `CHANGELOG.md` entry with date and summary
- All tests passing

---

## Running the tests

```bash
bash tests/run_all.sh
```

The suite has 15 sections covering:
- Package & installer correctness
- Workflow files structure and sync
- Skills installation
- UX entry points
- Multi-platform install (6 platforms)
- new-project workflow gates
- Cross-platform install content survival
- Regressions (config validation, Cursor .mdc, ceremony sync)
- All-workflows critical phrase survival
- Deep integrity (template resolution, cross-refs)
- Security (injection, secrets, exfiltration, Unicode, HTML, permissions)
- Learnship features (skills, learning_mode, contexts, references)
- Simulations (live node -e gate execution from 10 workflows)
- Hooks & commands (hook JS, CLI flags, upgrade safety, prompt guard)
- Platform-specific (Codex TOML, Gemini settings, tool rewrites, docs)

1200+ checks across 15 suites. All must pass before merging.

---

## PR workflow

```bash
git checkout -b feat/your-feature
# make changes
bash tests/run_all.sh    # must pass
git add -A
git commit -m "feat: [description] (vX.Y.Z)"
git push origin feat/your-feature
# open PR → label with enhancement/bug/documentation
```

---

## Credits

learnship builds on ideas and work from these open-source projects:

- **[get-shit-done](https://github.com/gsd-build/get-shit-done).** Spec-driven development with structured workflows and planning artifacts — no sprint ceremonies, just build
- **[agentic-learning](https://github.com/FavioVazquez/agentic-learning).** Neuroscience-backed learning techniques woven into the development cycle
- **[impeccable](https://github.com/pbakaus/impeccable).** Frontend design quality system with auditing and refinement actions
- **[compound-engineering](https://github.com/EveryInc/compound-engineering-plugin).** The philosophy that each unit of engineering work should make subsequent units easier — compounding knowledge through structured review and documentation
- **[superpowers](https://github.com/obra/superpowers).** Complete development workflow for coding agents with subagent-driven execution, TDD enforcement, and plan-based task dispatching
- **[gstack](https://github.com/nichochar/gstack).** Builder-first engineering system with safety guards, shipping pipelines, multi-specialist review, and the "Boil the Lake" philosophy of AI-assisted completeness
