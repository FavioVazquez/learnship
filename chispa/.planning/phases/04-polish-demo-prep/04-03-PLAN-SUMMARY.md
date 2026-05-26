# Plan 03 Summary

**Completed:** 2026-05-26

## What was built
Fixed the production server to correctly serve the React SPA. Two bugs fixed:
1. `express.static` path now uses `process.cwd()` instead of `__dirname` — stable regardless of compilation depth
2. Catch-all now serves `index.html` for non-API routes (SPA routing) instead of returning JSON 404 everywhere

Discovered and fixed an additional bug: `server/package.json` start script pointed to `dist/src/index.js` but compiled output lands at `dist/index.js` (rootDir:src strips the prefix). Fixed to `node dist/index.js`.

## Key files
- server/src/index.ts: process.cwd() paths for static + SPA catch-all
- server/package.json: corrected start script from dist/src/index.js to dist/index.js

## Decisions made
- Used `process.cwd()` over `__dirname` — process.cwd() is always `chispa/server/` when started via npm start, regardless of where compiled JS lives

## Notes for downstream
- Production build verified: all 4 curl cases pass
- Plan 04 (final polish) can proceed
