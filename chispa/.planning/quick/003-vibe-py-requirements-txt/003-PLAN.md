# Quick Task 003: Add requirements.txt for vibe.py

**Task:** Create requirements.txt with latest anthropic Python SDK (0.104.1), update WORKSHOP.md pre-demo setup and vibe.py run section to include pip install step.
**Date:** 2026-05-28

---

## Task 1 — Create requirements.txt

<files>
- requirements.txt (new file in chispa/ root, alongside vibe.py)
</files>

<action>
Create requirements.txt with a single pinned dependency:
  anthropic>=0.104.1
Use >= not == so presenters aren't blocked by minor patch releases, but
still get a minimum that guarantees the model and tool types used in vibe.py.
</action>

<verify>
- File exists at chispa/requirements.txt
- Contains anthropic>=0.104.1
- `pip install -r requirements.txt --dry-run` exits 0
</verify>

<done>
requirements.txt exists and pip accepts it.
</done>

---

## Task 2 — Update WORKSHOP.md

<files>
- WORKSHOP.md
</files>

<action>
Two changes:

1. In Pre-Demo Setup, add a new step (between "Install learnship globally" and "Test Claude Code is authenticated") for the Python dependency:
   ```
   ### 2b. Install vibe.py dependency
   ```bash
   pip install -r requirements.txt
   ```
   (requires Python 3.8+ and pip)
   ```

2. In [3-6 min] section, just before the "Run it:" bash block, add:
   ```
   First time only:
   ```bash
   pip install -r requirements.txt
   ```
   ```
</action>

<verify>
- `grep "pip install" WORKSHOP.md` shows both spots
- `grep "requirements.txt" WORKSHOP.md` returns matches
</verify>

<done>
Presenter knows to install before both pre-demo setup and the vibe.py demo moment.
</done>
