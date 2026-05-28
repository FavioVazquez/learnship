# Quick Task 002 Summary

**Task:** Fix vibe.py — add clear ANTHROPIC_API_KEY missing error, update model to claude-sonnet-4-6, sync WORKSHOP.md
**Completed:** 2026-05-28

## What was done

`vibe.py` previously crashed with a raw Python traceback if `ANTHROPIC_API_KEY` wasn't set — fatal during a live demo. Added an early `os.environ.get()` check that prints a readable error and exits cleanly before the SDK is ever called. Also updated the model from `claude-opus-4-7` to `claude-sonnet-4-6` for consistency. The `vibe.py` code block in `WORKSHOP.md` was updated to be byte-for-byte identical to the actual file.

## Files changed

- `vibe.py`: `import os`, key check before client init, model updated, usage guard added
- `WORKSHOP.md`: code block synced to match fixed vibe.py

## Commits

- `0bf0105` — fix(quick-002): vibe.py key error + model
- `87cc07c` — docs(quick-002): sync WORKSHOP.md block
