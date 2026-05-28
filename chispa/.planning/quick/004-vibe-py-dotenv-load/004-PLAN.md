# Quick Task 004: vibe.py .env loading via python-dotenv

**Task:** Completes what quick 003 should have included — vibe.py loads ANTHROPIC_API_KEY from root .env via python-dotenv instead of relying on a shell export. Add python-dotenv to requirements.txt, flesh out .env.example, update error message in vibe.py, update WORKSHOP.md code block and key-setup instructions, amend quick 003 SUMMARY.
**Date:** 2026-05-28

---

## Task 1 — Code: requirements.txt + vibe.py + .env.example

<files>
- requirements.txt
- vibe.py
- .env.example
</files>

<action>
1. requirements.txt: add `python-dotenv>=1.2.2` on a new line
2. vibe.py:
   - Add `from dotenv import load_dotenv` after `import os`
   - Add `load_dotenv()` as the first statement after imports (before the key check)
   - Update the error hint from `export ANTHROPIC_API_KEY=sk-ant-...` to:
     `cp .env.example .env  # then fill in your key`
3. .env.example: replace bare `ANTHROPIC_API_KEY=` with a commented block matching the server pattern:
   ```
   # ---------------------------------------------------------------
   # Chispa — vibe.py environment variables
   # Copy this file to .env and fill in your key:
   #   cp .env.example .env
   # .env is gitignored and never committed.
   # ---------------------------------------------------------------

   # Required — get yours at https://console.anthropic.com/
   ANTHROPIC_API_KEY=your_anthropic_api_key_here
   ```
</action>

<verify>
- `grep "python-dotenv" requirements.txt` returns a match
- `grep "load_dotenv" vibe.py` returns two lines (import + call)
- `grep "cp .env.example" vibe.py` returns a match (updated error hint)
- `grep "your_anthropic_api_key_here" .env.example` returns a match
- `pip install -r requirements.txt --dry-run` exits 0 and includes python-dotenv
</verify>

<done>
vibe.py loads .env on startup. Missing key error tells user exactly what to do.
</done>

---

## Task 2 — Docs: WORKSHOP.md + quick 003 SUMMARY

<files>
- WORKSHOP.md
- .planning/quick/003-vibe-py-requirements-txt/003-SUMMARY.md
</files>

<action>
1. WORKSHOP.md:
   a. Update pre-demo step 2b — change the pip install block to include the .env setup:
      ```
      ### 2b. Set up vibe.py
      ```bash
      pip install -r requirements.txt
      cp .env.example .env
      # Edit .env — add your ANTHROPIC_API_KEY
      ```
   b. In [3-6 min] section, update the "First time only" block to match the same cp .env.example .env pattern
   c. Update the vibe.py code block to match the new vibe.py (load_dotenv import + call, updated error hint)

2. 003-SUMMARY.md: append a note at the bottom:
   > **Note (amended by quick 004):** This task was incomplete — .env loading via python-dotenv was not included. Quick 004 completed the setup by adding python-dotenv to requirements.txt, wiring load_dotenv() into vibe.py, and updating WORKSHOP.md to use the .env.example workflow.
</action>

<verify>
- `grep "load_dotenv" WORKSHOP.md` matches in the code block
- `grep "cp .env.example .env" WORKSHOP.md` appears in both pre-demo setup and [3-6 min] section
- `grep "amended by quick 004" .planning/quick/003-vibe-py-requirements-txt/003-SUMMARY.md` returns a match
</verify>

<done>
Workshop presenter flow: pip install → cp .env.example .env → fill key → python vibe.py. Code block matches reality.
</done>
