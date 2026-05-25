#!/usr/bin/env bash
# learnship — Security validation
#
# Scans all files that become part of LLM agent context for:
#   1. Prompt injection patterns — instruction overrides, role manipulation, fake boundaries
#   2. Secrets and credentials — API keys, tokens, passwords in source
#   3. Exfiltration patterns — curl/fetch to external URLs in agent context
#   4. Invisible Unicode — zero-width chars that could hide instructions
#   5. Base64-encoded payloads — suspiciously long base64 strings
#   6. Dangerous shell patterns — rm -rf, eval, exec in workflow instructions
#   7. Cross-platform installed output — injection patterns must not appear after install

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC_WF="$REPO_DIR/learnship/workflows"
SRC_AG="$REPO_DIR/learnship/agents"
SRC_TPL="$REPO_DIR/learnship/templates"
CURSOR_MDC="$REPO_DIR/cursor-rules/learnship.mdc"
PASS=0
FAIL=0
ERRORS=()

check() {
  local description="$1"
  shift
  if "$@" > /dev/null 2>&1; then
    echo "  ✓ $description"
    PASS=$((PASS+1))
  else
    echo "  ✗ $description"
    FAIL=$((FAIL+1))
    ERRORS+=("$description")
  fi
}

echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo " Security Validation"
echo "═══════════════════════════════════════════════════════════════════"

# ─── 1. Prompt Injection Scan ─────────────────────────────────────────
# Scan all agent-context files for known injection patterns.
# These files are version-controlled source — any injection here
# would ship to every user's AI agent context.

echo ""
echo "─── Prompt Injection Scan ────────────────────────────────────────"

node -e "
const fs=require('fs'),path=require('path');
const dirs=['$SRC_WF','$SRC_AG','$SRC_TPL'];
const errs=[];

// Injection patterns — regex patterns that should NEVER appear in shipped content
const patterns=[
  // Instruction override
  {re:/ignore\s+(all\s+)?(previous|prior|above|earlier)\s+(instructions|prompts|rules|directives)/gi, desc:'instruction override'},
  {re:/disregard\s+(all\s+)?(previous|prior|above)\s+(instructions|prompts|rules)/gi, desc:'instruction disregard'},
  {re:/forget\s+(all\s+)?(previous|prior|above)\s+(instructions|prompts|rules|context)/gi, desc:'forget instructions'},

  // Role manipulation
  {re:/you\s+are\s+now\s+(a|an|my)\s+/gi, desc:'role manipulation (you are now)'},
  {re:/from\s+now\s+on\s+(you|pretend|act|behave)/gi, desc:'role manipulation (from now on)'},
  {re:/pretend\s+(you\s+are|to\s+be)\s+/gi, desc:'role manipulation (pretend)'},

  // System prompt extraction
  {re:/output\s+(your|the)\s+(system\s+)?(prompt|instructions)/gi, desc:'prompt extraction (output)'},
  {re:/reveal\s+(your|the)\s+(system\s+)?(prompt|instructions)/gi, desc:'prompt extraction (reveal)'},
  {re:/repeat\s+(your|the|all)\s+(system\s+)?(prompt|instructions|rules)/gi, desc:'prompt extraction (repeat)'},

  // Fake message boundaries (in source code, not in docs about them)
  {re:/<\/?system>/gi, desc:'fake <system> boundary'},
  {re:/<\/?assistant>/gi, desc:'fake <assistant> boundary'},
  {re:/<\/?human>/gi, desc:'fake <human> boundary'},
  {re:/\[SYSTEM\]/g, desc:'fake [SYSTEM] marker'},
  {re:/\[INST\]/g, desc:'fake [INST] marker'},
  {re:/<<SYS>>/g, desc:'fake <<SYS>> marker'},

  // Jailbreak patterns
  {re:/do\s+anything\s+now/gi, desc:'DAN jailbreak'},
  {re:/DAN\s+mode/gi, desc:'DAN mode'},
  {re:/developer\s+mode\s+(enabled|output|activated)/gi, desc:'developer mode jailbreak'},
  {re:/jailbreak/gi, desc:'jailbreak keyword'},
  {re:/bypass\s+(safety|content|security)\s+(filter|check|rule|guard)/gi, desc:'bypass safety'},
];

// Allowlist — files that legitimately discuss these patterns
const allowlist=new Set([
  'security.md',        // security template discusses threats
  'security-auditor.md', // STRIDE threat modeling uses 'pretend to be someone else'
]);

for(const dir of dirs){
  if(!fs.existsSync(dir))continue;
  const files=fs.readdirSync(dir).filter(f=>f.endsWith('.md'));
  for(const file of files){
    if(allowlist.has(file))continue;
    const c=fs.readFileSync(path.join(dir,file),'utf8');
    for(const{re,desc}of patterns){
      re.lastIndex=0;
      const match=re.exec(c);
      if(match){
        errs.push(file+': '+desc+' — \"'+match[0].substring(0,60)+'\"');
      }
    }
  }
}

if(errs.length){errs.forEach(e=>console.error('  - '+e));process.exit(1);}
console.log('OK — scanned '+dirs.length+' directories');
" && { echo "  ✓ No prompt injection patterns in workflows, agents, or templates"; PASS=$((PASS+1)); } || { echo "  ✗ Prompt injection patterns found"; FAIL=$((FAIL+1)); ERRORS+=("Prompt injection patterns found"); }

# Also scan Cursor .mdc
node -e "
const fs=require('fs');
const c=fs.readFileSync('$CURSOR_MDC','utf8');
const patterns=[
  /ignore\s+(all\s+)?(previous|prior|above)\s+(instructions|prompts|rules)/gi,
  /you\s+are\s+now\s+(a|an|my)\s+/gi,
  /jailbreak/gi,
  /\[SYSTEM\]/g,
  /<<SYS>>/g,
];
const errs=[];
for(const p of patterns){
  p.lastIndex=0;
  if(p.test(c))errs.push('Cursor .mdc: matches '+p.source);
}
if(errs.length){errs.forEach(e=>console.error('  - '+e));process.exit(1);}
" && { echo "  ✓ Cursor .mdc clean of injection patterns"; PASS=$((PASS+1)); } || { echo "  ✗ Cursor .mdc has injection patterns"; FAIL=$((FAIL+1)); ERRORS+=("Cursor .mdc injection patterns"); }

# ─── 2. Secrets and Credentials Scan ──────────────────────────────────
# No API keys, tokens, passwords, or credentials in source files.

echo ""
echo "─── Secrets and Credentials Scan ─────────────────────────────────"

node -e "
const fs=require('fs'),path=require('path');
const dirs=['$SRC_WF','$SRC_AG','$SRC_TPL','$REPO_DIR/bin','$REPO_DIR/cursor-rules'];
const errs=[];

const secretPatterns=[
  // API keys — common formats
  {re:/(?:api[_-]?key|apikey)\s*[:=]\s*['\"][a-zA-Z0-9_\-]{20,}/gi, desc:'API key literal'},
  {re:/(?:secret|token)\s*[:=]\s*['\"][a-zA-Z0-9_\-]{20,}/gi, desc:'secret/token literal'},

  // AWS keys
  {re:/AKIA[0-9A-Z]{16}/g, desc:'AWS access key'},

  // GitHub tokens
  {re:/ghp_[a-zA-Z0-9]{36}/g, desc:'GitHub personal access token'},
  {re:/gho_[a-zA-Z0-9]{36}/g, desc:'GitHub OAuth token'},
  {re:/github_pat_[a-zA-Z0-9_]{22,}/g, desc:'GitHub fine-grained PAT'},

  // npm tokens
  {re:/npm_[a-zA-Z0-9]{36}/g, desc:'npm token'},

  // Private keys
  {re:/-----BEGIN\s+(RSA\s+)?PRIVATE\s+KEY-----/g, desc:'private key'},
  {re:/-----BEGIN\s+OPENSSH\s+PRIVATE\s+KEY-----/g, desc:'SSH private key'},

  // Passwords in connection strings
  {re:/(?:password|passwd|pwd)\s*[:=]\s*['\"][^'\"]{8,}/gi, desc:'password literal'},
  {re:/[a-z]+:\/\/[^:\[]+:[^@\[]{8,}@/g, desc:'credentials in URL'},
];

function scanDir(dir){
  if(!fs.existsSync(dir))return;
  for(const f of fs.readdirSync(dir)){
    const fp=path.join(dir,f);
    const stat=fs.statSync(fp);
    if(stat.isDirectory())continue;
    if(!/\.(md|js|json|mdc|sh)$/.test(f))continue;
    const c=fs.readFileSync(fp,'utf8');
    for(const{re,desc}of secretPatterns){
      re.lastIndex=0;
      const match=re.exec(c);
      if(match){
        errs.push(path.relative('$REPO_DIR',fp)+': '+desc+' — \"'+match[0].substring(0,40)+'...\"');
      }
    }
  }
}

dirs.forEach(scanDir);

if(errs.length){errs.forEach(e=>console.error('  - '+e));process.exit(1);}
console.log('OK');
" && { echo "  ✓ No secrets or credentials in source files"; PASS=$((PASS+1)); } || { echo "  ✗ Secrets or credentials found in source files"; FAIL=$((FAIL+1)); ERRORS+=("Secrets found in source files"); }

# ─── 3. Exfiltration Pattern Scan ────────────────────────────────────
# No curl/fetch/wget to external URLs in agent context files.
# Legitimate web search instructions use platform tools, not raw HTTP calls.

echo ""
echo "─── Exfiltration Pattern Scan ────────────────────────────────────"

node -e "
const fs=require('fs'),path=require('path');
const dirs=['$SRC_WF','$SRC_AG'];
const errs=[];

const exfilPatterns=[
  // Direct HTTP calls to external URLs (not localhost)
  {re:/curl\s+(-[sSkLfX]+\s+)*https?:\/\/(?!localhost|127\.0\.0\.1)/gi, desc:'curl to external URL'},
  {re:/wget\s+https?:\/\/(?!localhost|127\.0\.0\.1)/gi, desc:'wget to external URL'},
  {re:/fetch\s*\(\s*['\"]https?:\/\/(?!localhost|127\.0\.0\.1)/gi, desc:'fetch() to external URL'},

  // Data exfiltration via DNS
  {re:/nslookup\s+/gi, desc:'DNS exfiltration (nslookup)'},
  {re:/dig\s+.*\.\s+TXT/gi, desc:'DNS exfiltration (dig TXT)'},
];

// Allowlist — workflows that legitimately discuss external API calls
const allowlist=new Set(['ship.md','release.md']);

for(const dir of dirs){
  if(!fs.existsSync(dir))continue;
  const files=fs.readdirSync(dir).filter(f=>f.endsWith('.md'));
  for(const file of files){
    if(allowlist.has(file))continue;
    const c=fs.readFileSync(path.join(dir,file),'utf8');
    for(const{re,desc}of exfilPatterns){
      re.lastIndex=0;
      const match=re.exec(c);
      if(match){
        errs.push(file+': '+desc+' — \"'+match[0].substring(0,60)+'\"');
      }
    }
  }
}

if(errs.length){errs.forEach(e=>console.error('  - '+e));process.exit(1);}
console.log('OK');
" && { echo "  ✓ No exfiltration patterns in workflows or agents"; PASS=$((PASS+1)); } || { echo "  ✗ Exfiltration patterns found"; FAIL=$((FAIL+1)); ERRORS+=("Exfiltration patterns found"); }

# ─── 4. Invisible Unicode Detection ──────────────────────────────────
# Zero-width chars, directional overrides, and other invisible Unicode
# that could hide malicious instructions in seemingly clean files.

echo ""
echo "─── Invisible Unicode Detection ──────────────────────────────────"

node -e "
const fs=require('fs'),path=require('path');
const dirs=['$SRC_WF','$SRC_AG','$SRC_TPL','$REPO_DIR/cursor-rules'];
const errs=[];

// Dangerous invisible Unicode ranges
const invisibleRe=/[\u200B-\u200F\u2028-\u202F\u2060-\u2064\uFEFF\u00AD\u2066-\u2069]/;

for(const dir of dirs){
  if(!fs.existsSync(dir))continue;
  const files=fs.readdirSync(dir).filter(f=>f.endsWith('.md')||f.endsWith('.mdc'));
  for(const file of files){
    const c=fs.readFileSync(path.join(dir,file),'utf8');
    if(invisibleRe.test(c)){
      const lines=c.split('\n');
      const badLines=[];
      lines.forEach((l,i)=>{if(invisibleRe.test(l))badLines.push(i+1);});
      errs.push(file+': invisible Unicode on line(s) '+badLines.join(', '));
    }
  }
}

if(errs.length){errs.forEach(e=>console.error('  - '+e));process.exit(1);}
console.log('OK');
" && { echo "  ✓ No invisible Unicode characters in agent context files"; PASS=$((PASS+1)); } || { echo "  ✗ Invisible Unicode found"; FAIL=$((FAIL+1)); ERRORS+=("Invisible Unicode found"); }

# ─── 5. Base64 Payload Detection ─────────────────────────────────────
# Suspiciously long base64 strings could encode hidden instructions.
# Short base64 is fine (e.g., git SHAs), but >100 chars is suspicious.

echo ""
echo "─── Base64 Payload Detection ─────────────────────────────────────"

node -e "
const fs=require('fs'),path=require('path');
const dirs=['$SRC_WF','$SRC_AG'];
const errs=[];

// Match base64 strings >100 chars that aren't in code blocks explaining base64
const b64Re=/(?<![a-zA-Z0-9\/+])[A-Za-z0-9+\/]{100,}={0,2}(?![a-zA-Z0-9\/+])/g;

for(const dir of dirs){
  if(!fs.existsSync(dir))continue;
  const files=fs.readdirSync(dir).filter(f=>f.endsWith('.md'));
  for(const file of files){
    const c=fs.readFileSync(path.join(dir,file),'utf8');
    const matches=[...c.matchAll(b64Re)];
    if(matches.length>0){
      errs.push(file+': '+matches.length+' suspicious base64 payload(s) (>100 chars)');
    }
  }
}

if(errs.length){errs.forEach(e=>console.error('  - '+e));process.exit(1);}
console.log('OK');
" && { echo "  ✓ No suspicious base64 payloads in workflows or agents"; PASS=$((PASS+1)); } || { echo "  ✗ Suspicious base64 payloads found"; FAIL=$((FAIL+1)); ERRORS+=("Suspicious base64 payloads found"); }

# ─── 6. Dangerous Shell Patterns ─────────────────────────────────────
# Workflows contain node -e scripts and git commands, but should NOT
# contain destructive shell patterns that could damage user systems.

echo ""
echo "─── Dangerous Shell Patterns ─────────────────────────────────────"

node -e "
const fs=require('fs'),path=require('path');
const wfDir='$SRC_WF';
const errs=[];

const dangerPatterns=[
  {re:/rm\s+-rf\s+\//g, desc:'rm -rf / (root filesystem deletion)'},
  {re:/rm\s+-rf\s+~\//g, desc:'rm -rf ~/ (home directory deletion)'},
  {re:/rm\s+-rf\s+\\\$HOME/g, desc:'rm -rf \$HOME (home directory deletion)'},
  {re:/mkfs\./g, desc:'mkfs (disk format)'},
  {re:/dd\s+if=.*of=\/dev\//g, desc:'dd to device (disk overwrite)'},
  {re:/:\s*>\s*\/etc\//g, desc:'truncate /etc/ files'},
  {re:/chmod\s+-R\s+777\s+\//g, desc:'chmod 777 root'},
];

const files=fs.readdirSync(wfDir).filter(f=>f.endsWith('.md'));
for(const file of files){
  const c=fs.readFileSync(path.join(wfDir,file),'utf8');
  for(const{re,desc}of dangerPatterns){
    re.lastIndex=0;
    if(re.test(c)){
      errs.push(file+': '+desc);
    }
  }
}

if(errs.length){errs.forEach(e=>console.error('  - '+e));process.exit(1);}
console.log('OK');
" && { echo "  ✓ No dangerous shell patterns in workflows"; PASS=$((PASS+1)); } || { echo "  ✗ Dangerous shell patterns found in workflows"; FAIL=$((FAIL+1)); ERRORS+=("Dangerous shell patterns in workflows"); }

# ─── 7. GitHub Actions Security ───────────────────────────────────────
# No ${{ }} expressions in run: blocks (injection risk).
# No hardcoded secrets in workflow files.

echo ""
echo "─── GitHub Actions Security ──────────────────────────────────────"

node -e "
const fs=require('fs'),path=require('path');
const ghDir='$REPO_DIR/.github/workflows';
const errs=[];

const files=fs.readdirSync(ghDir).filter(f=>f.endsWith('.yml')||f.endsWith('.yaml'));
for(const file of files){
  const c=fs.readFileSync(path.join(ghDir,file),'utf8');
  const lines=c.split('\n');

  let inRun=false;
  for(let i=0;i<lines.length;i++){
    const line=lines[i];

    // Detect run: blocks
    if(/^\s+run:\s/.test(line)){inRun=true;}
    else if(/^\s+\w+:/.test(line)&&!/^\s+-/.test(line)){inRun=false;}

    // Check for \${{ }} in run blocks (except env refs which are safe)
    if(inRun && /\\\$\\{\\{(?!\s*env\.)/.test(line)){
      errs.push(file+':'+( i+1)+': \${{ }} in run: block (use env: mapping instead)');
    }
  }

  // Check for hardcoded secrets (not using secrets.*)
  const secretRe=/(?:NPM_TOKEN|GH_PAT|GITHUB_TOKEN)\s*[:=]\s*['\"][a-zA-Z0-9]/g;
  if(secretRe.test(c)){
    errs.push(file+': hardcoded secret value');
  }
}

if(errs.length){errs.forEach(e=>console.error('  - '+e));process.exit(1);}
console.log('OK');
" && { echo "  ✓ GitHub Actions workflows follow security best practices"; PASS=$((PASS+1)); } || { echo "  ✗ GitHub Actions security issues found"; FAIL=$((FAIL+1)); ERRORS+=("GitHub Actions security issues"); }

# Verify secrets use secrets.* context
node -e "
const fs=require('fs'),path=require('path');
const ghDir='$REPO_DIR/.github/workflows';
const files=fs.readdirSync(ghDir).filter(f=>f.endsWith('.yml'));
const errs=[];
for(const file of files){
  const c=fs.readFileSync(path.join(ghDir,file),'utf8');
  // If file references NPM_TOKEN or GH_PAT, it must use secrets.* context
  if(c.includes('NPM_TOKEN')&&!c.includes('secrets.NPM_TOKEN')){
    errs.push(file+': NPM_TOKEN not via secrets context');
  }
  if(c.includes('GH_PAT')&&!c.includes('secrets.GH_PAT')){
    errs.push(file+': GH_PAT not via secrets context');
  }
}
if(errs.length){errs.forEach(e=>console.error('  - '+e));process.exit(1);}
console.log('OK');
" && { echo "  ✓ All secrets use proper secrets.* context in CI"; PASS=$((PASS+1)); } || { echo "  ✗ Secrets not using secrets.* context"; FAIL=$((FAIL+1)); ERRORS+=("Secrets not using secrets context"); }

# ─── 8. install.js Security ──────────────────────────────────────────
# The installer must not contain hardcoded credentials or use eval().

echo ""
echo "─── Installer Security ─────────────────────────────────────────"

INSTALLER="$REPO_DIR/bin/install.js"
check "install.js: no eval() calls" node -e "
const c=require('fs').readFileSync('$INSTALLER','utf8');
if(/\beval\s*\(/.test(c))process.exit(1);
"

check "install.js: no Function() constructor" node -e "
const c=require('fs').readFileSync('$INSTALLER','utf8');
if(/\bnew\s+Function\s*\(/.test(c))process.exit(1);
"

check "install.js: no hardcoded API keys" node -e "
const c=require('fs').readFileSync('$INSTALLER','utf8');
if(/(?:api[_-]?key|token|secret)\s*[:=]\s*['\"][a-zA-Z0-9_\-]{20,}/gi.test(c))process.exit(1);
"

# ─── 9. Cross-Platform Installed Output Security ─────────────────────
# Verify that injection patterns don't appear in installed output.

echo ""
echo "─── Installed Output Security ────────────────────────────────────"

TMPBASE=$(mktemp -d)
# shellcheck disable=SC2064
trap "rm -rf $TMPBASE" EXIT

# Install Windsurf as representative platform
mkdir -p "$TMPBASE/ws"
node "$REPO_DIR/bin/install.js" --windsurf --target "$TMPBASE/ws" > /dev/null 2>&1

node -e "
const fs=require('fs'),path=require('path');
const wfDir='$TMPBASE/ws/workflows';
if(!fs.existsSync(wfDir)){console.error('No workflows dir');process.exit(1);}
const errs=[];
const injection=[
  /ignore\s+all\s+previous\s+instructions/gi,
  /you\s+are\s+now\s+a\s+/gi,
  /\[SYSTEM\]/g,
  /jailbreak/gi,
];

const files=fs.readdirSync(wfDir).filter(f=>f.endsWith('.md'));
for(const file of files){
  const c=fs.readFileSync(path.join(wfDir,file),'utf8');
  for(const re of injection){
    re.lastIndex=0;
    if(re.test(c))errs.push(file+': injection pattern in installed output — '+re.source);
  }
}

if(errs.length){errs.forEach(e=>console.error('  - '+e));process.exit(1);}
console.log('OK — '+files.length+' installed workflows clean');
" && { echo "  ✓ Installed Windsurf output clean of injection patterns"; PASS=$((PASS+1)); } || { echo "  ✗ Injection patterns in installed output"; FAIL=$((FAIL+1)); ERRORS+=("Injection in installed output"); }

# ─── 10. References and Skills Injection Scan ─────────────────────────
# These files also become LLM context — scan them for injection patterns.

echo ""
echo "─── References & Skills Injection Scan ───────────────────────────"

node -e "
const fs=require('fs'),path=require('path');
const dirs=['$REPO_DIR/learnship/references','$REPO_DIR/skills/agentic-learning','$REPO_DIR/skills/agentic-learning/references'];
const errs=[];
const patterns=[
  /ignore\s+(all\s+)?(previous|prior|above)\s+(instructions|prompts|rules)/gi,
  /you\s+are\s+now\s+(a|an|my)\s+/gi,
  /from\s+now\s+on\s+(you|pretend|act)/gi,
  /\[SYSTEM\]/g,
  /<<SYS>>/g,
  /jailbreak/gi,
  /bypass\s+(safety|content|security)\s+(filter|check|rule|guard)/gi,
];
for(const dir of dirs){
  if(!fs.existsSync(dir))continue;
  const files=fs.readdirSync(dir).filter(f=>f.endsWith('.md'));
  for(const file of files){
    const c=fs.readFileSync(path.join(dir,file),'utf8');
    for(const re of patterns){
      re.lastIndex=0;
      if(re.test(c))errs.push(file+': injection pattern — '+re.source);
    }
  }
}
if(errs.length){errs.forEach(e=>console.error('  - '+e));process.exit(1);}
console.log('OK');
" && { echo "  ✓ References and skills clean of injection patterns"; PASS=$((PASS+1)); } || { echo "  ✗ Injection patterns in references/skills"; FAIL=$((FAIL+1)); ERRORS+=("Injection in references/skills"); }

# Also scan impeccable skill (21 action dirs)
node -e "
const fs=require('fs'),path=require('path');
const base='$REPO_DIR/skills/impeccable';
const errs=[];
const patterns=[
  /ignore\s+(all\s+)?(previous|prior|above)\s+(instructions|prompts|rules)/gi,
  /you\s+are\s+now\s+(a|an|my)\s+/gi,
  /\[SYSTEM\]/g,
  /jailbreak/gi,
];
function scan(dir){
  if(!fs.existsSync(dir))return;
  for(const e of fs.readdirSync(dir,{withFileTypes:true})){
    const fp=path.join(dir,e.name);
    if(e.isDirectory()){scan(fp);}
    else if(e.name.endsWith('.md')){
      const c=fs.readFileSync(fp,'utf8');
      for(const re of patterns){
        re.lastIndex=0;
        if(re.test(c))errs.push(path.relative(base,fp)+': '+re.source);
      }
    }
  }
}
scan(base);
if(errs.length){errs.forEach(e=>console.error('  - '+e));process.exit(1);}
console.log('OK');
" && { echo "  ✓ Impeccable skill clean of injection patterns"; PASS=$((PASS+1)); } || { echo "  ✗ Injection in impeccable skill"; FAIL=$((FAIL+1)); ERRORS+=("Injection in impeccable skill"); }

# ─── 11. Hook Files Secrets Scan ──────────────────────────────────────
# Hook JS files run on user machines — must not contain secrets.

echo ""
echo "─── Hook Files Secrets Scan ──────────────────────────────────────"

node -e "
const fs=require('fs'),path=require('path');
const dir='$REPO_DIR/hooks';
const errs=[];
const secretPatterns=[
  {re:/(?:api[_-]?key|apikey)\s*[:=]\s*['\"][a-zA-Z0-9_\-]{20,}/gi, desc:'API key'},
  {re:/(?:secret|token)\s*[:=]\s*['\"][a-zA-Z0-9_\-]{20,}/gi, desc:'secret/token'},
  {re:/AKIA[0-9A-Z]{16}/g, desc:'AWS key'},
  {re:/ghp_[a-zA-Z0-9]{36}/g, desc:'GitHub PAT'},
  {re:/-----BEGIN\s+(RSA\s+)?PRIVATE\s+KEY-----/g, desc:'private key'},
  {re:/(?:password|passwd)\s*[:=]\s*['\"][^'\"]{8,}/gi, desc:'password'},
];
for(const f of fs.readdirSync(dir).filter(f=>f.endsWith('.js')||f.endsWith('.json'))){
  const c=fs.readFileSync(path.join(dir,f),'utf8');
  for(const{re,desc}of secretPatterns){
    re.lastIndex=0;
    if(re.test(c))errs.push(f+': '+desc);
  }
}
if(errs.length){errs.forEach(e=>console.error('  - '+e));process.exit(1);}
console.log('OK');
" && { echo "  ✓ Hook files clean of secrets"; PASS=$((PASS+1)); } || { echo "  ✗ Secrets found in hook files"; FAIL=$((FAIL+1)); ERRORS+=("Secrets in hooks"); }

# ─── 12. AGENTS.md Template Injection Scan ────────────────────────────
# The AGENTS.md template becomes every user's project AGENTS.md.

echo ""
echo "─── AGENTS.md Template Scan ──────────────────────────────────────"

check "AGENTS.md template: no injection patterns" node -e "
const fs=require('fs');
const tpl=fs.readFileSync('$REPO_DIR/learnship/templates/agents.md','utf8');
const patterns=[
  /ignore\s+(all\s+)?(previous|prior|above)\s+(instructions|prompts|rules)/gi,
  /you\s+are\s+now\s+(a|an|my)\s+/gi,
  /\[SYSTEM\]/g,
  /jailbreak/gi,
];
for(const re of patterns){
  re.lastIndex=0;
  if(re.test(tpl)){console.error('AGENTS.md template: '+re.source);process.exit(1);}
}
"

# ─── 13. Markdown HTML Injection ──────────────────────────────────────
# Raw <script>, <iframe>, <img onerror> in .md files could cause XSS
# if any tool renders the markdown in a webview.

echo ""
echo "─── Markdown HTML Injection Scan ─────────────────────────────────"

node -e "
const fs=require('fs'),path=require('path');
const dirs=['$SRC_WF','$SRC_AG','$SRC_TPL','$REPO_DIR/learnship/references','$REPO_DIR/learnship/contexts'];
const errs=[];
// Files that legitimately discuss HTML event handlers (React component verification patterns)
const htmlAllowlist=new Set(['verification-patterns.md']);
const htmlPatterns=[
  {re:/<script[\s>]/gi, desc:'<script> tag'},
  {re:/<iframe[\s>]/gi, desc:'<iframe> tag'},
  {re:/<object[\s>]/gi, desc:'<object> tag'},
  {re:/<embed[\s>]/gi, desc:'<embed> tag'},
  {re:/onerror\s*=/gi, desc:'onerror handler'},
  {re:/onload\s*=/gi, desc:'onload handler'},
  {re:/onclick\s*=/gi, desc:'onclick handler'},
  {re:/javascript\s*:/gi, desc:'javascript: protocol'},
];
for(const dir of dirs){
  if(!fs.existsSync(dir))continue;
  const files=fs.readdirSync(dir).filter(f=>f.endsWith('.md'));
  for(const file of files){
    if(htmlAllowlist.has(file))continue;
    const c=fs.readFileSync(path.join(dir,file),'utf8');
    for(const{re,desc}of htmlPatterns){
      re.lastIndex=0;
      if(re.test(c))errs.push(file+': '+desc);
    }
  }
}
if(errs.length){errs.forEach(e=>console.error('  - '+e));process.exit(1);}
console.log('OK');
" && { echo "  ✓ No HTML injection in markdown files"; PASS=$((PASS+1)); } || { echo "  ✗ HTML injection found in markdown files"; FAIL=$((FAIL+1)); ERRORS+=("HTML injection in markdown"); }

# ─── 14. Prototype Pollution in Config Template ──────────────────────
# __proto__, constructor, or prototype keys in config.json could
# poison the runtime if parsed naively.

echo ""
echo "─── Prototype Pollution Check ────────────────────────────────────"

check "config template: no __proto__ key" node -e "
const c=require('fs').readFileSync('$REPO_DIR/templates/config.json','utf8');
if(c.includes('__proto__'))process.exit(1);
if(c.includes('constructor'))process.exit(1);
if(c.includes('prototype'))process.exit(1);
"

# Also check that the settings.md embedded config is clean
check "settings.md embedded config: no prototype pollution" node -e "
const c=require('fs').readFileSync('$SRC_WF/settings.md','utf8');
if(c.includes('__proto__'))process.exit(1);
// 'constructor' appears in legitimate text, so only check inside JSON blocks
const jsonBlocks=[...c.matchAll(/\x60\x60\x60(?:json)?\\n([\\s\\S]*?)\x60\x60\x60/g)];
for(const m of jsonBlocks){
  if(m[1].includes('__proto__'))process.exit(1);
}
"

# ─── 15. Installed Output Scan — All Platforms ───────────────────────
# Install.js transforms could introduce injection on any platform.
# Scan all 5 platforms, not just Windsurf.

echo ""
echo "─── Installed Output Scan — All Platforms ────────────────────────"

TMPALL=$(mktemp -d)
for p in windsurf claude opencode gemini codex; do
  mkdir -p "$TMPALL/$p"
  node "$REPO_DIR/bin/install.js" "--$p" --target "$TMPALL/$p" > /dev/null 2>&1
done

node -e "
const fs=require('fs'),path=require('path');
const platforms={
  windsurf:'$TMPALL/windsurf/workflows',
  claude:'$TMPALL/claude/learnship/workflows',
  opencode:'$TMPALL/opencode/learnship/workflows',
  gemini:'$TMPALL/gemini/learnship/workflows',
  codex:'$TMPALL/codex/learnship/workflows',
};
const injection=[
  /ignore\s+all\s+previous\s+instructions/gi,
  /you\s+are\s+now\s+a\s+/gi,
  /\[SYSTEM\]/g,
  /jailbreak/gi,
];
const errs=[];
for(const[platform,wfDir]of Object.entries(platforms)){
  if(!fs.existsSync(wfDir))continue;
  const files=fs.readdirSync(wfDir).filter(f=>f.endsWith('.md'));
  for(const file of files){
    const c=fs.readFileSync(path.join(wfDir,file),'utf8');
    for(const re of injection){
      re.lastIndex=0;
      if(re.test(c))errs.push(platform+'/'+file+': '+re.source);
    }
  }
}
if(errs.length){errs.forEach(e=>console.error('  - '+e));process.exit(1);}
console.log('OK — all 5 platforms clean');
" && { echo "  ✓ All 5 platform installed outputs clean"; PASS=$((PASS+1)); } || { echo "  ✗ Injection patterns in installed output"; FAIL=$((FAIL+1)); ERRORS+=("Injection in multi-platform output"); }

rm -rf "$TMPALL"

# ─── 16. File Permission Checks ──────────────────────────────────────
# Hook scripts must be executable. Installed workflows should not be
# world-writable.

echo ""
echo "─── File Permission Checks ───────────────────────────────────────"

check "hooks/session-start: executable" test -x "$REPO_DIR/hooks/session-start"

# Hook JS files should NOT be world-writable
for hook in learnship-statusline.js learnship-context-monitor.js learnship-prompt-guard.js learnship-session-state.js; do
  check "hook $hook: not world-writable" node -e "
    const fs=require('fs');
    const mode=fs.statSync('$REPO_DIR/hooks/$hook').mode;
    const worldWrite=mode&0o002;
    if(worldWrite)process.exit(1);
  "
done

# install.js should not be world-writable
check "bin/install.js: not world-writable" node -e "
  const fs=require('fs');
  const mode=fs.statSync('$REPO_DIR/bin/install.js').mode;
  if(mode&0o002)process.exit(1);
"

# ─── 17. --target Path Boundary Enforcement ───────────────────────────
# install.js must refuse system paths and bare $HOME so a typo or hostile
# arg can't trigger fs.rmSync on something important.

echo ""
echo "─── --target Path Boundary Enforcement ───────────────────────────"

INSTALLER="$REPO_DIR/bin/install.js"

# Refuses root filesystem
check_must_fail() {
  local description="$1"
  shift
  if "$@" > /dev/null 2>&1; then
    echo "  ✗ $description (expected exit !=0 but got 0)"
    FAIL=$((FAIL+1))
    ERRORS+=("$description")
  else
    echo "  ✓ $description"
    PASS=$((PASS+1))
  fi
}

check_must_fail "install.js: refuses --target /" node "$INSTALLER" --claude --target /
check_must_fail "install.js: refuses --target /etc" node "$INSTALLER" --claude --target /etc
check_must_fail "install.js: refuses --target /usr/local" node "$INSTALLER" --claude --target /usr/local
check_must_fail "install.js: refuses --target \$HOME directly" node "$INSTALLER" --claude --target "$HOME"

# Accepts valid paths (under /tmp and under cwd)
TMPGOOD=$(mktemp -d)
check "install.js: accepts --target under /tmp" node "$INSTALLER" --claude --target "$TMPGOOD"
rm -rf "$TMPGOOD"

# ─── 18. Manifest Path-Traversal Protection ───────────────────────────
# saveLocalPatches must refuse manifest entries with '../' or absolute paths
# so a malicious learnship-file-manifest.json can't be used to back up
# sensitive files outside the install root.

echo ""
echo "─── Manifest Path-Traversal Protection ───────────────────────────"

TMPMANI=$(mktemp -d)
# Set up a fake install with a corrupted manifest containing dangerous paths
mkdir -p "$TMPMANI/learnship"
echo "ok" > "$TMPMANI/learnship/safe.md"
# Create a target file outside the install root that a traversal would expose
echo "SECRET" > "$TMPMANI/secret.txt"
cat > "$TMPMANI/learnship-file-manifest.json" <<'EOF'
{
  "version": "test",
  "files": {
    "learnship/safe.md": "deadbeef0000000000000000000000000000000000000000000000000000beef",
    "../secret.txt": "deadbeef0000000000000000000000000000000000000000000000000000beef",
    "/etc/passwd": "deadbeef0000000000000000000000000000000000000000000000000000beef"
  }
}
EOF

# Run saveLocalPatches via LEARNSHIP_TEST_MODE export
LEARNSHIP_TEST_MODE=1 node -e "
const { saveLocalPatches } = require('$INSTALLER');
const modified = saveLocalPatches('$TMPMANI');
// safe.md should be backed up (hash mismatch), but '../secret.txt' must be skipped
const fs = require('fs');
const path = require('path');
const escaped = fs.existsSync(path.join('$TMPMANI', 'secret.txt-backup'))
  || fs.existsSync(path.join('$TMPMANI', '..', 'secret.txt-backup'));
if (escaped) { console.error('Path traversal succeeded'); process.exit(1); }
// Refused entries must NOT appear in the modified list
if (modified.includes('../secret.txt') || modified.includes('/etc/passwd')) {
  console.error('Unsafe manifest entry was processed: ' + modified.filter(m => m.includes('..') || m.startsWith('/')).join(', '));
  process.exit(1);
}
" 2>&1
if [ $? -eq 0 ]; then
  echo "  ✓ saveLocalPatches refuses ../ and absolute manifest paths"
  PASS=$((PASS+1))
else
  echo "  ✗ saveLocalPatches allowed path traversal"
  FAIL=$((FAIL+1))
  ERRORS+=("saveLocalPatches allowed path traversal")
fi
rm -rf "$TMPMANI"

echo ""
echo "─── Results ──────────────────────────────────────────────────────"
echo "  Passed: $PASS"
echo "  Failed: $FAIL"

if [ ${#ERRORS[@]} -gt 0 ]; then
  echo ""
  echo "  Failures:"
  for err in "${ERRORS[@]}"; do
    echo "    - $err"
  done
fi

echo ""
[ "$FAIL" -eq 0 ] && echo "  ALL TESTS PASSED ✓" || { echo "  TESTS FAILED ✗"; exit 1; }
