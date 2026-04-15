#!/usr/bin/env node
// learnship-hook-version: 2.2.0
// Session State — SessionStart hook
// Injects project state reminder on every session start for orientation.
// Also checks for learnship updates in the background.

const fs = require('fs');
const path = require('path');
const os = require('os');
const { spawn } = require('child_process');

// --- Session state injection ---

function getStateContext() {
  const lines = [];

  if (fs.existsSync('.planning/STATE.md')) {
    lines.push('## Project State Reminder');
    lines.push('');
    lines.push('STATE.md exists - check for blockers and current phase.');
    try {
      const content = fs.readFileSync('.planning/STATE.md', 'utf8');
      const head = content.split('\n').slice(0, 20).join('\n');
      lines.push(head);
    } catch (e) {}
  } else {
    lines.push('No .planning/ found - suggest /new-project if starting new work.');
  }

  lines.push('');

  if (fs.existsSync('.planning/config.json')) {
    try {
      const config = JSON.parse(fs.readFileSync('.planning/config.json', 'utf8'));
      if (config.mode) lines.push(`Config: mode="${config.mode}"`);
      if (config.context) lines.push(`Context profile: ${config.context}`);
    } catch (e) {}
  }

  return lines.join('\n');
}

// --- Update check (background, non-blocking) ---

function checkForUpdates(configDir) {
  const cacheDir = path.join(os.homedir(), '.cache', 'learnship');
  try { fs.mkdirSync(cacheDir, { recursive: true }); } catch (e) {}

  const versionFile = path.join(configDir, 'learnship', 'VERSION');
  let installed = '0.0.0';
  try {
    if (fs.existsSync(versionFile)) {
      installed = fs.readFileSync(versionFile, 'utf8').trim();
    }
  } catch (e) {}

  const cacheFile = path.join(cacheDir, 'update-check.json');

  const child = spawn(process.execPath, ['-e', `
    const fs = require('fs');
    const { execSync } = require('child_process');

    function isNewer(a, b) {
      const pa = (a || '').split('.').map(s => Number(s.replace(/-.*/, '')) || 0);
      const pb = (b || '').split('.').map(s => Number(s.replace(/-.*/, '')) || 0);
      for (let i = 0; i < 3; i++) {
        if (pa[i] > pb[i]) return true;
        if (pa[i] < pb[i]) return false;
      }
      return false;
    }

    const installed = ${JSON.stringify(installed)};
    const cacheFile = ${JSON.stringify(cacheFile)};

    let latest = null;
    try {
      latest = execSync('npm view learnship version', { encoding: 'utf8', timeout: 10000, windowsHide: true }).trim();
    } catch (e) {}

    const result = {
      update_available: latest && isNewer(latest, installed),
      installed,
      latest: latest || 'unknown',
      checked: Math.floor(Date.now() / 1000)
    };

    fs.writeFileSync(cacheFile, JSON.stringify(result));
  `], {
    stdio: 'ignore',
    windowsHide: true,
    detached: true
  });

  child.unref();
}

// --- Main ---

let input = '';
const stdinTimeout = setTimeout(() => process.exit(0), 3000);
process.stdin.setEncoding('utf8');
process.stdin.on('data', chunk => input += chunk);
process.stdin.on('end', () => {
  clearTimeout(stdinTimeout);
  try {
    const data = JSON.parse(input);
    const cwd = data.cwd || process.cwd();

    // Determine config directory
    const homeDir = os.homedir();
    let configDir = process.env.CLAUDE_CONFIG_DIR || path.join(homeDir, '.claude');
    // Also check project-local .claude/
    const localConfigDir = path.join(cwd, '.claude');
    if (fs.existsSync(path.join(localConfigDir, 'learnship', 'VERSION'))) {
      configDir = localConfigDir;
    }

    // Fire background update check
    checkForUpdates(configDir);

    // Build state context
    const stateContext = getStateContext();

    const output = {
      hookSpecificOutput: {
        hookEventName: 'SessionStart',
        additionalContext: stateContext
      }
    };

    process.stdout.write(JSON.stringify(output));
  } catch (e) {
    process.exit(0);
  }
});
