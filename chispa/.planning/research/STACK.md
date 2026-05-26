# STACK.md — Chispa Technology Stack Research

Research conducted: 2026-05-26
Codebase scanned: Yes (existing scaffold found at /home/user/learnship/chispa)

---

## Recommended Stack

### Runtime & Package Management

**Node.js 20+** (HIGH confidence)
Use Node.js 20 LTS or later. The server package.json uses ESM (`"type": "module"`), which requires Node 18+ minimum; Node 20 is the stable LTS. Node's native `--watch` flag exists but tsx --watch is superior for TypeScript in development.

**npm workspaces** (HIGH confidence — already in use)
The project uses a root package.json with `concurrently` orchestrating `cd server && npm run dev` and `cd client && npm run dev`. This is the simplest pattern for a two-package monorepo without requiring pnpm, Turborepo, or nx. Do not add Turborepo unless build caching becomes a pain point.

---

### Backend

**Express 4.x** (HIGH confidence — already installed: `^4.19.2`)
Express 5 is released but the ecosystem (middleware types, @types/express) is still catching up. Stick with Express 4 for this project. Express handles SSE cleanly: set `Content-Type: text/event-stream`, `Cache-Control: no-cache`, `Connection: keep-alive`, write `data: {json}\n\n`, and call `res.end()` when the stream closes.

**TypeScript 5.5.x** (HIGH confidence — already installed: `^5.5.3`)
Both client and server use TypeScript 5.5. This is the correct version. Do not upgrade to 5.6+ mid-project without testing.

**tsx 4.x** (HIGH confidence — already installed: `^4.16.2`)
tsx replaces ts-node for development. The command `tsx --watch src/index.ts` provides hot reload without a separate nodemon configuration file. The existing scaffold uses nodemon calling tsx via `nodemon.json` — this works and should be kept as-is.

**cors 2.x** (HIGH confidence — already installed: `^2.8.5`)
Required because the Vite dev server runs on port 5173 and Express runs on a separate port (typically 3001). The Vite proxy (configured in `vite.config.ts`) forwards `/api` and `/stream` routes to Express, eliminating CORS issues in production — but cors middleware is still needed for direct API calls during development.

**dotenv 16.x** (HIGH confidence — already installed: `^16.4.5`)
Standard env-var loading. The ANTHROPIC_API_KEY must be in a `.env` file at the server root. Do not commit `.env`.

---

### AI Integration

**@anthropic-ai/sdk 0.98.x** (HIGH confidence)
The existing scaffold pins `^0.30.0` which is outdated. The npm registry shows the latest version is **0.98.0** (as of 2026-05-26). Upgrade is required. The SDK ships:
- `client.messages.stream()` — keeps HTTP connection alive via SSE, fires `.on("text")`, `.on("message")`, `.on("streamEvent")` callbacks
- Tool use protocol built-in, including `web_search_20250305` tool definition
- Full TypeScript types for all message and event shapes

Use `client.messages.stream()` (not `.create()`) for the agentic validation loop so tool call events can be forwarded to the frontend in real time.

**Model: claude-sonnet-4-6** (HIGH confidence)
Claude Sonnet 4.6 is the current production Sonnet model as of February 2026 (API ID: `claude-sonnet-4-6`, pricing: $3/$15 per MTok). Claude Sonnet 3.7 and Claude Sonnet 4.0 are retired. Use `claude-sonnet-4-6` as the default model string. Opus 4.7 is available but costs significantly more and is unnecessary for structured validation tasks.

**web_search_20250305 tool** (HIGH confidence)
The Anthropic web search tool was introduced September 10, 2025 and is available on Claude 3.7 Sonnet, upgraded Claude 3.5 Sonnet, and Claude 3.5 Haiku. It is also available on claude-sonnet-4-6. Pass it in the `tools` array as `{ type: "web_search_20250305" }`. Claude autonomously decides when to call it; the SDK fires a `tool_use` stream event that the backend must forward to the frontend SSE stream.

---

### Real-Time Streaming

**Server-Sent Events (SSE)** (HIGH confidence — architectural decision already made)
SSE is the correct choice over WebSockets for this use case. Reasons:
1. Unidirectional (server to client only) — matches the validation flow exactly
2. Native browser EventSource API, no client library needed
3. Automatic reconnection built into EventSource
4. Works over standard HTTP/1.1, no upgrade handshake

Critical implementation details:
- Headers: `Content-Type: text/event-stream`, `Cache-Control: no-cache`, `Connection: keep-alive`
- Each event must end with `\n\n` (double newline) — missing this silently drops events in the browser EventSource parser
- Call `res.end()` after the Anthropic stream closes, or the client hangs
- The Vite proxy must pass SSE through: set `ws: false` and do NOT buffer the response (configure `proxyReq` to not buffer)

---

### Frontend

**React 18.3.x** (HIGH confidence — already installed: `^18.3.1`)
React 19 is available but the framer-motion and recharts ecosystem has not fully caught up. React 18.3 is the safe choice for this project.

**Vite 5.3.x** (HIGH confidence — already installed: `^5.3.2`)
Vite 5 with `@vitejs/plugin-react` is the correct setup. Configure `server.proxy` in `vite.config.ts` to forward `/api` to `http://localhost:3001` so the frontend never sees CORS issues and the production build can be served by Express.

**Tailwind CSS 3.4.x** (HIGH confidence — already installed: `^3.4.4`)
Do NOT upgrade to Tailwind v4 for this project. Tailwind v4 requires `@tailwindcss/vite` plugin and has breaking changes in config, theming, and directives. Several community members report stability issues with v4 on non-trivial setups. The existing v3.4 PostCSS configuration with `autoprefixer` is stable and correct. The dark theme (`#0a0a0f` background, `#7c3aed` accent) should be extended in `tailwind.config.js` under `theme.extend.colors`.

**Framer Motion 11.x / motion package** (MEDIUM confidence — existing install: `^11.3.0`)
The Framer Motion package was rebranded to "motion" in late 2024. The npm package `framer-motion` is still maintained and at version 12.40.0 as of 2026-05-26. The existing scaffold installs `^11.3.0` which is one major version behind. The API is identical between v11 and v12; v12 introduces the `motion/react` import path from the new package name. **Recommendation**: upgrade to `framer-motion@^12` or switch to `motion` package with `import { motion } from "motion/react"`. Either works; prefer `framer-motion@^12` to keep import paths unchanged.

**Recharts 3.x** (MEDIUM confidence — existing install: `^2.12.7`)
The existing scaffold is on Recharts 2.12.7. The latest version is **3.8.1** as of 2026-05-26. Recharts 3 rewrote state management and removed the `recharts-scale` and `react-smooth` dependencies (animations are now internal). The `activeIndex` prop was removed from Scatter, Bar, and Pie charts. **Recommendation**: upgrade to `recharts@^3` for the RadarChart component (core use case for Chispa's verdict dashboard). Verify RadarChart API compatibility — RadarChart is less commonly modified in major releases. Requires React 16.8+ and TypeScript 5.x (both satisfied).

**lucide-react 0.400.x** (HIGH confidence — already installed: `^0.400.0`)
Standard icon library, tree-shakable. No changes needed.

---

### Development Tooling

**concurrently 9.x** (HIGH confidence)
The root package.json uses `concurrently@^8.2.2`. Latest version is **9.2.1**. The existing `"dev": "concurrently \"npm run dev:server\" \"npm run dev:client\""` pattern is the correct approach for a non-workspace monorepo. No changes needed beyond optional upgrade.

**nodemon 3.x** (HIGH confidence — already installed on server: `^3.1.4`)
Nodemon is used on the server alongside tsx. The combination of `nodemon` calling `tsx` via `nodemon.json` exec is a standard and stable pattern. No changes needed.

---

## Alternatives Considered

| Alternative | Why Not Used |
|---|---|
| pnpm workspaces + Turborepo | Overkill for a 2-package monorepo; adds complexity without benefit at this scale |
| WebSockets (ws / socket.io) | Bidirectional protocol adds unnecessary complexity; SSE is sufficient for server-push only |
| Vercel AI SDK (@ai-sdk/anthropic) | Adds abstraction layer between Chispa and Anthropic SDK; harder to access raw tool_use stream events needed for the live activity feed |
| Next.js | Adds SSR/routing complexity; stateless single-page app with base64 URL sharing doesn't need it |
| Tailwind CSS v4 | Breaking changes in config and directives; community reports stability issues; not worth the migration risk |
| Turborepo | No build caching benefit at this project size; adds config overhead |
| React 19 | Framer Motion and Recharts ecosystem hasn't fully validated React 19 compatibility |
| ts-node | Known ESM compatibility issues in 2025; tsx is the correct modern replacement |
| Vite-express (single-process) | Less transparent dev experience; the concurrently + Vite proxy pattern is better understood and easier to debug |
| PostgreSQL/SQLite | Project is explicitly stateless; no database needed; state is encoded in base64 URL params |

---

## What NOT to Use

**Do NOT use Tailwind v4**: Breaking config changes, `@import "tailwindcss"` syntax, removed `@tailwind` directives. The v3 PostCSS setup is stable and already configured.

**Do NOT use ts-node**: Has ESM module compatibility bugs in Node 20+. tsx is the correct replacement.

**Do NOT use WebSockets**: The one-way streaming from Claude to browser is exactly what SSE was designed for. WebSockets add bidirectional complexity with no benefit.

**Do NOT use the Vercel AI SDK** (`ai` package or `@ai-sdk/anthropic`): It abstracts away the raw stream events. Chispa needs to intercept `tool_use`, `tool_result`, and `content_block_delta` events individually to power the live activity feed. The official `@anthropic-ai/sdk` gives direct access to these.

**Do NOT commit `.env`**: The `ANTHROPIC_API_KEY` is sensitive. Add `.env` to `.gitignore` at both root and server levels.

**Do NOT use `res.write()` with raw HTTP/2 frames for SSE**: Express on Node.js handles chunked transfer automatically. Use `res.write("data: ...\n\n")` and let Express flush.

**Do NOT use React 19**: Ecosystem compatibility risk with framer-motion and recharts at this point in 2026.

---

## Versions

Pinned versions based on research (2026-05-26). Caret ranges (`^`) allow minor/patch upgrades.

### Root (package.json)

| Package | Version | Notes |
|---|---|---|
| concurrently | ^9.2.1 | Upgrade from ^8.2.2 in scaffold |

### Server (server/package.json)

| Package | Version | Notes |
|---|---|---|
| express | ^4.19.2 | Keep at 4.x; 5.x ecosystem not mature |
| @anthropic-ai/sdk | ^0.98.0 | MUST upgrade from ^0.30.0 in scaffold |
| cors | ^2.8.5 | Keep as-is |
| dotenv | ^16.4.5 | Keep as-is |
| typescript | ^5.5.3 | Keep as-is |
| tsx | ^4.16.2 | Keep as-is |
| nodemon | ^3.1.4 | Keep as-is |
| @types/express | ^4.17.21 | Keep as-is |
| @types/cors | ^2.8.17 | Keep as-is |
| @types/node | ^20.14.9 | Keep as-is |

### Client (client/package.json)

| Package | Version | Notes |
|---|---|---|
| react | ^18.3.1 | Keep at 18.x |
| react-dom | ^18.3.1 | Keep at 18.x |
| framer-motion | ^12.40.0 | Upgrade from ^11.3.0 in scaffold |
| recharts | ^3.8.1 | Upgrade from ^2.12.7 in scaffold |
| lucide-react | ^0.400.0 | Keep as-is |
| tailwindcss | ^3.4.4 | Keep at v3; do NOT upgrade to v4 |
| vite | ^5.3.2 | Keep as-is |
| @vitejs/plugin-react | ^4.3.1 | Keep as-is |
| typescript | ^5.5.3 | Keep as-is |
| postcss | ^8.4.38 | Keep as-is |
| autoprefixer | ^10.4.19 | Keep as-is |

### AI Model

| Setting | Value | Notes |
|---|---|---|
| Model ID | `claude-sonnet-4-6` | Current production Sonnet as of Feb 2026 |
| Web search tool | `web_search_20250305` | Built-in Anthropic tool, pass in `tools[]` array |
| Streaming method | `client.messages.stream()` | Not `.create()`; enables per-event callbacks |

---

## Confidence Summary

| Area | Confidence | Basis |
|---|---|---|
| Express + TypeScript + tsx setup | HIGH | Codebase scan + multiple 2025 articles |
| @anthropic-ai/sdk version (0.98.0) | HIGH | npm registry (4 days ago) |
| claude-sonnet-4-6 model ID | HIGH | Anthropic news + Wikipedia timeline |
| web_search_20250305 tool | HIGH | Anthropic official announcement (Sep 2025) + docs |
| SSE implementation pattern | HIGH | Official Claude streaming docs + DEV community articles |
| Tailwind v3 vs v4 recommendation | HIGH | Multiple migration reports + Tailwind official upgrade guide |
| Recharts 3.x breaking changes | MEDIUM | GitHub wiki + npm, no official migration article fetched |
| framer-motion v12 API compatibility | MEDIUM | npm page + motion.dev upgrade guide summary |
| concurrently 9.x | HIGH | npm registry |

---

Sources consulted:
- [Vite Getting Started](https://vite.dev/guide/)
- [Full-stack TypeScript/React Boilerplate for 2026 · vitejs/vite Discussion](https://github.com/vitejs/vite/discussions/21819)
- [Introducing web search on the Anthropic API](https://www.anthropic.com/news/web-search-api)
- [Streaming messages - Claude API Docs](https://platform.claude.com/docs/en/build-with-claude/streaming)
- [Server-Sent Events with Claude Code - DEV Community](https://dev.to/myougatheaxo/server-sent-events-with-claude-code-real-time-push-without-websocket-complexity-596l)
- [Claude API Streaming: Real-Time Patterns and SSE](https://learn-prompting.fr/blog/claude-api-streaming-guide)
- [Framer Motion + Tailwind: The 2025 Animation Stack - DEV Community](https://dev.to/manukumar07/framer-motion-tailwind-the-2025-animation-stack-1801)
- [Motion & Framer Motion upgrade guide](https://motion.dev/docs/react-upgrade-guide)
- [3.0 migration guide · recharts/recharts Wiki](https://github.com/recharts/recharts/wiki/3.0-migration-guide)
- [Tailwind 4 vs Tailwind 3: Key Differences](https://staticmania.com/blog/tailwind-v4-vs-v3-comparison)
- [A Modern Node.js + TypeScript Setup for 2025 - DEV Community](https://dev.to/woovi/a-modern-nodejs-typescript-setup-for-2025-nlk)
- [Bridging React and Node with Vite's Proxy Configuration](https://medium.com/@pavitramodi.it/bridging-react-and-node-with-vites-proxy-configuration-7281bbe23169)
- [Claude Sonnet 4.6 release - Anthropic](https://www.anthropic.com/news/claude-sonnet-4-6)
- [concurrently - npm](https://www.npmjs.com/package/concurrently)
- [@anthropic-ai/sdk - npm](https://www.npmjs.com/package/@anthropic-ai/sdk)
