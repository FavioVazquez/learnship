# Quick Task 002: Fix vibe.py — key check, model, WORKSHOP.md sync

**Task:** Add clear ANTHROPIC_API_KEY missing error to vibe.py (raw SDK traceback is fatal on stage), update model to claude-sonnet-4-6, sync the vibe.py code block in WORKSHOP.md to match.
**Date:** 2026-05-28

---

## Task 1 — Fix vibe.py

<files>
- vibe.py
</files>

<action>
1. Add `import os` at the top
2. After `import sys`, add an early exit before client creation:
   ```python
   if not os.environ.get('ANTHROPIC_API_KEY'):
       print("Error: ANTHROPIC_API_KEY not set.")
       print("  export ANTHROPIC_API_KEY=sk-ant-...")
       sys.exit(1)
   ```
3. Change `model="claude-opus-4-7"` to `model="claude-sonnet-4-6"`
4. Keep everything else identical — vibe.py is intentionally minimal (workshop contrast piece)
</action>

<verify>
- `python3 vibe.py` with no key set → prints clear error, exits 1 (not a traceback)
- `grep "sonnet-4-6" vibe.py` returns a match
- `grep "opus" vibe.py` returns nothing
</verify>

<done>
Missing key exits with a readable message. Model updated. File still intentionally minimal.
</done>

---

## Task 2 — Sync WORKSHOP.md vibe.py code block

<files>
- WORKSHOP.md
</files>

<action>
Find the vibe.py code block in WORKSHOP.md (around line 108–128) and update it to match the fixed vibe.py exactly — same `import os`, same key check, same model string.
</action>

<verify>
- `grep "sonnet-4-6" WORKSHOP.md` matches the vibe.py block
- `grep "ANTHROPIC_API_KEY" WORKSHOP.md` shows the key check in the code block
- `grep "opus" WORKSHOP.md` returns nothing
</verify>

<done>
WORKSHOP.md vibe.py block is byte-for-byte identical to what a presenter would see when running vibe.py.
</done>
