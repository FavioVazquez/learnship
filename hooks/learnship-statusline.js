#!/usr/bin/env node
// learnship-hook-version: 2.2.0
// learnship Statusline — shows model, project state, directory, and context usage
// Installed by learnship for Claude Code and Gemini CLI.

const fs = require('fs');
const path = require('path');
const os = require('os');

// --- Project state reader ---

function readProjectState(dir) {
  const home = os.homedir();
  let current = dir;
  for (let i = 0; i < 10; i++) {
    const candidate = path.join(current, '.planning', 'STATE.md');
    if (fs.existsSync(candidate)) {
      try {
        return parseStateMd(fs.readFileSync(candidate, 'utf8'));
      } catch (e) {
        return null;
      }
    }
    const parent = path.dirname(current);
    if (parent === current || current === home) break;
    current = parent;
  }
  return null;
}

function parseStateMd(content) {
  const state = {};
  const fmMatch = content.match(/^---\n([\s\S]*?)\n---/);
  if (fmMatch) {
    for (const line of fmMatch[1].split('\n')) {
      const m = line.match(/^(\w+):\s*(.+)/);
      if (!m) continue;
      const [, key, val] = m;
      const v = val.trim().replace(/^["']|["']$/g, '');
      if (key === 'status') state.status = v === 'null' ? null : v;
      if (key === 'milestone') state.milestone = v === 'null' ? null : v;
      if (key === 'milestone_name') state.milestoneName = v === 'null' ? null : v;
    }
  }
  const phaseMatch = content.match(/^Phase:\s*(\d+)\s+of\s+(\d+)(?:\s+\(([^)]+)\))?/m);
  if (phaseMatch) {
    state.phaseNum = phaseMatch[1];
    state.phaseTotal = phaseMatch[2];
    state.phaseName = phaseMatch[3] || null;
  }
  if (!state.status) {
    const bodyStatus = content.match(/^Status:\s*(.+)/m);
    if (bodyStatus) {
      const raw = bodyStatus[1].trim().toLowerCase();
      if (raw.includes('ready to plan') || raw.includes('planning')) state.status = 'planning';
      else if (raw.includes('execut')) state.status = 'executing';
      else if (raw.includes('complet') || raw.includes('archived')) state.status = 'complete';
    }
  }
  return state;
}

function formatProjectState(s) {
  const parts = [];
  if (s.milestone || s.milestoneName) {
    const ver = s.milestone || '';
    const name = (s.milestoneName && s.milestoneName !== 'milestone') ? s.milestoneName : '';
    const ms = [ver, name].filter(Boolean).join(' ');
    if (ms) parts.push(ms);
  }
  if (s.status) parts.push(s.status);
  if (s.phaseNum && s.phaseTotal) {
    const phase = s.phaseName
      ? `${s.phaseName} (${s.phaseNum}/${s.phaseTotal})`
      : `ph ${s.phaseNum}/${s.phaseTotal}`;
    parts.push(phase);
  }
  return parts.join(' \u00b7 ');
}

// --- Main ---

function runStatusline() {
  let input = '';
  const stdinTimeout = setTimeout(() => process.exit(0), 3000);
  process.stdin.setEncoding('utf8');
  process.stdin.on('data', chunk => input += chunk);
  process.stdin.on('end', () => {
    clearTimeout(stdinTimeout);
    try {
      const data = JSON.parse(input);
      const model = data.model?.display_name || 'Claude';
      const dir = data.workspace?.current_dir || process.cwd();
      const session = data.session_id || '';
      const remaining = data.context_window?.remaining_percentage;

      // Context window display (shows USED percentage scaled to usable context)
      const AUTO_COMPACT_BUFFER_PCT = 16.5;
      let ctx = '';
      if (remaining != null) {
        const usableRemaining = Math.max(0, ((remaining - AUTO_COMPACT_BUFFER_PCT) / (100 - AUTO_COMPACT_BUFFER_PCT)) * 100);
        const used = Math.max(0, Math.min(100, Math.round(100 - usableRemaining)));

        // Write bridge file for context-monitor hook
        const sessionSafe = session && !/[/\\]|\.\./.test(session);
        if (sessionSafe) {
          try {
            const bridgePath = path.join(os.tmpdir(), `learnship-ctx-${session}.json`);
            const bridgeData = JSON.stringify({
              session_id: session,
              remaining_percentage: remaining,
              used_pct: used,
              timestamp: Math.floor(Date.now() / 1000)
            });
            fs.writeFileSync(bridgePath, bridgeData);
          } catch (e) {
            // Silent fail — bridge is best-effort
          }
        }

        const filled = Math.floor(used / 10);
        const bar = '\u2588'.repeat(filled) + '\u2591'.repeat(10 - filled);
        if (used < 50) {
          ctx = ` \x1b[32m${bar} ${used}%\x1b[0m`;
        } else if (used < 65) {
          ctx = ` \x1b[33m${bar} ${used}%\x1b[0m`;
        } else if (used < 80) {
          ctx = ` \x1b[38;5;208m${bar} ${used}%\x1b[0m`;
        } else {
          ctx = ` \x1b[5;31m\ud83d\udc80 ${bar} ${used}%\x1b[0m`;
        }
      }

      // Current task from todos
      let task = '';
      const homeDir = os.homedir();
      const claudeDir = process.env.CLAUDE_CONFIG_DIR || path.join(homeDir, '.claude');
      const todosDir = path.join(claudeDir, 'todos');
      if (session && fs.existsSync(todosDir)) {
        try {
          const files = fs.readdirSync(todosDir)
            .filter(f => f.startsWith(session) && f.includes('-agent-') && f.endsWith('.json'))
            .map(f => ({ name: f, mtime: fs.statSync(path.join(todosDir, f)).mtime }))
            .sort((a, b) => b.mtime - a.mtime);
          if (files.length > 0) {
            try {
              const todos = JSON.parse(fs.readFileSync(path.join(todosDir, files[0].name), 'utf8'));
              const inProgress = todos.find(t => t.status === 'in_progress');
              if (inProgress) task = inProgress.activeForm || '';
            } catch (e) {}
          }
        } catch (e) {}
      }

      // Project state (milestone · status · phase)
      const stateStr = task ? '' : formatProjectState(readProjectState(dir) || {});

      // Output
      const dirname = path.basename(dir);
      const middle = task
        ? `\x1b[1m${task}\x1b[0m`
        : stateStr
          ? `\x1b[2m${stateStr}\x1b[0m`
          : null;

      if (middle) {
        process.stdout.write(`\x1b[2m${model}\x1b[0m \u2502 ${middle} \u2502 \x1b[2m${dirname}\x1b[0m${ctx}`);
      } else {
        process.stdout.write(`\x1b[2m${model}\x1b[0m \u2502 \x1b[2m${dirname}\x1b[0m${ctx}`);
      }
    } catch (e) {
      // Silent fail
    }
  });
}

module.exports = { readProjectState, parseStateMd, formatProjectState };

if (require.main === module) runStatusline();
