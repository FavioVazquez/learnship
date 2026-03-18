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
const hasAll       = args.includes('--all');
const hasGlobal    = args.includes('--global') || args.includes('-g');
const hasLocal     = args.includes('--local')  || args.includes('-l');
const hasUninstall = args.includes('--uninstall') || args.includes('-u');
const hasHelp      = args.includes('--help') || args.includes('-h');

let selectedPlatforms = [];
if (hasAll) {
  selectedPlatforms = ['windsurf', 'claude', 'opencode', 'gemini', 'codex'];
} else {
  if (hasWindsurf) selectedPlatforms.push('windsurf');
  if (hasClaude)   selectedPlatforms.push('claude');
  if (hasOpencode) selectedPlatforms.push('opencode');
  if (hasGemini)   selectedPlatforms.push('gemini');
  if (hasCodex)    selectedPlatforms.push('codex');
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
  ${dim}v${pkg.version} · Windsurf · Claude Code · OpenCode · Gemini CLI · Codex CLI${reset}
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
    ${cyan}--all${reset}         All platforms

  ${yellow}Scope:${reset}
    ${cyan}-g, --global${reset}  Install to global config directory (recommended)
    ${cyan}-l, --local${reset}   Install to current project directory

  ${yellow}Options:${reset}
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
  // Also replace platform-specific dir refs that may appear in source
  if (platform === 'opencode') {
    c = c.replace(/~\/\.opencode\//g, pathPrefix);
  } else if (platform === 'gemini') {
    c = c.replace(/~\/\.gemini\//g, pathPrefix);
  } else if (platform === 'codex') {
    c = c.replace(/~\/\.codex\//g, pathPrefix);
  }
  return c;
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

/** Install Claude Code native plugin skills (plugins/learnship/skills/) */
function installClaudePlugins(skillsSrc, targetDir) {
  const pluginDir = path.join(targetDir, 'plugins', 'learnship');
  const pluginSkillsDir = path.join(pluginDir, 'skills');
  const pluginMetaDir = path.join(pluginDir, '.claude-plugin');

  // Clean install
  if (fs.existsSync(pluginDir)) fs.rmSync(pluginDir, { recursive: true });
  fs.mkdirSync(pluginSkillsDir, { recursive: true });
  fs.mkdirSync(pluginMetaDir, { recursive: true });

  // Write plugin manifest
  const manifest = {
    name: 'learnship',
    description: 'Learnship skills — agentic-learning partner and impeccable design system',
    author: { name: 'favio-vazquez' },
  };
  fs.writeFileSync(
    path.join(pluginMetaDir, 'plugin.json'),
    JSON.stringify(manifest, null, 2) + '\n'
  );

  let count = 0;

  for (const entry of fs.readdirSync(skillsSrc, { withFileTypes: true })) {
    if (!entry.isDirectory()) continue;
    const skillName = entry.name;
    const srcPath = path.join(skillsSrc, skillName);

    if (!fs.existsSync(path.join(srcPath, 'SKILL.md'))) continue;

    const dest = path.join(pluginSkillsDir, skillName);

    if (skillName === 'impeccable') {
      // impeccable: copy root SKILL.md (rewriting sibling paths → references/ paths),
      // then copy each sub-skill dir into references/
      fs.mkdirSync(dest, { recursive: true });
      let skillMdContent = fs.readFileSync(path.join(srcPath, 'SKILL.md'), 'utf8');
      // Rewrite repo-relative sibling links (e.g. adapt/SKILL.md) to post-install references/ paths
      skillMdContent = skillMdContent.replace(/\]\((?!references\/)([^/)][^)]*\/SKILL\.md)\)/g, '](references/$1)');
      fs.writeFileSync(path.join(dest, 'SKILL.md'), skillMdContent);
      const refsDest = path.join(dest, 'references');
      fs.mkdirSync(refsDest, { recursive: true });
      for (const sub of fs.readdirSync(srcPath, { withFileTypes: true })) {
        if (!sub.isDirectory()) continue;
        const subSrc = path.join(srcPath, sub.name);
        const subDest = path.join(refsDest, sub.name);
        if (fs.existsSync(path.join(subSrc, 'SKILL.md'))) {
          copyDir(subSrc, subDest, '', 'claude');
        }
      }
      count++;
    } else {
      // agentic-learning and any future top-level skills — copy verbatim
      copyDir(srcPath, dest, '', 'claude');
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

// ─── Main install function ─────────────────────────────────────────────────
function install(platform, isGlobal) {
  const src = path.join(__dirname, '..');
  const targetDir = isGlobal ? getGlobalDir(platform) : path.join(process.cwd(), getDirName(platform));
  const pathPrefix = `${targetDir.replace(/\\/g, '/')}/learnship/`;
  const label = getPlatformLabel(platform);
  const locationLabel = targetDir.replace(os.homedir(), '~');

  console.log(`\n  Installing for ${cyan}${label}${reset} → ${cyan}${locationLabel}${reset}\n`);

  fs.mkdirSync(targetDir, { recursive: true });

  const learnshipSrc = path.join(src, 'learnship');
  const commandsSrc  = path.join(src, 'commands', 'learnship');
  const agentsSrc    = path.join(src, 'agents');
  const skillsSrc    = path.join(src, '.windsurf', 'skills');
  const failures = [];

  // 1. Install learnship/ payload (workflows, references, templates)
  const learnshipDest = path.join(targetDir, 'learnship');
  copyDir(learnshipSrc, learnshipDest, pathPrefix, platform);
  if (verifyInstalled(learnshipDest, 'learnship/')) {
    console.log(`  ${green}✓${reset} Installed learnship/ (workflows, references, templates)`);
  } else { failures.push('learnship/'); }

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
      fs.copyFileSync(path.join(learnshipSrc, 'workflows', f), path.join(wfDest, f));
      count++;
    }
    // Copy templates/ and references/ so @./templates/ and @./references/ resolve in workflows
    for (const subdir of ['templates', 'references']) {
      const srcSub = path.join(learnshipSrc, subdir);
      const destSub = path.join(wfDest, subdir);
      if (fs.existsSync(srcSub)) {
        copyDir(srcSub, destSub, pathPrefix, platform);
      }
    }
    console.log(`  ${green}✓${reset} Installed ${count} workflows to workflows/`);
  } else if (platform === 'claude') {
    const count = installClaudeCommands(commandsSrc, targetDir, pathPrefix);
    if (verifyInstalled(path.join(targetDir, 'commands', 'learnship'), 'commands/learnship/')) {
      console.log(`  ${green}✓${reset} Installed ${count} commands to commands/learnship/`);
    } else { failures.push('commands/learnship/'); }
    const aCount = installAgents(agentsSrc, targetDir, pathPrefix, 'claude');
    if (aCount > 0) console.log(`  ${green}✓${reset} Installed ${aCount} agents to agents/`);
    else failures.push('agents/');
    const pCount = installClaudePlugins(skillsSrc, targetDir);
    if (pCount > 0) {
      console.log(`  ${green}✓${reset} Installed ${pCount} skills to plugins/learnship/skills/`);
    } else {
      failures.push('plugins/learnship/skills/');
    }
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

  // 5. Post-install tips
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
  const targetDir = isGlobal ? getGlobalDir(platform) : path.join(process.cwd(), getDirName(platform));
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
    const pluginDir = path.join(targetDir, 'plugins', 'learnship');
    if (fs.existsSync(pluginDir)) {
      fs.rmSync(pluginDir, { recursive: true });
      removed++;
      console.log(`  ${green}✓${reset} Removed plugins/learnship/`);
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
    toHomePrefix,
    LEARNSHIP_CODEX_MARKER,
    CODEX_AGENT_SANDBOX,
  };
}
