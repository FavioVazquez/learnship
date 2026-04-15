#!/usr/bin/env node

/**
 * learnship multi-platform installer
 *
 * Installs learnship workflows, agents, and commands for:
 *   --windsurf   ~/.codeium/windsurf/workflows/  (Windsurf — same as install.sh)
 *   --claude     ~/.claude/                       (Claude Code)
 *   --opencode   ~/.config/opencode/              (OpenCode)
 *   --gemini     ~/.gemini/                       (Gemini CLI)
 *   --codex      ~/.codex/                        (Codex CLI / OpenAI Codex)
 *   --all        All platforms
 *
 * Usage:
 *   npx learnship                     Interactive install
 *   npx learnship --claude --global   Claude Code, global
 *   npx learnship --all --global      All platforms, global
 *   npx learnship --claude --global --uninstall  Remove Claude Code files
 */

'use strict';

const fs = require('fs');
const path = require('path');
const os = require('os');
const readline = require('readline');

const pkg = require('../package.json');

// Codex config.toml marker — used to identify learnship-managed section
const LEARNSHIP_CODEX_MARKER = '# learnship Agent Configuration — managed by learnship installer';

// Per-agent Codex sandbox modes (read-only for checkers, workspace-write for executors)
const CODEX_AGENT_SANDBOX = {
  'learnship-executor':          'workspace-write',
  'learnship-planner':           'workspace-write',
  'learnship-phase-researcher':  'workspace-write',
  'learnship-verifier':          'workspace-write',
  'learnship-debugger':          'workspace-write',
  'learnship-plan-checker':      'read-only',
  'learnship-solution-writer':   'workspace-write',
  'learnship-code-reviewer':     'read-only',
  'learnship-challenger':        'read-only',
  'learnship-ideation-agent':    'read-only',
  'learnship-security-auditor':  'read-only',
  'learnship-doc-writer':        'workspace-write',
};

// ─── Colors ────────────────────────────────────────────────────────────────
const cyan   = '\x1b[36m';
const purple = '\x1b[38;5;135m';
const green  = '\x1b[32m';
const yellow = '\x1b[33m';
const dim    = '\x1b[2m';
const reset  = '\x1b[0m';

// ─── Argument parsing ──────────────────────────────────────────────────────
const args = process.argv.slice(2);
const hasWindsurf  = args.includes('--windsurf');
const hasClaude    = args.includes('--claude');
const hasOpencode  = args.includes('--opencode');
const hasGemini    = args.includes('--gemini');
const hasCodex     = args.includes('--codex');
const hasCursor    = args.includes('--cursor');
const hasAll       = args.includes('--all');
const hasGlobal    = args.includes('--global') || args.includes('-g');
const hasLocal     = args.includes('--local')  || args.includes('-l');
const hasUninstall = args.includes('--uninstall') || args.includes('-u');
const hasHelp      = args.includes('--help') || args.includes('-h');
const targetIdx    = args.indexOf('--target');
const targetOverride = targetIdx !== -1 && args[targetIdx + 1] ? path.resolve(args[targetIdx + 1]) : null;

let selectedPlatforms = [];
if (hasAll) {
  selectedPlatforms = ['windsurf', 'claude', 'opencode', 'gemini', 'codex'];
} else {
  if (hasWindsurf) selectedPlatforms.push('windsurf');
  if (hasClaude)   selectedPlatforms.push('claude');
  if (hasOpencode) selectedPlatforms.push('opencode');
  if (hasGemini)   selectedPlatforms.push('gemini');
  if (hasCodex)    selectedPlatforms.push('codex');
  if (hasCursor)   selectedPlatforms.push('cursor');
}

// ─── Banner ────────────────────────────────────────────────────────────────
const banner = `
${purple}  ██╗     ███████╗ █████╗ ██████╗ ███╗   ██╗███████╗██╗  ██╗██╗██████╗
  ██║     ██╔════╝██╔══██╗██╔══██╗████╗  ██║██╔════╝██║  ██║██║██╔══██╗
  ██║     █████╗  ███████║██████╔╝██╔██╗ ██║███████╗███████║██║██████╔╝
  ██║     ██╔══╝  ██╔══██║██╔══██╗██║╚██╗██║╚════██║██╔══██║██║██╔═══╝
  ███████╗███████╗██║  ██║██║  ██║██║ ╚████║███████║██║  ██║██║██║
  ╚══════╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝╚═╝╚═╝${reset}

  ${dim}Learn as you build. Build with intent.${reset}
  ${dim}v${pkg.version} · Windsurf · Claude Code · OpenCode · Gemini CLI · Codex CLI · Cursor${reset}
`;

// ─── Help text ─────────────────────────────────────────────────────────────
const helpText = `
  ${yellow}Usage:${reset} npx learnship [platform] [scope] [options]

  ${yellow}Platforms:${reset}
    ${cyan}--windsurf${reset}    Windsurf (same as install.sh)
    ${cyan}--claude${reset}      Claude Code  (~/.claude/)
    ${cyan}--opencode${reset}    OpenCode     (~/.config/opencode/)
    ${cyan}--gemini${reset}      Gemini CLI   (~/.gemini/)
    ${cyan}--codex${reset}       Codex CLI    (~/.codex/)
    ${cyan}--all${reset}         All platforms (excludes Cursor — use marketplace)
    ${cyan}--cursor${reset}      Show Cursor install instructions

  ${yellow}Scope:${reset}
    ${cyan}-g, --global${reset}  Install to global config directory (recommended)
    ${cyan}-l, --local${reset}   Install to current project directory

  ${yellow}Options:${reset}
    ${cyan}--target <dir>${reset}   Install to a custom directory instead of the platform default
    ${cyan}-u, --uninstall${reset}  Remove learnship files
    ${cyan}-h, --help${reset}       Show this help

  ${yellow}Examples:${reset}
    ${dim}# Interactive install (prompts for platform and scope)${reset}
    npx learnship

    ${dim}# Install for Claude Code globally${reset}
    npx learnship --claude --global

    ${dim}# Install for all platforms globally${reset}
    npx learnship --all --global

    ${dim}# Install for Gemini CLI globally${reset}
    npx learnship --gemini --global

    ${dim}# Install for Codex globally${reset}
    npx learnship --codex --global

    ${dim}# Uninstall from OpenCode${reset}
    npx learnship --opencode --global --uninstall

    ${dim}# Install to current project only${reset}
    npx learnship --claude --local
`;

// ─── Path helpers ──────────────────────────────────────────────────────────
function expandTilde(p) {
  if (p && p.startsWith('~/')) return path.join(os.homedir(), p.slice(2));
  return p;
}

function getDirName(platform) {
  if (platform === 'opencode') return '.opencode';
  if (platform === 'gemini')   return '.gemini';
  if (platform === 'codex')    return '.codex';
  if (platform === 'windsurf') return '.windsurf';
  return '.claude';
}

function getGlobalDir(platform) {
  switch (platform) {
    case 'opencode': {
      if (process.env.OPENCODE_CONFIG_DIR) return expandTilde(process.env.OPENCODE_CONFIG_DIR);
      if (process.env.XDG_CONFIG_HOME)     return path.join(expandTilde(process.env.XDG_CONFIG_HOME), 'opencode');
      return path.join(os.homedir(), '.config', 'opencode');
    }
    case 'gemini': {
      if (process.env.GEMINI_CONFIG_DIR) return expandTilde(process.env.GEMINI_CONFIG_DIR);
      return path.join(os.homedir(), '.gemini');
    }
    case 'codex': {
      if (process.env.CODEX_HOME) return expandTilde(process.env.CODEX_HOME);
      return path.join(os.homedir(), '.codex');
    }
    case 'windsurf': {
      return path.join(os.homedir(), '.codeium', 'windsurf');
    }
    default: { // claude
      if (process.env.CLAUDE_CONFIG_DIR) return expandTilde(process.env.CLAUDE_CONFIG_DIR);
      return path.join(os.homedir(), '.claude');
    }
  }
}

function getPlatformLabel(platform) {
  const labels = {
    windsurf: 'Windsurf', claude: 'Claude Code',
    opencode: 'OpenCode', gemini: 'Gemini CLI', codex: 'Codex CLI',
  };
  return labels[platform] || platform;
}

// ─── File helpers ──────────────────────────────────────────────────────────
function readSettings(p) {
  if (!fs.existsSync(p)) return {};
  try { return JSON.parse(fs.readFileSync(p, 'utf8')); } catch { return {}; }
}
function writeSettings(p, obj) {
  fs.writeFileSync(p, JSON.stringify(obj, null, 2) + '\n');
}

// ─── Path helpers (extended) ───────────────────────────────────────────────

/**
 * Convert an absolute pathPrefix to $HOME-relative form for bash code blocks.
 * Keeps $HOME as a shell variable so paths remain portable across machines.
 */
function toHomePrefix(pathPrefix) {
  const home = os.homedir().replace(/\\/g, '/');
  const normalized = pathPrefix.replace(/\\/g, '/');
  if (normalized.startsWith(home)) return '$HOME' + normalized.slice(home.length);
  return normalized;
}

// ─── Frontmatter conversion ────────────────────────────────────────────────

// Color name → hex for OpenCode (color names not supported)
const colorNameToHex = {
  cyan: '#00FFFF', red: '#FF0000', green: '#00FF00', blue: '#0000FF',
  yellow: '#FFFF00', magenta: '#FF00FF', orange: '#FFA500', purple: '#800080',
  pink: '#FFC0CB', white: '#FFFFFF', black: '#000000', gray: '#808080', grey: '#808080',
};

/** Convert Claude Code tool name → OpenCode tool name */
function toOpencodeToolName(t) {
  const map = { AskUserQuestion: 'question', SlashCommand: 'skill', TodoWrite: 'todowrite',
                WebFetch: 'webfetch', WebSearch: 'websearch' };
  return map[t] || t.toLowerCase();
}

/** Convert Claude Code tool name → Gemini CLI tool name (snake_case) */
function toGeminiToolName(t) {
  if (t.startsWith('mcp__') || t === 'Task') return null; // auto-discovered
  const map = { Read: 'read_file', Write: 'write_file', Edit: 'replace',
                Bash: 'run_shell_command', Glob: 'glob', Grep: 'search_file_content',
                WebSearch: 'google_web_search', WebFetch: 'web_fetch',
                TodoWrite: 'write_todos', AskUserQuestion: 'ask_user' };
  return map[t] || t.toLowerCase();
}

/** Parse YAML frontmatter from a .md file. Returns { frontmatter, body }. */
function parseFrontmatter(content) {
  if (!content.startsWith('---')) return { frontmatter: null, body: content };
  const end = content.indexOf('---', 3);
  if (end === -1) return { frontmatter: null, body: content };
  return { frontmatter: content.substring(3, end).trim(), body: content.substring(end + 3) };
}

function getFrontmatterField(fm, field) {
  const m = fm.match(new RegExp(`^${field}:\\s*(.+)$`, 'm'));
  return m ? m[1].trim().replace(/^['"]|['"]$/g, '') : null;
}

/**
 * Convert Claude Code command/agent .md → OpenCode format
 * - allowed-tools array → tools object (tool: true)
 * - name: field removed (OpenCode uses filename for commands)
 * - color: name → hex (OpenCode requires hex)
 * - /learnship:cmd → /learnship-cmd
 * - subagent_type="general-purpose" → subagent_type="general"
 * - ~/.claude/ → ~/.config/opencode/
 */
function convertToOpencode(content) {
  let c = content
    .replace(/\/learnship:/g, '/learnship-')
    .replace(/~\/\.claude\//g, '~/.config/opencode/')
    .replace(/\$HOME\/\.claude\//g, '$HOME/.config/opencode/')
    .replace(/\bAskUserQuestion\b/g, 'question')
    .replace(/\bWebSearch\b/g, 'websearch')
    .replace(/\bWebFetch\b/g, 'webfetch')
    .replace(/\bSlashCommand\b/g, 'skill')
    .replace(/\bTodoWrite\b/g, 'todowrite')
    .replace(/subagent_type="general-purpose"/g, 'subagent_type="general"');

  const { frontmatter, body } = parseFrontmatter(c);
  if (!frontmatter) return c;

  const lines = frontmatter.split('\n');
  const newLines = [];
  let inTools = false;
  const tools = [];

  for (const line of lines) {
    const t = line.trim();
    if (t.startsWith('name:')) continue; // OpenCode uses filename for command name
    if (t.startsWith('allowed-tools:')) { inTools = true; continue; }
    // Handle inline tools: field (comma-separated string, e.g. agents use 'tools: Read, Write')
    if (t.startsWith('tools:')) {
      const toolsValue = t.substring(6).trim();
      if (toolsValue) {
        // Inline comma-separated: tools: Read, Write, Bash
        for (const tool of toolsValue.split(',').map(s => s.trim()).filter(Boolean)) {
          tools.push(tool);
        }
      } else {
        // YAML array follows
        inTools = true;
      }
      continue;
    }
    // Convert color names to hex
    if (t.startsWith('color:')) {
      const colorVal = t.substring(6).trim().toLowerCase();
      const hex = colorNameToHex[colorVal];
      if (hex) { newLines.push(`color: "${hex}"`); }
      else if (colorVal.startsWith('#')) { newLines.push(line); }
      // skip unknown color names entirely
      continue;
    }
    if (inTools) {
      if (t.startsWith('- ')) { tools.push(t.slice(2).trim()); continue; }
      if (t && !t.startsWith('-')) inTools = false;
    }
    if (!inTools) newLines.push(line);
  }
  if (tools.length > 0) {
    newLines.push('tools:');
    for (const tool of tools) newLines.push(`  ${toOpencodeToolName(tool)}: true`);
  }
  return `---\n${newLines.join('\n').trim()}\n---${body}`;
}

/**
 * Convert Claude Code command .md → Gemini CLI .toml
 * Gemini uses TOML: description = "..." and prompt = "..."
 */
function convertToGeminiToml(content) {
  const { frontmatter, body } = parseFrontmatter(content);
  // Strip <sub> tags — terminals can't render them
  const cleanBody = (body || content).replace(/<sub>(.*?)<\/sub>/g, '*($1)*').trim();
  let desc = '';
  if (frontmatter) {
    const d = getFrontmatterField(frontmatter, 'description');
    if (d) desc = d;
  }
  let toml = '';
  if (desc) toml += `description = ${JSON.stringify(desc)}\n`;
  // Escape ${VAR} → $VAR (Gemini treats ${word} as template variables)
  const escapedBody = cleanBody.replace(/\$\{(\w+)\}/g, '$$$1');
  toml += `prompt = ${JSON.stringify(escapedBody)}\n`;
  return toml;
}

/**
 * Convert Claude Code command .md → Codex skill SKILL.md
 * - /learnship:cmd → $learnship-cmd
 * - $ARGUMENTS → {{LEARNSHIP_ARGS}}
 * - AskUserQuestion → request_user_input
 * - Adds full <codex_skill_adapter> header (matching GSD's detail level)
 */
function convertToCodexSkill(content, skillName) {
  let c = content
    .replace(/\/learnship:([a-z0-9-]+)/gi, '$learnship-$1')
    .replace(/\$ARGUMENTS\b/g, '{{LEARNSHIP_ARGS}}')
    .replace(/\/learnship-help\b/g, '$learnship-help');

  const { frontmatter, body } = parseFrontmatter(c);
  let description = `Run learnship workflow ${skillName}.`;
  if (frontmatter) {
    const d = getFrontmatterField(frontmatter, 'description');
    if (d) description = d.replace(/\s+/g, ' ').trim();
  }
  const shortDesc = description.length > 180 ? description.slice(0, 177) + '...' : description;
  const invocation = `$${skillName}`;

  const adapter = `<codex_skill_adapter>
## A. Skill Invocation
- This skill is invoked by mentioning \`${invocation}\`.
- Treat all user text after \`${invocation}\` as \`{{LEARNSHIP_ARGS}}\`.
- If no arguments are present, treat \`{{LEARNSHIP_ARGS}}\` as empty.

## B. AskUserQuestion → request_user_input Mapping
learnship workflows use \`AskUserQuestion\` (Claude Code syntax). Translate to Codex \`request_user_input\`:

Parameter mapping:
- \`header\` → \`header\`
- \`question\` → \`question\`
- Options formatted as \`"Label" — description\` → \`{label: "Label", description: "description"}\`
- Generate \`id\` from header: lowercase, replace spaces with underscores

Multi-select workaround:
- Codex has no \`multiSelect\`. Use sequential single-selects, or present a numbered freeform list.

Execute mode fallback:
- When \`request_user_input\` is rejected, present a plain-text numbered list and pick a reasonable default.

## C. Task() → spawn_agent Mapping
learnship workflows use \`Task(...)\` (Claude Code syntax). Translate to Codex collaboration tools:

Direct mapping:
- \`Task(subagent_type="X", prompt="Y")\` → \`spawn_agent(agent_type="X", message="Y")\`
- \`Task(model="...")\` → omit (Codex uses per-role config)
- \`fork_context: false\` by default — learnship agents load their own context via \`<files_to_read>\` blocks

Parallel fan-out:
- Spawn multiple agents → collect agent IDs → \`wait(ids)\` for all to complete

Result parsing:
- Look for structured markers: \`CHECKPOINT\`, \`PLAN COMPLETE\`, \`SUMMARY\`, etc.
- \`close_agent(id)\` after collecting results from each agent
</codex_skill_adapter>`;

  return `---\nname: ${JSON.stringify(skillName)}\ndescription: ${JSON.stringify(description)}\nmetadata:\n  short-description: ${JSON.stringify(shortDesc)}\n---\n\n${adapter}\n\n${body.trimStart()}`;
}

/**
 * Convert Claude Code agent .md to Codex agent format.
 * Adds <codex_agent_role> header, cleans frontmatter (removes tools/color).
 */
function convertClaudeAgentToCodexAgent(content) {
  // Apply base Codex markdown conversions first
  let c = content
    .replace(/\/learnship:([a-z0-9-]+)/gi, '$learnship-$1')
    .replace(/\$ARGUMENTS\b/g, '{{LEARNSHIP_ARGS}}');

  const { frontmatter, body } = parseFrontmatter(c);
  if (!frontmatter) return c;

  const name = getFrontmatterField(frontmatter, 'name') || 'unknown';
  const description = (getFrontmatterField(frontmatter, 'description') || '').replace(/\s+/g, ' ').trim();
  const tools = getFrontmatterField(frontmatter, 'tools') || '';

  const roleHeader = `<codex_agent_role>\nrole: ${name}\ntools: ${tools}\npurpose: ${description}\n</codex_agent_role>`;
  const cleanFrontmatter = `---\nname: ${JSON.stringify(name)}\ndescription: ${JSON.stringify(description)}\n---`;

  return `${cleanFrontmatter}\n\n${roleHeader}\n${body}`;
}

/**
 * Convert agent .md for Gemini CLI
 * - allowed-tools array → tools YAML array with snake_case names
 * - color: removed (causes validation error in Gemini)
 * - Task: excluded (agents auto-registered as tools in Gemini)
 * - ${VAR} → $VAR in body (Gemini template engine would misparse ${WORD})
 */
function convertAgentForGemini(content) {
  if (!content.startsWith('---')) return content;
  const end = content.indexOf('---', 3);
  if (end === -1) return content;
  const frontmatter = content.substring(3, end).trim();
  const body = content.substring(end + 3);

  const lines = frontmatter.split('\n');
  const newLines = [];
  let inTools = false;
  const tools = [];

  for (const line of lines) {
    const t = line.trim();
    if (t.startsWith('color:')) continue; // Gemini rejects color field
    if (t.startsWith('allowed-tools:')) { inTools = true; continue; }
    // Handle inline tools: field (comma-separated, used by agent frontmatter)
    if (t.startsWith('tools:')) {
      const toolsValue = t.substring(6).trim();
      if (toolsValue) {
        // Inline: tools: Read, Write, Bash
        for (const tool of toolsValue.split(',').map(s => s.trim()).filter(Boolean)) {
          const mapped = toGeminiToolName(tool);
          if (mapped) tools.push(mapped);
        }
      } else {
        // YAML array follows
        inTools = true;
      }
      continue;
    }
    if (inTools) {
      if (t.startsWith('- ')) {
        const mapped = toGeminiToolName(t.slice(2).trim());
        if (mapped) tools.push(mapped);
        continue;
      }
      if (t && !t.startsWith('-')) inTools = false;
    }
    if (!inTools) newLines.push(line);
  }
  if (tools.length > 0) {
    newLines.push('tools:');
    for (const tool of tools) newLines.push(`  - ${tool}`);
  }
  const escapedBody = body.replace(/\$\{(\w+)\}/g, '$$$1');
  return `---\n${newLines.join('\n').trim()}\n---${escapedBody}`;
}

// ─── File copy helpers ─────────────────────────────────────────────────────

/** Verify a directory exists and has files */
function verifyInstalled(dirPath, description) {
  if (!fs.existsSync(dirPath)) {
    console.error(`  ${yellow}✗${reset} Failed to install ${description}: directory not created`);
    return false;
  }
  try {
    if (fs.readdirSync(dirPath).length === 0) {
      console.error(`  ${yellow}✗${reset} Failed to install ${description}: directory is empty`);
      return false;
    }
  } catch (e) {
    console.error(`  ${yellow}✗${reset} Failed to install ${description}: ${e.message}`);
    return false;
  }
  return true;
}

/** Recursively copy dir, replacing path references in .md files */
function copyDir(srcDir, destDir, pathPrefix, platform) {
  if (fs.existsSync(destDir)) fs.rmSync(destDir, { recursive: true });
  fs.mkdirSync(destDir, { recursive: true });
  for (const entry of fs.readdirSync(srcDir, { withFileTypes: true })) {
    const src = path.join(srcDir, entry.name);
    const dest = path.join(destDir, entry.name);
    if (entry.isDirectory()) {
      copyDir(src, dest, pathPrefix, platform);
    } else if (entry.name.endsWith('.md')) {
      let c = fs.readFileSync(src, 'utf8');
      c = replacePaths(c, pathPrefix, platform);
      if (entry.name === 'new-project.md') c = rewriteNewProject(c, platform);
      if (entry.name === 'agents.md') c = rewriteAgentsMd(c, platform, pathPrefix);
      if (platform === 'opencode') c = convertToOpencode(c);
      // gemini agents converted separately; body ${VAR} escaping done there
      fs.writeFileSync(dest, c);
    } else {
      fs.copyFileSync(src, dest);
    }
  }
}

function replacePaths(content, pathPrefix, platform) {
  const dirName = getDirName(platform);
  let c = content
    // Source files use ~/.claude/ and $HOME/.claude/ as canonical paths
    .replace(/~\/\.claude\//g, pathPrefix)
    .replace(/\$HOME\/\.claude\//g, toHomePrefix(pathPrefix))
    // Local ./.claude/ refs → ./<dirName>/
    .replace(/\.\/.claude\//g, `./${dirName}/`);
  // Replace platform-specific dir refs that may appear in source
  if (platform === 'opencode') {
    c = c.replace(/~\/\.opencode\//g, pathPrefix);
  } else if (platform === 'gemini') {
    c = c.replace(/~\/\.gemini\//g, pathPrefix);
  } else if (platform === 'codex') {
    c = c.replace(/~\/\.codex\//g, pathPrefix);
  }
  // Rewrite AskUserQuestion to platform-native interactive question tool name.
  // Source files use AskUserQuestion (Claude Code syntax). Each platform has its own tool name.
  // OpenCode is handled separately in convertToOpencode(). Claude keeps AskUserQuestion as-is.
  if (platform === 'windsurf') {
    c = c.replace(/\bAskUserQuestion\b/g, 'ask_user_question');
  } else if (platform === 'gemini') {
    c = c.replace(/\bAskUserQuestion\b/g, 'ask_user');
  } else if (platform === 'codex') {
    c = c.replace(/\bAskUserQuestion\b/g, 'request_user_input');
  }
  // Rewrite WebSearch/WebFetch to platform-native tool names.
  // Claude and Codex use WebSearch/WebFetch as-is. OpenCode handled in convertToOpencode().
  if (platform === 'windsurf') {
    c = c.replace(/\bWebSearch\b/g, 'search_web');
    c = c.replace(/\bWebFetch\b/g, 'read_url_content');
  } else if (platform === 'gemini') {
    c = c.replace(/\bWebSearch\b/g, 'google_web_search');
    c = c.replace(/\bWebFetch\b/g, 'web_fetch');
  }
  // Replace @mention skill syntax — @mention dispatch is Windsurf-native only
  if (platform === 'claude') {
    c = c.replace(/@agentic-learning\b/g, '/agentic-learning');
    c = c.replace(/@impeccable\b/g, '/impeccable');
  } else if (platform === 'opencode' || platform === 'gemini' || platform === 'codex') {
    // Strip @ so tips show plain skill names (no dispatch mechanism on these platforms)
    c = c.replace(/@agentic-learning\b/g, 'agentic-learning');
    c = c.replace(/@impeccable\b/g, 'impeccable');
  }
  return c;
}

/**
 * Rewrite AGENTS.md markers with platform-specific skill invocation instructions.
 * On Windsurf, @agentic-learning and @impeccable are native @skill invocations.
 * On all other platforms there is no @mention dispatch — the AI must be told
 * explicitly where the skill files live and what to do when the user types @skill-name.
 */
function rewriteAgentsMd(content, platform, pathPrefix) {
  if (!content.includes('<!-- LEARNSHIP_SKILLS_BLOCK -->')) return content;

  let block;
  if (platform === 'windsurf') {
    block = `### Learning Partner — \`@agentic-learning\`

Windsurf loads \`@agentic-learning\` natively as a skill. When the user (or a workflow) invokes \`@agentic-learning <action>\`, Windsurf automatically routes it to the installed skill.

Available actions: \`learn\`, \`quiz\`, \`reflect\`, \`space\`, \`brainstorm\`, \`explain-first\`, \`struggle\`, \`either-or\`, \`interleave\`, \`cognitive-load\`

### Design System — \`@impeccable\`

Windsurf loads \`@impeccable\` natively as a skill. When the user (or a workflow) invokes \`@impeccable <action>\`, Windsurf automatically routes it to the installed skill.

Available actions: \`adapt\`, \`animate\`, \`arrange\`, \`audit\`, \`bolder\`, \`clarify\`, \`colorize\`, \`critique\`, \`delight\`, \`distill\`, \`extract\`, \`frontend-design\`, \`harden\`, \`normalize\`, \`onboard\`, \`optimize\`, \`overdrive\`, \`polish\`, \`quieter\`, \`teach-impeccable\`, \`typeset\``;
  } else if (platform === 'claude') {
    // Claude Code: skills live at ~/.claude/skills/ (installed by installClaudeSkills).
    // @mention dispatch is Windsurf-native — use /skill-name slash command syntax instead.
    // pathPrefix = targetDir + '/learnship/' so strip 'learnship/' to get the skills parent.
    const claudeDir = pathPrefix.replace(/\/learnship\/$/, '');
    const skillsPath = claudeDir + '/skills';

    block = `### Learning Partner — \`/agentic-learning\`

The \`agentic-learning\` skill is installed at \`${skillsPath}/agentic-learning/SKILL.md\`. When a workflow checkpoint or the user mentions \`/agentic-learning <action>\` or asks you to use the agentic-learning skill:

1. Use the \`agentic-learning\` skill (invoke via the Skill tool or \`/agentic-learning\` slash command, or read \`${skillsPath}/agentic-learning/SKILL.md\`)
2. Find the section for the requested action (e.g. \`either-or\`, \`brainstorm\`, \`reflect\`, \`quiz\`, etc.)
3. Execute those instructions directly in this conversation

Available actions: \`learn\`, \`quiz\`, \`reflect\`, \`space\`, \`brainstorm\`, \`explain-first\`, \`struggle\`, \`either-or\`, \`interleave\`, \`cognitive-load\`

**Do NOT say "agentic-learning isn't installed" — it is installed. Run the action.**

### Design System — \`/impeccable\`

The \`impeccable\` skill is installed at \`${skillsPath}/impeccable/SKILL.md\`. When a workflow checkpoint or the user mentions \`/impeccable <action>\` or asks you to use the impeccable skill:

1. Use the \`impeccable\` skill (invoke via the Skill tool or \`/impeccable\` slash command, or read \`${skillsPath}/impeccable/SKILL.md\`)
2. Find the section for the requested action (e.g. \`audit\`, \`critique\`, \`polish\`, etc.)
3. Execute those instructions directly in this conversation

Available actions: \`adapt\`, \`animate\`, \`arrange\`, \`audit\`, \`bolder\`, \`clarify\`, \`colorize\`, \`critique\`, \`delight\`, \`distill\`, \`extract\`, \`frontend-design\`, \`harden\`, \`normalize\`, \`onboard\`, \`optimize\`, \`overdrive\`, \`polish\`, \`quieter\`, \`teach-impeccable\`, \`typeset\`

**Do NOT say "impeccable isn't installed" — it is installed. Run the action.**`;
  } else {
    // gemini, opencode, codex: @mention is not a native dispatch mechanism.
    // Skills are copied into learnship/skills/ — the AI reads SKILL.md directly.
    const skillsPath = pathPrefix + 'skills';

    block = `### Learning Partner — \`agentic-learning\`

The \`agentic-learning\` skill is installed at \`${skillsPath}/agentic-learning/SKILL.md\`. When a workflow checkpoint or the user asks you to use the agentic-learning skill:

1. Read \`${skillsPath}/agentic-learning/SKILL.md\`
2. Find the section for the requested action (e.g. \`either-or\`, \`brainstorm\`, \`reflect\`, \`quiz\`, etc.)
3. Execute those instructions directly in this conversation

Available actions: \`learn\`, \`quiz\`, \`reflect\`, \`space\`, \`brainstorm\`, \`explain-first\`, \`struggle\`, \`either-or\`, \`interleave\`, \`cognitive-load\`

**Do NOT say "agentic-learning isn't installed" — it is installed. Read the SKILL.md file and run the action.**

### Design System — \`impeccable\`

The \`impeccable\` skill is installed at \`${skillsPath}/impeccable/SKILL.md\`. When a workflow checkpoint or the user asks you to use the impeccable skill:

1. Read \`${skillsPath}/impeccable/SKILL.md\`
2. Find the section for the requested action (e.g. \`audit\`, \`critique\`, \`polish\`, etc.)
3. Execute those instructions directly in this conversation

Available actions: \`adapt\`, \`animate\`, \`arrange\`, \`audit\`, \`bolder\`, \`clarify\`, \`colorize\`, \`critique\`, \`delight\`, \`distill\`, \`extract\`, \`frontend-design\`, \`harden\`, \`normalize\`, \`onboard\`, \`optimize\`, \`overdrive\`, \`polish\`, \`quieter\`, \`teach-impeccable\`, \`typeset\`

**Do NOT say "impeccable isn't installed" — it is installed. Read the SKILL.md file and run the action.**`;
  }

  return content.replace('<!-- LEARNSHIP_SKILLS_BLOCK -->', block);
}

/** Rewrite new-project.md markers with exact platform-specific content at install time */
function rewriteNewProject(content, platform) {
  const dirName = getDirName(platform);
  const label   = getPlatformLabel(platform);

  // Platform label block
  const platformLabel = `You are running on **${label}**. Platform config directory: \`${dirName}/\``;
  content = content.replace('<!-- LEARNSHIP_PLATFORM_LABEL -->', platformLabel);

  // Gitignore command — exact single line, no conditionals
  const gitignoreCmd = `grep -q '${dirName}/' .gitignore 2>/dev/null || echo '${dirName}/' >> .gitignore`;
  content = content.replace('<!-- LEARNSHIP_GITIGNORE_CMD -->', gitignoreCmd);

  // Platforms that support real parallel subagents (verified against official docs)
  // Windsurf: no subagents at all
  // Gemini CLI: subagents exist but parallel execution is not yet shipped (GitHub issues #14963/#17749)
  const supportsParallel = platform === 'claude' || platform === 'opencode' || platform === 'codex';

  // Parallel execution block
  let parallelBlock;
  if (supportsParallel) {
    parallelBlock = `**Group D — Parallel execution:**\n\n${label} supports real parallel subagents. Ask:\n\n"Do you want to enable parallel subagent execution?"\n- **No** (recommended default) — Plans execute sequentially, one at a time. Safer, easier to follow.\n- **Yes** — Each independent plan in a wave gets its own dedicated subagent with a fresh context budget. Faster, but uses more tokens.`;
  } else if (platform === 'gemini') {
    parallelBlock = `**Group D — Parallel execution:**\n\nGemini CLI supports subagents but only runs them sequentially — parallel execution is not yet available. Parallelization is automatically set to \`false\`.`;
  } else {
    parallelBlock = `**Group D — Parallel execution:**\n\n${label} does not support real subagents. Parallelization is automatically set to \`false\`.`;
  }
  content = content.replace('<!-- LEARNSHIP_PARALLEL_BLOCK -->', parallelBlock);

  // Platform-specific AGENTS.md note
  // Claude Code reads CLAUDE.md as primary; Gemini CLI reads GEMINI.md — copy so sessions have context
  let agentsMdNote = '';
  if (platform === 'claude') {
    agentsMdNote = `> **Claude Code** reads \`CLAUDE.md\` as its primary context file. Copy AGENTS.md now so every future session has project context:\n> \`\`\`bash\n> cp AGENTS.md CLAUDE.md\n> git add CLAUDE.md && git commit -m "docs: add CLAUDE.md for Claude Code auto-loading"\n> \`\`\`\n>\n> **Keep them in sync:** Whenever you update AGENTS.md (e.g. via \`execute-phase\`), also update CLAUDE.md: \`cp AGENTS.md CLAUDE.md\``;
  } else if (platform === 'gemini') {
    agentsMdNote = `> **Gemini CLI** reads \`GEMINI.md\` automatically at session start, not \`AGENTS.md\`. Copy it now so every future session has project context:\n> \`\`\`bash\n> cp AGENTS.md GEMINI.md\n> git add GEMINI.md && git commit -m "docs: add GEMINI.md for Gemini CLI auto-loading"\n> \`\`\`\n>\n> **Keep them in sync:** Whenever you update AGENTS.md (e.g. via \`execute-phase\`), also update GEMINI.md: \`cp AGENTS.md GEMINI.md\``;
  }
  content = content.replace('<!-- LEARNSHIP_AGENTSMD_PLATFORM_NOTE -->', agentsMdNote);

  return content;
}

/** Install Claude Code / Windsurf commands (commands/learnship/ → target/commands/learnship/) */
function installClaudeCommands(srcDir, targetDir, pathPrefix) {
  const destDir = path.join(targetDir, 'commands', 'learnship');
  if (fs.existsSync(destDir)) fs.rmSync(destDir, { recursive: true });
  fs.mkdirSync(destDir, { recursive: true });
  let count = 0;
  for (const f of fs.readdirSync(srcDir)) {
    if (!f.endsWith('.md')) continue;
    let c = fs.readFileSync(path.join(srcDir, f), 'utf8');
    c = replacePaths(c, pathPrefix, 'claude');
    fs.writeFileSync(path.join(destDir, f), c);
    count++;
  }
  return count;
}

/** Install Claude Code native skills to ~/.claude/skills/<skillname>/ */
function installClaudeSkills(skillsSrc, targetDir) {
  const skillsDir = path.join(targetDir, 'skills');

  // Clean up legacy plugins/learnship/ if it exists from pre-1.9.23 installs
  const legacyPluginDir = path.join(targetDir, 'plugins', 'learnship');
  if (fs.existsSync(legacyPluginDir)) fs.rmSync(legacyPluginDir, { recursive: true });

  let count = 0;

  for (const entry of fs.readdirSync(skillsSrc, { withFileTypes: true })) {
    if (!entry.isDirectory()) continue;
    const skillName = entry.name;
    const srcPath = path.join(skillsSrc, skillName);

    if (!fs.existsSync(path.join(srcPath, 'SKILL.md'))) continue;

    const dest = path.join(skillsDir, skillName);

    if (skillName === 'impeccable') {
      // impeccable: build a single inlined SKILL.md that contains all sub-skill
      // content inline — Claude Code cannot follow markdown reference links to
      // sibling files, so the hollow index approach produced an "isn't installed" error.
      fs.mkdirSync(dest, { recursive: true });

      // Read root frontmatter + intro (everything up to the ## Actions section)
      const rootContent = fs.readFileSync(path.join(srcPath, 'SKILL.md'), 'utf8');
      // Strip frontmatter, keep the prose intro + "After running" footer
      const rootBody = rootContent.replace(/^---[\s\S]*?---\n/, '');

      // Ordered sub-actions (defines appearance order in the inlined file)
      const SUB_ACTION_ORDER = [
        'adapt', 'animate', 'arrange', 'audit', 'bolder', 'clarify', 'colorize',
        'critique', 'delight', 'distill', 'extract', 'frontend-design',
        'harden', 'normalize', 'onboard', 'optimize', 'overdrive', 'polish',
        'quieter', 'teach-impeccable', 'typeset',
      ];

      // Build inlined sections by reading each sub-skill's body
      const inlinedSections = [];
      for (const subName of SUB_ACTION_ORDER) {
        const subSkillPath = path.join(srcPath, subName, 'SKILL.md');
        if (!fs.existsSync(subSkillPath)) continue;
        const subContent = fs.readFileSync(subSkillPath, 'utf8');
        // Strip YAML frontmatter, keep body only
        const subBody = subContent.replace(/^---[\s\S]*?---\n/, '').trim();
        // Also copy sub-skill directory for reference files
        const subDest = path.join(dest, subName);
        copyDir(path.join(srcPath, subName), subDest, '', 'claude');
        inlinedSections.push(`\n## Action: \`${subName}\`\n\n${subBody}`);
      }

      // Description without @mention syntax — Claude Code discovers skills by description
      // content matching the user's request, not by @mention dispatch.
      const inlinedSkillMd =
        `---\nname: impeccable\ndescription: >\n` +
        `  A design quality system for frontend interfaces. 21 focused actions for\n` +
        `  auditing, refining, and elevating UI quality. Use when the user asks to\n` +
        `  audit, critique, polish, improve, review, or refine a frontend interface.\n` +
        `  Actions: adapt, animate, arrange, audit, bolder, clarify, colorize,\n` +
        `  critique, delight, distill, extract, frontend-design, harden, normalize,\n` +
        `  onboard, optimize, overdrive, polish, quieter, teach-impeccable, typeset.\n` +
        `---\n\n` +
        rootBody.replace(/## Actions[\s\S]*?---\n\n## How to use/, '## How to use') +
        `\n\n` +
        inlinedSections.join('\n\n');

      fs.writeFileSync(path.join(dest, 'SKILL.md'), inlinedSkillMd);
      count++;
    } else {
      // agentic-learning and any future top-level skills — copy then fix description
      copyDir(srcPath, dest, '', 'claude');
      // Remove @mention invocation hint from description — it's Windsurf-only syntax.
      // Claude Code discovers skills by description content, not @mention dispatch.
      const skillMdPath = path.join(dest, 'SKILL.md');
      let skillContent = fs.readFileSync(skillMdPath, 'utf8');
      skillContent = skillContent.replace(
        /\n( +)Invoke with @\S+ followed by one of:[^\n]*(\n\1[^\n]+)*/g,
        ''
      );
      fs.writeFileSync(skillMdPath, skillContent);
      count++;
    }
  }

  return count;
}

/** Install OpenCode commands (flat: learnship-*.md) */
function installOpencodeCommands(srcDir, targetDir, pathPrefix) {
  const destDir = path.join(targetDir, 'command');
  fs.mkdirSync(destDir, { recursive: true });
  // Remove old learnship-*.md
  if (fs.existsSync(destDir)) {
    for (const f of fs.readdirSync(destDir)) {
      if (f.startsWith('learnship-') && f.endsWith('.md')) fs.unlinkSync(path.join(destDir, f));
    }
  }
  let count = 0;
  for (const f of fs.readdirSync(srcDir)) {
    if (!f.endsWith('.md')) continue;
    const baseName = f.replace('.md', '');
    const destName = `learnship-${baseName}.md`;
    let c = fs.readFileSync(path.join(srcDir, f), 'utf8');
    c = replacePaths(c, pathPrefix, 'opencode');
    c = convertToOpencode(c);
    fs.writeFileSync(path.join(destDir, destName), c);
    count++;
  }
  return count;
}

/** Install Gemini CLI commands (commands/learnship/*.toml) */
function installGeminiCommands(srcDir, targetDir, pathPrefix) {
  const destDir = path.join(targetDir, 'commands', 'learnship');
  if (fs.existsSync(destDir)) fs.rmSync(destDir, { recursive: true });
  fs.mkdirSync(destDir, { recursive: true });
  let count = 0;
  for (const f of fs.readdirSync(srcDir)) {
    if (!f.endsWith('.md')) continue;
    let c = fs.readFileSync(path.join(srcDir, f), 'utf8');
    c = replacePaths(c, pathPrefix, 'gemini');
    const toml = convertToGeminiToml(c);
    const destName = f.replace('.md', '.toml');
    fs.writeFileSync(path.join(destDir, destName), toml);
    count++;
  }
  return count;
}

/* Install Codex skills (skills/learnship-NAME/SKILL.md) */
function installCodexSkills(srcDir, targetDir, pathPrefix) {
  const skillsDir = path.join(targetDir, 'skills');
  fs.mkdirSync(skillsDir, { recursive: true });
  // Remove old learnship-* skill dirs
  for (const entry of fs.readdirSync(skillsDir, { withFileTypes: true })) {
    if (entry.isDirectory() && entry.name.startsWith('learnship-')) {
      fs.rmSync(path.join(skillsDir, entry.name), { recursive: true });
    }
  }
  let count = 0;
  for (const f of fs.readdirSync(srcDir)) {
    if (!f.endsWith('.md')) continue;
    const baseName = f.replace('.md', '');
    const skillName = `learnship-${baseName}`;
    const skillDir = path.join(skillsDir, skillName);
    fs.mkdirSync(skillDir, { recursive: true });
    let c = fs.readFileSync(path.join(srcDir, f), 'utf8');
    c = replacePaths(c, pathPrefix, 'codex');
    c = convertToCodexSkill(c, skillName);
    fs.writeFileSync(path.join(skillDir, 'SKILL.md'), c);
    count++;
  }
  return count;
}

/**
 * Generate the learnship config block for Codex config.toml.
 */
function generateCodexConfigBlock(agents) {
  const lines = [
    LEARNSHIP_CODEX_MARKER,
    '[features]',
    'multi_agent = true',
    'default_mode_request_user_input = true',
    '',
    '[agents]',
    'max_threads = 4',
    'max_depth = 2',
    '',
  ];
  for (const { name, description } of agents) {
    lines.push(`[agents.${name}]`);
    lines.push(`description = ${JSON.stringify(description)}`);
    lines.push(`config_file = "agents/${name}.toml"`);
    lines.push('');
  }
  return lines.join('\n');
}

/**
 * Strip learnship sections from Codex config.toml content.
 * Returns cleaned content, or null if file would be empty after stripping.
 */
function stripLearnshipFromCodexConfig(content) {
  const markerIndex = content.indexOf(LEARNSHIP_CODEX_MARKER);
  if (markerIndex !== -1) {
    let before = content.substring(0, markerIndex).trimEnd();
    before = before.replace(/^multi_agent\s*=\s*true\s*\n?/m, '');
    before = before.replace(/^default_mode_request_user_input\s*=\s*true\s*\n?/m, '');
    before = before.replace(/^\[features\]\s*\n(?=\[|$)/m, '');
    before = before.replace(/\n{3,}/g, '\n\n').trim();
    if (!before) return null;
    return before + '\n';
  }
  // No marker — clean any learnship-injected keys that may have leaked
  let cleaned = content;
  cleaned = cleaned.replace(/^multi_agent\s*=\s*true\s*\n?/m, '');
  cleaned = cleaned.replace(/^default_mode_request_user_input\s*=\s*true\s*\n?/m, '');
  cleaned = cleaned.replace(/^\[agents\.learnship-[^\]]+\]\n(?:(?!\[)[^\n]*\n?)*/gm, '');
  cleaned = cleaned.replace(/^\[features\]\s*\n(?=\[|$)/m, '');
  cleaned = cleaned.replace(/^\[agents\]\s*\n(?=\[|$)/m, '');
  cleaned = cleaned.replace(/\n{3,}/g, '\n\n').trim();
  if (!cleaned) return null;
  return cleaned + '\n';
}

/**
 * Merge learnship config block into existing or new config.toml.
 * Three cases: new file, existing with learnship marker, existing without marker.
 */
function mergeCodexConfig(configPath, learnshipBlock) {
  // Case 1: No config.toml — create fresh
  if (!fs.existsSync(configPath)) {
    fs.writeFileSync(configPath, learnshipBlock + '\n');
    return;
  }
  const existing = fs.readFileSync(configPath, 'utf8');
  const markerIndex = existing.indexOf(LEARNSHIP_CODEX_MARKER);

  // Case 2: Has learnship marker — truncate and re-append
  if (markerIndex !== -1) {
    let before = existing.substring(0, markerIndex).trimEnd();
    if (before) {
      before = before.replace(/^\[agents\.learnship-[^\]]+\]\n(?:(?!\[)[^\n]*\n?)*/gm, '');
      before = before.replace(/^\[agents\]\n(?:(?!\[)[^\n]*\n?)*/m, '');
      before = before.replace(/\n{3,}/g, '\n\n').trimEnd();
      const hasFeatures = /^\[features\]\s*$/m.test(before);
      if (hasFeatures) {
        if (!before.includes('multi_agent')) before = before.replace(/^\[features\]\s*$/m, '[features]\nmulti_agent = true');
        if (!before.includes('default_mode_request_user_input')) before = before.replace(/^\[features\].*$/m, '$&\ndefault_mode_request_user_input = true');
        const block = LEARNSHIP_CODEX_MARKER + '\n' + learnshipBlock.substring(learnshipBlock.indexOf('[agents]'));
        fs.writeFileSync(configPath, before + '\n\n' + block + '\n');
      } else {
        fs.writeFileSync(configPath, before + '\n\n' + learnshipBlock + '\n');
      }
    } else {
      fs.writeFileSync(configPath, learnshipBlock + '\n');
    }
    return;
  }

  // Case 3: No marker — inject features if needed, append agents
  let content = existing;
  const featuresRegex = /^\[features\]\s*$/m;
  const hasFeatures = featuresRegex.test(content);
  if (hasFeatures) {
    if (!content.includes('multi_agent')) content = content.replace(featuresRegex, '[features]\nmulti_agent = true');
    if (!content.includes('default_mode_request_user_input')) content = content.replace(/^\[features\].*$/m, '$&\ndefault_mode_request_user_input = true');
    const agentsBlock = learnshipBlock.substring(learnshipBlock.indexOf('[agents]'));
    content = content.trimEnd() + '\n\n' + LEARNSHIP_CODEX_MARKER + '\n' + agentsBlock + '\n';
  } else {
    content = content.trimEnd() + '\n\n' + learnshipBlock + '\n';
  }
  fs.writeFileSync(configPath, content);
}

/** Install Codex agent .toml files and update config.toml */
function installCodexAgents(agentsSrcDir, targetDir, pathPrefix) {
  const agentsDir = path.join(targetDir, 'agents');
  fs.mkdirSync(agentsDir, { recursive: true });
  // Remove stale learnship agent .toml files
  for (const f of fs.readdirSync(agentsDir)) {
    if (f.startsWith('learnship-') && f.endsWith('.toml')) fs.unlinkSync(path.join(agentsDir, f));
  }
  const agents = [];
  for (const f of fs.readdirSync(agentsSrcDir)) {
    if (!f.startsWith('learnship-') || !f.endsWith('.md')) continue;
    let content = fs.readFileSync(path.join(agentsSrcDir, f), 'utf8');
    // Replace ~/.claude/ paths before generating TOML
    content = content.replace(/~\/\.claude\//g, pathPrefix);
    content = content.replace(/\$HOME\/\.claude\//g, toHomePrefix(pathPrefix));
    // Convert to Codex agent format
    content = convertClaudeAgentToCodexAgent(content);
    const { frontmatter, body } = parseFrontmatter(content);
    const name = frontmatter ? (getFrontmatterField(frontmatter, 'name') || f.replace('.md','')) : f.replace('.md','');
    const description = frontmatter ? (getFrontmatterField(frontmatter, 'description') || '').replace(/\s+/g,' ').trim() : '';
    agents.push({ name, description });
    const sandboxMode = CODEX_AGENT_SANDBOX[name] || 'workspace-write';
    const tomlContent = `sandbox_mode = "${sandboxMode}"\ndeveloper_instructions = """\n${body.trim()}\n"""\n`;
    fs.writeFileSync(path.join(agentsDir, `${name}.toml`), tomlContent);
  }
  const learnshipBlock = generateCodexConfigBlock(agents);
  mergeCodexConfig(path.join(targetDir, 'config.toml'), learnshipBlock);
  return agents.length;
}

/** Install agent .md files for a platform (not Codex — handled by installCodexAgents) */
function installAgents(agentsSrcDir, targetDir, pathPrefix, platform) {
  const destDir = path.join(targetDir, 'agents');
  fs.mkdirSync(destDir, { recursive: true });
  // Remove stale learnship agent .md files before re-installing
  for (const f of fs.readdirSync(destDir)) {
    if (f.startsWith('learnship-') && f.endsWith('.md')) fs.unlinkSync(path.join(destDir, f));
  }
  let count = 0;
  for (const f of fs.readdirSync(agentsSrcDir)) {
    if (!f.startsWith('learnship-') || !f.endsWith('.md')) continue;
    let c = fs.readFileSync(path.join(agentsSrcDir, f), 'utf8');
    c = replacePaths(c, pathPrefix, platform);
    if (platform === 'gemini') c = convertAgentForGemini(c);
    else if (platform === 'opencode') c = convertToOpencode(c);
    fs.writeFileSync(path.join(destDir, f), c);
    count++;
  }
  return count;
}

/**
 * Parse JSONC (JSON with Comments) by stripping comments and trailing commas.
 * OpenCode supports JSONC so users may have // comments in opencode.json.
 */
function parseJsonc(content) {
  if (content.charCodeAt(0) === 0xFEFF) content = content.slice(1); // strip BOM
  let result = '';
  let inString = false;
  let i = 0;
  while (i < content.length) {
    const char = content[i];
    const next = content[i + 1];
    if (inString) {
      result += char;
      if (char === '\\' && i + 1 < content.length) { result += next; i += 2; continue; }
      if (char === '"') inString = false;
      i++;
    } else {
      if (char === '"') { inString = true; result += char; i++; }
      else if (char === '/' && next === '/') { while (i < content.length && content[i] !== '\n') i++; }
      else if (char === '/' && next === '*') {
        i += 2;
        while (i < content.length - 1 && !(content[i] === '*' && content[i + 1] === '/')) i++;
        i += 2;
      } else { result += char; i++; }
    }
  }
  result = result.replace(/,(\s*[}\]])/g, '$1'); // remove trailing commas
  return JSON.parse(result);
}

/** Configure OpenCode permissions to allow reading learnship reference docs */
function configureOpencodePermissions(targetDir, learnshipDir) {
  const configPath = path.join(targetDir, 'opencode.json');
  let config = {};
  if (fs.existsSync(configPath)) {
    try { config = parseJsonc(fs.readFileSync(configPath, 'utf8')); }
    catch (e) {
      console.log(`  ${yellow}⚠${reset} Could not parse opencode.json — skipping permission config`);
      console.log(`    ${dim}Reason: ${e.message}${reset}`);
      console.log(`    ${dim}Your config was NOT modified. Fix the syntax manually if needed.${reset}`);
      return;
    }
  }
  const defaultDir = path.join(os.homedir(), '.config', 'opencode');
  const learnshipPath = targetDir === defaultDir
    ? '~/.config/opencode/learnship/*'
    : `${learnshipDir.replace(/\\/g, '/')}/*`;
  if (!config.permission) config.permission = {};
  if (!config.permission.read) config.permission.read = {};
  if (!config.permission.external_directory) config.permission.external_directory = {};
  if (config.permission.read[learnshipPath] === 'allow' &&
      config.permission.external_directory[learnshipPath] === 'allow') return; // already set
  config.permission.read[learnshipPath] = 'allow';
  config.permission.external_directory[learnshipPath] = 'allow';
  writeSettings(configPath, config);
  console.log(`  ${green}✓${reset} Configured read permissions in opencode.json`);
}

/**
 * Scan installed files for leaked ~/.claude paths in non-Claude platforms.
 * GSD pattern: warn if any .md/.toml file still contains the source platform path.
 */
function scanForLeakedPaths(targetDir, platform) {
  if (platform === 'claude' || platform === 'windsurf') return;
  const leaks = [];
  function scan(dir) {
    if (!fs.existsSync(dir)) return;
    for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
      const full = path.join(dir, entry.name);
      if (entry.isDirectory()) { scan(full); continue; }
      if (!entry.name.endsWith('.md') && !entry.name.endsWith('.toml')) continue;
      if (entry.name === 'CHANGELOG.md') continue;
      const content = fs.readFileSync(full, 'utf8');
      const matches = content.match(/(?:~|\$HOME)\/\.claude\b/g);
      if (matches) leaks.push({ file: full.replace(targetDir + '/', ''), count: matches.length });
    }
  }
  scan(targetDir);
  if (leaks.length > 0) {
    const total = leaks.reduce((s, l) => s + l.count, 0);
    console.warn(`\n  ${yellow}⚠${reset}  Found ${total} unreplaced .claude path(s) in ${leaks.length} file(s):`);
    for (const leak of leaks.slice(0, 5)) console.warn(`     ${dim}${leak.file}${reset} (${leak.count})`);
    if (leaks.length > 5) console.warn(`     ${dim}... and ${leaks.length - 5} more${reset}`);
    console.warn(`  ${dim}These paths may not resolve correctly for ${getPlatformLabel(platform)}.${reset}`);
  }
}

// ─── Hook installation ────────────────────────────────────────────────────

/** List of learnship hook files managed by the installer */
const LEARNSHIP_MANAGED_HOOKS = [
  'learnship-statusline.js',
  'learnship-context-monitor.js',
  'learnship-prompt-guard.js',
  'learnship-session-state.js',
];

/**
 * Install Claude Code / Gemini native hooks into settings.json.
 * Copies hook .js files to target/hooks/ and registers them in settings.json.
 * Preserves existing non-learnship entries (read-modify-write).
 */
function installClaudeHooks(targetDir, isGlobal, platform) {
  const hooksSrc = path.join(__dirname, '..', 'hooks');
  const hooksDest = path.join(targetDir, 'hooks');
  fs.mkdirSync(hooksDest, { recursive: true });

  // Copy hook .js files (skip session-start bash script — replaced by learnship-session-state.js)
  let copied = 0;
  for (const file of LEARNSHIP_MANAGED_HOOKS) {
    const src = path.join(hooksSrc, file);
    if (fs.existsSync(src)) {
      // Stamp version header
      let content = fs.readFileSync(src, 'utf8');
      content = content.replace(/learnship-hook-version:\s*[\d.]+/, `learnship-hook-version: ${pkg.version}`);
      fs.writeFileSync(path.join(hooksDest, file), content);
      copied++;
    }
  }

  if (copied === 0) return 0;

  // Write package.json for CJS require() support in hooks
  const pkgJsonPath = path.join(targetDir, 'package.json');
  if (!fs.existsSync(pkgJsonPath)) {
    fs.writeFileSync(pkgJsonPath, '{"type":"commonjs"}\n');
  }

  // Build hook commands — use $CLAUDE_PROJECT_DIR for local installs
  const dirName = getDirName(platform);
  const localPrefix = '"$CLAUDE_PROJECT_DIR"/' + dirName;
  const buildCmd = (file) => {
    if (isGlobal) {
      const resolved = path.resolve(targetDir).replace(/\\/g, '/');
      return `node "${resolved}/hooks/${file}"`;
    }
    return `node ${localPrefix}/hooks/${file}`;
  };

  // Read-modify-write settings.json
  const settingsPath = path.join(targetDir, 'settings.json');
  const settings = readSettings(settingsPath);
  if (!settings.hooks) settings.hooks = {};

  // Gemini uses AfterTool/BeforeTool instead of PostToolUse/PreToolUse
  const isGemini = platform === 'gemini';
  const postToolEvent = isGemini ? 'AfterTool' : 'PostToolUse';
  const preToolEvent = isGemini ? 'BeforeTool' : 'PreToolUse';

  // --- SessionStart: learnship-session-state.js ---
  if (!settings.hooks.SessionStart) settings.hooks.SessionStart = [];
  const hasSessionHook = settings.hooks.SessionStart.some(entry =>
    entry.hooks && entry.hooks.some(h => h.command && h.command.includes('learnship-session-state'))
  );
  if (!hasSessionHook && fs.existsSync(path.join(hooksDest, 'learnship-session-state.js'))) {
    settings.hooks.SessionStart.push({
      hooks: [{ type: 'command', command: buildCmd('learnship-session-state.js') }]
    });
  }

  // --- PostToolUse: learnship-context-monitor.js ---
  if (!settings.hooks[postToolEvent]) settings.hooks[postToolEvent] = [];
  const hasContextHook = settings.hooks[postToolEvent].some(entry =>
    entry.hooks && entry.hooks.some(h => h.command && h.command.includes('learnship-context-monitor'))
  );
  if (!hasContextHook && fs.existsSync(path.join(hooksDest, 'learnship-context-monitor.js'))) {
    settings.hooks[postToolEvent].push({
      matcher: 'Bash|Edit|Write|MultiEdit',
      hooks: [{ type: 'command', command: buildCmd('learnship-context-monitor.js'), timeout: 10 }]
    });
  }

  // --- PreToolUse: learnship-prompt-guard.js ---
  if (!settings.hooks[preToolEvent]) settings.hooks[preToolEvent] = [];
  const hasPromptGuard = settings.hooks[preToolEvent].some(entry =>
    entry.hooks && entry.hooks.some(h => h.command && h.command.includes('learnship-prompt-guard'))
  );
  if (!hasPromptGuard && fs.existsSync(path.join(hooksDest, 'learnship-prompt-guard.js'))) {
    settings.hooks[preToolEvent].push({
      matcher: 'Write|Edit',
      hooks: [{ type: 'command', command: buildCmd('learnship-prompt-guard.js'), timeout: 5 }]
    });
  }

  // --- statusLine: learnship-statusline.js ---
  if (!settings.statusLine && fs.existsSync(path.join(hooksDest, 'learnship-statusline.js'))) {
    settings.statusLine = {
      type: 'command',
      command: buildCmd('learnship-statusline.js')
    };
  }

  writeSettings(settingsPath, settings);
  return copied;
}

/**
 * Remove learnship hooks from settings.json and delete hook files.
 */
function uninstallClaudeHooks(targetDir) {
  const settingsPath = path.join(targetDir, 'settings.json');
  if (fs.existsSync(settingsPath)) {
    try {
      const settings = JSON.parse(fs.readFileSync(settingsPath, 'utf8'));
      let modified = false;

      // Remove learnship entries from hook arrays
      for (const event of ['SessionStart', 'PostToolUse', 'AfterTool', 'PreToolUse', 'BeforeTool']) {
        if (Array.isArray(settings.hooks?.[event])) {
          const before = settings.hooks[event].length;
          settings.hooks[event] = settings.hooks[event].filter(entry =>
            !entry.hooks || !entry.hooks.some(h => h.command && h.command.includes('learnship-'))
          );
          if (settings.hooks[event].length !== before) modified = true;
          if (settings.hooks[event].length === 0) delete settings.hooks[event];
        }
      }

      // Remove statusLine if it's ours
      if (settings.statusLine?.command?.includes('learnship-')) {
        delete settings.statusLine;
        modified = true;
      }

      // Clean empty hooks object
      if (settings.hooks && Object.keys(settings.hooks).length === 0) delete settings.hooks;

      if (modified) {
        writeSettings(settingsPath, settings);
        console.log(`  ${green}✓${reset} Removed learnship hooks from settings.json`);
      }
    } catch (e) { /* ignore parse errors */ }
  }

  // Remove hook files
  const hooksDir = path.join(targetDir, 'hooks');
  if (fs.existsSync(hooksDir)) {
    let n = 0;
    for (const file of LEARNSHIP_MANAGED_HOOKS) {
      const fp = path.join(hooksDir, file);
      if (fs.existsSync(fp)) { fs.unlinkSync(fp); n++; }
    }
    if (n > 0) console.log(`  ${green}✓${reset} Removed ${n} learnship hook files`);
  }

  // Remove package.json if it's our minimal one
  const pkgJsonPath = path.join(targetDir, 'package.json');
  if (fs.existsSync(pkgJsonPath)) {
    try {
      const content = fs.readFileSync(pkgJsonPath, 'utf8').trim();
      if (content === '{"type":"commonjs"}') {
        fs.unlinkSync(pkgJsonPath);
      }
    } catch (e) { /* ignore */ }
  }
}

// ─── File manifest ────────────────────────────────────────────────────────

const crypto = require('crypto');

function fileHash(filePath) {
  const content = fs.readFileSync(filePath);
  return crypto.createHash('sha256').update(content).digest('hex');
}

/**
 * Generate install manifest with SHA-256 hashes for all installed files.
 */
function generateManifest(targetDir) {
  const manifest = {
    version: pkg.version,
    timestamp: new Date().toISOString(),
    files: {}
  };

  function scanDir(dir, prefix) {
    if (!fs.existsSync(dir)) return;
    for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
      const full = path.join(dir, entry.name);
      const rel = prefix ? prefix + '/' + entry.name : entry.name;
      if (entry.isDirectory()) {
        scanDir(full, rel);
      } else {
        manifest.files[rel] = fileHash(full);
      }
    }
  }

  // Scan learnship/ payload
  const learnshipDir = path.join(targetDir, 'learnship');
  if (fs.existsSync(learnshipDir)) scanDir(learnshipDir, 'learnship');

  // Scan hooks/
  const hooksDir = path.join(targetDir, 'hooks');
  if (fs.existsSync(hooksDir)) {
    for (const file of fs.readdirSync(hooksDir)) {
      if (file.startsWith('learnship-')) {
        manifest.files['hooks/' + file] = fileHash(path.join(hooksDir, file));
      }
    }
  }

  fs.writeFileSync(path.join(targetDir, 'learnship-file-manifest.json'), JSON.stringify(manifest, null, 2));
  return manifest;
}

/**
 * Detect user-modified files by comparing against install manifest.
 * Backs up modified files to learnship-local-patches/.
 */
function saveLocalPatches(targetDir) {
  const manifestPath = path.join(targetDir, 'learnship-file-manifest.json');
  if (!fs.existsSync(manifestPath)) return [];

  let manifest;
  try { manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8')); } catch { return []; }

  const patchesDir = path.join(targetDir, 'learnship-local-patches');
  const modified = [];

  for (const [relPath, originalHash] of Object.entries(manifest.files || {})) {
    const fullPath = path.join(targetDir, relPath);
    if (!fs.existsSync(fullPath)) continue;
    const currentHash = fileHash(fullPath);
    if (currentHash !== originalHash) {
      const backupPath = path.join(patchesDir, relPath);
      fs.mkdirSync(path.dirname(backupPath), { recursive: true });
      fs.copyFileSync(fullPath, backupPath);
      modified.push(relPath);
    }
  }

  if (modified.length > 0) {
    const meta = {
      backed_up_at: new Date().toISOString(),
      from_version: manifest.version,
      files: modified
    };
    fs.writeFileSync(path.join(patchesDir, 'backup-meta.json'), JSON.stringify(meta, null, 2));
    console.log(`\n  ${yellow}i${reset}  Found ${modified.length} locally modified learnship file(s) — backed up to learnship-local-patches/`);
    for (const f of modified.slice(0, 5)) console.log(`     ${dim}${f}${reset}`);
    if (modified.length > 5) console.log(`     ${dim}... and ${modified.length - 5} more${reset}`);
  }
  return modified;
}

// ─── Main install function ─────────────────────────────────────────────────
function install(platform, isGlobal) {
  // Cursor installs via the marketplace plugin, not this CLI.
  // Print instructions and exit cleanly rather than silently doing nothing.
  if (platform === 'cursor') {
    console.log(`\n  ${cyan}Cursor${reset} — learnship installs via the plugin marketplace, not this CLI.\n`);
    console.log(`  ${yellow}Option 1 (recommended):${reset} Install from the Cursor marketplace:`);
    console.log(`    ${dim}/add-plugin learnship${reset}\n`);
    console.log(`  ${yellow}Option 2 (manual):${reset} Copy the rule file into your project:`);
    console.log(`    ${dim}mkdir -p .cursor/rules${reset}`);
    console.log(`    ${dim}cp node_modules/learnship/cursor-rules/learnship.mdc .cursor/rules/${reset}\n`);
    console.log(`  ${dim}The .mdc rule activates all 42 learnship workflows automatically in every Cursor session.${reset}\n`);
    return;
  }

  const src = path.join(__dirname, '..');
  const targetDir = targetOverride || (isGlobal ? getGlobalDir(platform) : path.join(process.cwd(), getDirName(platform)));
  const pathPrefix = `${targetDir.replace(/\\/g, '/')}/learnship/`;
  const label = getPlatformLabel(platform);
  const locationLabel = targetDir.replace(os.homedir(), '~');

  console.log(`\n  Installing for ${cyan}${label}${reset} → ${cyan}${locationLabel}${reset}\n`);

  fs.mkdirSync(targetDir, { recursive: true });

  // Save locally modified files before overwriting
  saveLocalPatches(targetDir);

  const learnshipSrc = path.join(src, 'learnship');
  const commandsSrc  = path.join(src, 'commands', 'learnship');
  const agentsSrc    = path.join(src, 'agents');
  const skillsSrc    = path.join(src, 'skills');
  const failures = [];

  // 1. Install learnship/ payload (workflows, references, templates)
  const learnshipDest = path.join(targetDir, 'learnship');
  copyDir(learnshipSrc, learnshipDest, pathPrefix, platform);
  if (verifyInstalled(learnshipDest, 'learnship/')) {
    console.log(`  ${green}✓${reset} Installed learnship/ (workflows, references, templates)`);
  } else { failures.push('learnship/'); }

  // 1b. Copy agents/ into learnship/workflows/agents/ so @./agents/ resolves from workflow files.
  // Windsurf is handled separately (flat workflows/ dir). For all other platforms, the AI reads
  // workflows from learnship/workflows/ and @./ resolves relative to that directory.
  if (platform !== 'windsurf') {
    const agentsInlinesSrc  = path.join(learnshipSrc, 'agents');
    const agentsInlinesDest = path.join(learnshipDest, 'workflows', 'agents');
    if (fs.existsSync(agentsInlinesSrc)) {
      copyDir(agentsInlinesSrc, agentsInlinesDest, pathPrefix, platform);
    }
  }

  // 2. Write VERSION file into learnship/ dir
  fs.writeFileSync(path.join(learnshipDest, 'VERSION'), pkg.version);
  console.log(`  ${green}✓${reset} Wrote VERSION (${pkg.version})`);

  // 2b. Install skills
  // Windsurf: native skill support — copy to targetDir/skills/ (i.e. .windsurf/skills/)
  // Others:   copy to learnship/skills/ so the AI loads them as context files
  if (fs.existsSync(skillsSrc)) {
    const skillsDest = platform === 'windsurf'
      ? path.join(targetDir, 'skills')
      : path.join(learnshipDest, 'skills');
    fs.mkdirSync(skillsDest, { recursive: true });
    let skillCount = 0;
    for (const entry of fs.readdirSync(skillsSrc, { withFileTypes: true })) {
      if (!entry.isDirectory()) continue;
      copyDir(path.join(skillsSrc, entry.name), path.join(skillsDest, entry.name), pathPrefix, platform);
      skillCount++;
    }
    if (skillCount > 0) {
      const loc = platform === 'windsurf' ? 'skills/' : 'learnship/skills/';
      console.log(`  ${green}✓${reset} Installed ${skillCount} skills to ${loc}`);
    }
  }

  // 3. Install commands (platform-specific format)
  if (platform === 'windsurf') {
    const wfDest = path.join(targetDir, 'workflows');
    fs.mkdirSync(wfDest, { recursive: true });
    let count = 0;
    for (const f of fs.readdirSync(path.join(learnshipSrc, 'workflows'))) {
      if (!f.endsWith('.md')) continue;
      let c = fs.readFileSync(path.join(learnshipSrc, 'workflows', f), 'utf8');
      c = replacePaths(c, pathPrefix, platform);
      if (f === 'new-project.md') c = rewriteNewProject(c, platform);
      fs.writeFileSync(path.join(wfDest, f), c);
      count++;
    }
    // Copy templates/, references/, and agents/ so @./templates/, @./references/, @./agents/ resolve in workflows
    for (const subdir of ['templates', 'references', 'agents']) {
      const srcSub = path.join(learnshipSrc, subdir);
      const destSub = path.join(wfDest, subdir);
      if (fs.existsSync(srcSub)) {
        copyDir(srcSub, destSub, pathPrefix, platform);
      }
    }
    console.log(`  ${green}✓${reset} Installed ${count} workflows to workflows/`);
  } else if (platform === 'claude') {
    // Remove legacy workflows/ dir left by pre-1.9.0 installs — it shadows learnship/workflows/
    // and causes commands to read stale files (e.g. showing "Windsurf-native" text on Claude Code)
    const legacyWorkflowsDir = path.join(targetDir, 'workflows');
    if (fs.existsSync(legacyWorkflowsDir)) {
      fs.rmSync(legacyWorkflowsDir, { recursive: true });
      console.log(`  ${yellow}⚠${reset}  Removed legacy workflows/ directory (pre-1.9.0 leftover)`);
    }
    const count = installClaudeCommands(commandsSrc, targetDir, pathPrefix);
    if (verifyInstalled(path.join(targetDir, 'commands', 'learnship'), 'commands/learnship/')) {
      console.log(`  ${green}✓${reset} Installed ${count} commands to commands/learnship/`);
    } else { failures.push('commands/learnship/'); }
    const aCount = installAgents(agentsSrc, targetDir, pathPrefix, 'claude');
    if (aCount > 0) console.log(`  ${green}✓${reset} Installed ${aCount} agents to agents/`);
    else failures.push('agents/');
    const pCount = installClaudeSkills(skillsSrc, targetDir);
    if (pCount > 0) {
      console.log(`  ${green}✓${reset} Installed ${pCount} skills to skills/`);
    } else {
      failures.push('skills/');
    }
    // Install native Claude Code hooks (settings.json + hook files)
    const hCount = installClaudeHooks(targetDir, isGlobal, 'claude');
    if (hCount > 0) console.log(`  ${green}✓${reset} Installed ${hCount} hooks + settings.json (statusline, context monitor, prompt guard, session state)`);
  } else if (platform === 'opencode') {
    const count = installOpencodeCommands(commandsSrc, targetDir, pathPrefix);
    console.log(`  ${green}✓${reset} Installed ${count} commands to command/ (flat)`);
    const aCount = installAgents(agentsSrc, targetDir, pathPrefix, 'opencode');
    if (aCount > 0) console.log(`  ${green}✓${reset} Installed ${aCount} agents to agents/`);
    configureOpencodePermissions(targetDir, learnshipDest);
  } else if (platform === 'gemini') {
    const count = installGeminiCommands(commandsSrc, targetDir, pathPrefix);
    if (verifyInstalled(path.join(targetDir, 'commands', 'learnship'), 'commands/learnship/')) {
      console.log(`  ${green}✓${reset} Installed ${count} commands to commands/learnship/ (TOML)`);
    } else { failures.push('commands/learnship/'); }
    const aCount = installAgents(agentsSrc, targetDir, pathPrefix, 'gemini');
    if (aCount > 0) console.log(`  ${green}✓${reset} Installed ${aCount} agents to agents/`);
    // Gemini requires experimental agents enabled
    const settingsPath = path.join(targetDir, 'settings.json');
    const settings = readSettings(settingsPath);
    if (!settings.experimental) settings.experimental = {};
    if (!settings.experimental.enableAgents) {
      settings.experimental.enableAgents = true;
      writeSettings(settingsPath, settings);
      console.log(`  ${green}✓${reset} Enabled experimental.enableAgents in settings.json`);
    }
    // Install native Gemini hooks (settings.json + hook files)
    const hCount = installClaudeHooks(targetDir, isGlobal, 'gemini');
    if (hCount > 0) console.log(`  ${green}✓${reset} Installed ${hCount} hooks + settings.json (statusline, context monitor, prompt guard, session state)`);
  } else if (platform === 'codex') {
    const count = installCodexSkills(commandsSrc, targetDir, pathPrefix);
    console.log(`  ${green}✓${reset} Installed ${count} skills to skills/`);
    const aCount = installCodexAgents(agentsSrc, targetDir, pathPrefix);
    console.log(`  ${green}✓${reset} Installed ${aCount} agents + config.toml (sandbox modes: read-only for checkers)`);
  }

  if (failures.length > 0) {
    console.error(`\n  ${yellow}Installation incomplete!${reset} Failed: ${failures.join(', ')}`);
    process.exit(1);
  }

  // 4. Scan for leaked .claude paths
  scanForLeakedPaths(targetDir, platform);

  // 5. Generate file manifest for upgrade safety
  generateManifest(targetDir);
  console.log(`  ${green}✓${reset} Generated learnship-file-manifest.json`);

  // 6. Post-install tips
  const firstCmd = platform === 'windsurf' ? '/ls' :
                   platform === 'claude'   ? '/learnship:ls' :
                   platform === 'opencode' ? '/learnship-ls' :
                   platform === 'gemini'   ? '/learnship:ls' : '$learnship-ls';
  console.log(`\n  ${green}Done!${reset} Open a project in ${label} and run ${cyan}${firstCmd}${reset}.`);
  console.log(`  ${dim}First time? Run ${cyan}${platform === 'windsurf' ? '/new-project' : platform === 'claude' ? '/learnship:new-project' : platform === 'opencode' ? '/learnship-new-project' : platform === 'gemini' ? '/learnship:new-project' : '$learnship-new-project'}${reset}${dim} to initialize your project and create AGENTS.md.${reset}`);
  if (platform !== 'windsurf') {
    console.log(`  ${dim}Enable parallel subagents: add ${cyan}"parallelization": true${reset}${dim} to .planning/config.json${reset}`);
  }
}

// ─── Uninstall function ────────────────────────────────────────────────────
function uninstall(platform, isGlobal) {
  const targetDir = targetOverride || (isGlobal ? getGlobalDir(platform) : path.join(process.cwd(), getDirName(platform)));
  const label = getPlatformLabel(platform);
  const locationLabel = targetDir.replace(os.homedir(), '~');
  console.log(`\n  Uninstalling learnship from ${cyan}${label}${reset} at ${cyan}${locationLabel}${reset}\n`);

  if (!fs.existsSync(targetDir)) {
    console.log(`  ${yellow}⚠${reset} Directory not found — nothing to uninstall.`);
    return;
  }

  let removed = 0;

  // 1. Remove learnship/ payload
  const learnshipDir = path.join(targetDir, 'learnship');
  if (fs.existsSync(learnshipDir)) {
    fs.rmSync(learnshipDir, { recursive: true });
    console.log(`  ${green}✓${reset} Removed learnship/`);
    removed++;
  }

  // 2. Remove platform-specific command files
  if (platform === 'claude' || platform === 'windsurf') {
    const commandsDir = path.join(targetDir, 'commands', 'learnship');
    if (fs.existsSync(commandsDir)) { fs.rmSync(commandsDir, { recursive: true }); removed++; console.log(`  ${green}✓${reset} Removed commands/learnship/`); }
  }
  if (platform === 'claude') {
    // Remove skills installed to ~/.claude/skills/ (post-1.9.23)
    for (const skillName of ['agentic-learning', 'impeccable']) {
      const skillDir = path.join(targetDir, 'skills', skillName);
      if (fs.existsSync(skillDir)) {
        fs.rmSync(skillDir, { recursive: true });
        removed++;
        console.log(`  ${green}✓${reset} Removed skills/${skillName}/`);
      }
    }
    // Remove legacy plugins/learnship/ from pre-1.9.23 installs
    const pluginDir = path.join(targetDir, 'plugins', 'learnship');
    if (fs.existsSync(pluginDir)) {
      fs.rmSync(pluginDir, { recursive: true });
      removed++;
      console.log(`  ${green}✓${reset} Removed plugins/learnship/ (legacy)`);
    }
  }
  if (platform === 'opencode') {
    const commandDir = path.join(targetDir, 'command');
    if (fs.existsSync(commandDir)) {
      let n = 0;
      for (const f of fs.readdirSync(commandDir)) {
        if (f.startsWith('learnship-') && f.endsWith('.md')) { fs.unlinkSync(path.join(commandDir, f)); n++; }
      }
      if (n > 0) { removed++; console.log(`  ${green}✓${reset} Removed ${n} learnship-*.md from command/`); }
    }
    // Clean opencode.json permissions
    const ocConfig = path.join(targetDir, 'opencode.json');
    if (fs.existsSync(ocConfig)) {
      try {
        const cfg = JSON.parse(fs.readFileSync(ocConfig, 'utf8'));
        let modified = false;
        if (cfg.permission) {
          for (const permType of ['read', 'external_directory']) {
            if (cfg.permission[permType]) {
              for (const key of Object.keys(cfg.permission[permType])) {
                if (key.includes('learnship')) { delete cfg.permission[permType][key]; modified = true; }
              }
              if (Object.keys(cfg.permission[permType]).length === 0) delete cfg.permission[permType];
            }
          }
          if (Object.keys(cfg.permission).length === 0) delete cfg.permission;
        }
        if (modified) { fs.writeFileSync(ocConfig, JSON.stringify(cfg, null, 2) + '\n'); removed++; console.log(`  ${green}✓${reset} Removed learnship permissions from opencode.json`); }
      } catch { /* ignore */ }
    }
  }
  if (platform === 'gemini') {
    const commandsDir = path.join(targetDir, 'commands', 'learnship');
    if (fs.existsSync(commandsDir)) { fs.rmSync(commandsDir, { recursive: true }); removed++; console.log(`  ${green}✓${reset} Removed commands/learnship/`); }
  }
  if (platform === 'codex') {
    // Remove skill directories
    const skillsDir = path.join(targetDir, 'skills');
    if (fs.existsSync(skillsDir)) {
      let n = 0;
      for (const entry of fs.readdirSync(skillsDir, { withFileTypes: true })) {
        if (entry.isDirectory() && entry.name.startsWith('learnship-')) {
          fs.rmSync(path.join(skillsDir, entry.name), { recursive: true }); n++;
        }
      }
      if (n > 0) { removed++; console.log(`  ${green}✓${reset} Removed ${n} learnship skill directories`); }
    }
    // Remove agent .toml files
    const agentsDir2 = path.join(targetDir, 'agents');
    if (fs.existsSync(agentsDir2)) {
      let n = 0;
      for (const f of fs.readdirSync(agentsDir2)) {
        if (f.startsWith('learnship-') && f.endsWith('.toml')) { fs.unlinkSync(path.join(agentsDir2, f)); n++; }
      }
      if (n > 0) { removed++; console.log(`  ${green}✓${reset} Removed ${n} agent .toml configs`); }
    }
    // Clean config.toml
    const configPath = path.join(targetDir, 'config.toml');
    if (fs.existsSync(configPath)) {
      const content = fs.readFileSync(configPath, 'utf8');
      const cleaned = stripLearnshipFromCodexConfig(content);
      if (cleaned === null) {
        fs.unlinkSync(configPath); removed++;
        console.log(`  ${green}✓${reset} Removed config.toml (was learnship-only)`);
      } else if (cleaned !== content) {
        fs.writeFileSync(configPath, cleaned); removed++;
        console.log(`  ${green}✓${reset} Cleaned learnship sections from config.toml`);
      }
    }
  }

  // 3. Remove learnship agent .md files
  const agentsDir = path.join(targetDir, 'agents');
  if (fs.existsSync(agentsDir)) {
    let n = 0;
    for (const f of fs.readdirSync(agentsDir)) {
      if (f.startsWith('learnship-') && f.endsWith('.md')) { fs.unlinkSync(path.join(agentsDir, f)); n++; }
    }
    if (n > 0) { removed++; console.log(`  ${green}✓${reset} Removed ${n} learnship agent files`); }
  }

  // 4. Remove hooks and settings.json entries (Claude Code / Gemini)
  if (platform === 'claude' || platform === 'gemini') {
    uninstallClaudeHooks(targetDir);
    removed++;
  }

  // 5. Remove file manifest and local patches
  const manifestPath = path.join(targetDir, 'learnship-file-manifest.json');
  if (fs.existsSync(manifestPath)) { fs.unlinkSync(manifestPath); removed++; console.log(`  ${green}✓${reset} Removed learnship-file-manifest.json`); }
  const patchesDir = path.join(targetDir, 'learnship-local-patches');
  if (fs.existsSync(patchesDir)) { fs.rmSync(patchesDir, { recursive: true }); removed++; console.log(`  ${green}✓${reset} Removed learnship-local-patches/`); }

  if (removed === 0) console.log(`  ${yellow}⚠${reset} No learnship files found.`);
  else console.log(`\n  ${green}Done!${reset} learnship uninstalled from ${label}. Your other files and settings were preserved.`);
}

// ─── Interactive prompt ────────────────────────────────────────────────────
async function promptUser() {
  const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
  const ask = (q) => new Promise(resolve => rl.question(q, resolve));

  console.log(`  ${yellow}Select platform:${reset}`);
  console.log(`    1) Claude Code  (/learnship:ls)`);
  console.log(`    2) OpenCode     (/learnship-ls)`);
  console.log(`    3) Gemini CLI   (/learnship:ls)`);
  console.log(`    4) Codex CLI    ($learnship-ls)`);
  console.log(`    5) Windsurf     (/ls — same as install.sh)`);
  console.log(`    6) All platforms`);

  const platformChoice = await ask('\n  Platform [1-6]: ');
  const platformMap = { '1': ['claude'], '2': ['opencode'], '3': ['gemini'], '4': ['codex'], '5': ['windsurf'], '6': ['claude','opencode','gemini','codex','windsurf'] };
  const platforms = platformMap[platformChoice.trim()] || ['claude'];

  console.log(`\n  ${yellow}Install scope:${reset}`);
  console.log(`    1) Global (recommended) — available in all projects`);
  console.log(`    2) Local — current project only`);
  const scopeChoice = await ask('\n  Scope [1-2]: ');
  const isGlobal = scopeChoice.trim() !== '2';

  rl.close();
  return { platforms, isGlobal };
}

// ─── Entry point ──────────────────────────────────────────────────────────
async function main() {
  console.log(banner);

  if (hasHelp) { console.log(helpText); process.exit(0); }

  let platforms = selectedPlatforms;
  let isGlobal = hasGlobal || !hasLocal;

  if (platforms.length === 0 && !hasUninstall) {
    // Interactive
    const result = await promptUser();
    platforms = result.platforms;
    isGlobal = result.isGlobal;
  } else if (platforms.length === 0 && hasUninstall) {
    console.error(`  ${yellow}Error:${reset} Specify a platform to uninstall from. Example: npx learnship --claude --global --uninstall`);
    process.exit(1);
  }

  console.log('');
  for (const platform of platforms) {
    if (hasUninstall) uninstall(platform, isGlobal);
    else install(platform, isGlobal);
  }
}

if (!process.env.LEARNSHIP_TEST_MODE) {
  main().catch(err => {
    console.error(`  Error: ${err.message}`);
    process.exit(1);
  });
}

// Test-only exports — allow unit testing without running main install logic
if (process.env.LEARNSHIP_TEST_MODE) {
  module.exports = {
    convertToOpencode,
    convertToGeminiToml,
    convertToCodexSkill,
    convertClaudeAgentToCodexAgent,
    convertAgentForGemini,
    generateCodexConfigBlock,
    stripLearnshipFromCodexConfig,
    mergeCodexConfig,
    installCodexAgents,
    parseJsonc,
    replacePaths,
    rewriteNewProject,
    rewriteAgentsMd,
    installClaudeSkills,
    installClaudeHooks,
    uninstallClaudeHooks,
    generateManifest,
    saveLocalPatches,
    toHomePrefix,
    LEARNSHIP_CODEX_MARKER,
    CODEX_AGENT_SANDBOX,
  };
}
