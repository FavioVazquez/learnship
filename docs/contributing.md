---
title: Contributing
description: How to extend learnship — add workflows, improve skills, submit PRs.
---

# Contributing

learnship is built in the open. Contributions — new workflows, skill improvements, platform support, bug fixes, and documentation — are welcome.

---

## Repository structure

```
learnship/
├── .windsurf/workflows/    # 42 workflows as slash commands (source of truth)
├── learnship/workflows/    # installed payload — must stay in sync with .windsurf/
├── .windsurf/skills/       # agentic-learning + impeccable native skills
├── agents/                 # 6+ agent persona files
├── commands/               # Claude Code-style slash command wrappers
├── learnship/references/   # reference docs loaded by workflows
├── learnship/templates/    # document templates for .planning/ + AGENTS.md
├── tests/
│   └── validate_multiplatform.sh  # full test suite (146+ checks)
├── docs/                   # this documentation site (MkDocs)
├── generate_images.py      # brand image generator (Gemini)
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
    > `@agentic-learning [action] [topic]` — [why this action, why now]

    **If `manual`:** Add quietly: *"Tip: `@agentic-learning [action]` to [benefit]."*
    ```

2. **Sync to installed payload:**

    ```bash
    cp .windsurf/workflows/[name].md learnship/workflows/[name].md
    ```

3. **Add to `help.md`** in both `.windsurf/workflows/` and `learnship/workflows/`.

4. **Add tests** — new workflows need at least:
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
bash tests/validate_multiplatform.sh
```

The suite has 13 sections covering:
- Installer correctness across all 5 platforms
- Workflow structure and sync
- Skills installation
- Learning Checkpoint coverage
- Documentation site integrity

146+ checks. All must pass before merging.

---

## PR workflow

```bash
git checkout -b feat/your-feature
# make changes
bash tests/validate_multiplatform.sh    # must pass
git add -A
git commit -m "feat: [description] (vX.Y.Z)"
git push origin feat/your-feature
# open PR → label with enhancement/bug/documentation
```

---

## Generating brand images

```bash
# List available images
python generate_images.py --list

# Generate a specific image
python generate_images.py --only [key]

# Generate all 16 images
python generate_images.py

# Requirements
pip install google-genai python-dotenv
# GOOGLE_CLOUD_API_KEY in .env
```

Images are saved to `assets/` and referenced in docs and the README.

---

## Credits

learnship builds on:

- **[get-shit-done](https://github.com/davila7/get-shit-done)** — spec-driven workflow and planning artifact patterns
- **[agentic-learn](https://github.com/faviovazquez/agentic-learn)** — neuroscience-backed learning techniques
- **[impeccable](https://github.com/pbakaus/impeccable)** — frontend design quality system
