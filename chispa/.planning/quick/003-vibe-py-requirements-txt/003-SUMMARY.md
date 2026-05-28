# Quick Task 003 Summary

**Task:** Add requirements.txt for vibe.py with latest anthropic Python SDK, update WORKSHOP.md
**Completed:** 2026-05-28

## What was done

Created `requirements.txt` at the chispa root with `anthropic>=0.104.1` (latest Python SDK as of 2026-05-28). Uses `>=` so presenters aren't blocked by minor patches. Updated WORKSHOP.md in two places: a new pre-demo step 2b ("Install vibe.py dependency") and an inline "First time only" reminder immediately before the `python vibe.py` run command in the [3-6 min] section.

## Files changed

- `requirements.txt`: new file — `anthropic>=0.104.1`
- `WORKSHOP.md`: step 2b added to pre-demo setup; pip install note added before vibe.py run command

## Commits

- `61edf9d` — feat(quick-003): requirements.txt
- `6504425` — docs(quick-003): WORKSHOP.md pip install steps
