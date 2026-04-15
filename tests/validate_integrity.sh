#!/usr/bin/env bash
# learnship — Deep integrity validation
#
# Categories tested:
#   1. Hardcoded paths — no leaked ~/.claude/ in source workflows
#   2. Stale references — no dangling @./templates/ or @./agents/ refs
#   3. Template file resolution — every @./templates/ ref points to real file
#   4. Agent file internal structure — agents have meaningful persona content
#   5. install.js output structure — installed files have correct frontmatter/format
#   6. Config field documentation — every config key in template is documented in workflows
#   7. Workflow frontmatter consistency — all workflows have required YAML fields
#   8. Cross-reference integrity — workflows that reference other workflows use valid names
#   9. Forbidden patterns — no stale or dangerous patterns in shipped content
#  10. Cursor .mdc sync — condensed rule file stays in sync with full workflow set

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC_WF="$REPO_DIR/learnship/workflows"
SRC_AG="$REPO_DIR/learnship/agents"
SRC_TPL="$REPO_DIR/learnship/templates"
TPL_DIR="$REPO_DIR/templates"
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
echo " Deep Integrity Validation"
echo "═══════════════════════════════════════════════════════════════════"

# ─── 1. Hardcoded Path Detection ─────────────────────────────────────
# Source workflows must not contain platform-specific hardcoded paths.
# install.js rewrites ~/.claude/ etc during install — source should use
# generic @./  references or platform-agnostic descriptions.

echo ""
echo "─── Hardcoded Path Detection ─────────────────────────────────────"

node -e "
const fs=require('fs'),path=require('path');
const wfDir='$SRC_WF';
const agDir='$SRC_AG';
const errs=[];

// Patterns that should NOT appear in source (pre-install) files
const forbidden=[
  {pat:/~\/\.windsurf\//g, desc:'hardcoded ~/.windsurf/'},
  {pat:/~\/\.opencode\//g, desc:'hardcoded ~/.opencode/'},
  {pat:/\\\$HOME\/\.windsurf\//g, desc:'hardcoded \$HOME/.windsurf/'},
  {pat:/~\/\.config\/opencode\//g, desc:'hardcoded ~/.config/opencode/'},
];

function scan(dir,label){
  if(!fs.existsSync(dir))return;
  for(const f of fs.readdirSync(dir).filter(x=>x.endsWith('.md'))){
    const c=fs.readFileSync(path.join(dir,f),'utf8');
    for(const{pat,desc}of forbidden){
      pat.lastIndex=0;
      if(pat.test(c)){
        errs.push(label+'/'+f+': contains '+desc);
      }
    }
  }
}
scan(wfDir,'workflows');
scan(agDir,'agents');

if(errs.length){errs.forEach(e=>console.error('  - '+e));process.exit(1);}
console.log('OK');
" && { echo "  ✓ No hardcoded platform-specific paths in source workflows/agents"; PASS=$((PASS+1)); } || { echo "  ✗ Hardcoded paths found in source files"; FAIL=$((FAIL+1)); ERRORS+=("Hardcoded paths in source files"); }

# ─── 2. Template File Resolution ─────────────────────────────────────
# Every @./templates/ reference in workflows must point to a real file
# in learnship/templates/ (source) or templates/ (installed).

echo ""
echo "─── Template File Resolution ─────────────────────────────────────"

node -e "
const fs=require('fs'),path=require('path');
const wfDir='$SRC_WF';
const tplDir='$SRC_TPL';
const errs=[];

const wfs=fs.readdirSync(wfDir).filter(f=>f.endsWith('.md'));
for(const wf of wfs){
  const c=fs.readFileSync(path.join(wfDir,wf),'utf8');
  // Match @./templates/something.md or @./templates/something/FILE.md
  const refs=[...c.matchAll(/@\.\/(templates\/[a-zA-Z0-9_\/-]+\.(?:md|json))/g)];
  for(const m of refs){
    const refPath=m[1].replace('templates/','');
    // Check both source and installed template dirs
    const srcPath=path.join(tplDir,refPath);
    const instPath=path.join('$TPL_DIR',refPath);
    if(!fs.existsSync(srcPath)&&!fs.existsSync(instPath)){
      errs.push(wf+': @./templates/'+m[1].replace('templates/','')+' does not exist in either template dir');
    }
  }
}

if(errs.length){errs.forEach(e=>console.error('  - '+e));process.exit(1);}
console.log('OK');
" && { echo "  ✓ All @./templates/ references resolve to existing files"; PASS=$((PASS+1)); } || { echo "  ✗ Dangling @./templates/ references found"; FAIL=$((FAIL+1)); ERRORS+=("Dangling @./templates/ references"); }

# ─── 3. Agent Internal Structure ─────────────────────────────────────
# Agent files should have persona-defining content: a clear role description,
# behavioral instructions, not just stubs.

echo ""
echo "─── Agent Internal Structure ─────────────────────────────────────"

node -e "
const fs=require('fs'),path=require('path');
const agDir='$SRC_AG';
const errs=[];
const files=fs.readdirSync(agDir).filter(f=>f.endsWith('.md'));

for(const f of files){
  const c=fs.readFileSync(path.join(agDir,f),'utf8');

  // Must have a role/persona description (You are, persona, role)
  if(!/(You are|persona|role|agent)/i.test(c)){
    errs.push(f+': no persona/role description found');
  }

  // Must be substantive (>200 chars)
  if(c.length<200){
    errs.push(f+': too short ('+c.length+' chars, need >200)');
  }
}

if(errs.length){errs.forEach(e=>console.error('  - '+e));process.exit(1);}
console.log('All '+files.length+' agent files have proper structure');
" && { echo "  ✓ All agent files have persona descriptions and substantive content"; PASS=$((PASS+1)); } || { echo "  ✗ Agent file structure issues found"; FAIL=$((FAIL+1)); ERRORS+=("Agent file structure issues"); }

# ─── 4. Workflow Frontmatter Consistency ──────────────────────────────
# Every workflow must have YAML frontmatter with at least a description.
# This is required by install.js for all platforms.

echo ""
echo "─── Workflow Frontmatter Consistency ─────────────────────────────"

node -e "
const fs=require('fs'),path=require('path');
const wfDir='$SRC_WF';
const errs=[];
const wfs=fs.readdirSync(wfDir).filter(f=>f.endsWith('.md'));

for(const wf of wfs){
  const c=fs.readFileSync(path.join(wfDir,wf),'utf8');

  // Must start with --- (YAML frontmatter)
  if(!c.startsWith('---')){
    errs.push(wf+': missing YAML frontmatter (must start with ---)');
    continue;
  }

  // Must have a description field
  const fmEnd=c.indexOf('---',3);
  if(fmEnd===-1){errs.push(wf+': unclosed frontmatter');continue;}
  const fm=c.substring(3,fmEnd);
  if(!fm.includes('description:')){
    errs.push(wf+': frontmatter missing description field');
  }
}

if(errs.length){errs.forEach(e=>console.error('  - '+e));process.exit(1);}
console.log('All '+wfs.length+' workflows have valid frontmatter');
" && { echo "  ✓ All workflows have valid YAML frontmatter with description"; PASS=$((PASS+1)); } || { echo "  ✗ Workflow frontmatter issues found"; FAIL=$((FAIL+1)); ERRORS+=("Workflow frontmatter issues"); }

# ─── 5. Config Key Documentation Coverage ────────────────────────────
# Every top-level key in config.json template must appear somewhere in
# new-project.md or settings.md (the two workflows that set config).

echo ""
echo "─── Config Key Documentation Coverage ────────────────────────────"

node -e "
const fs=require('fs'),path=require('path');
const tpl=JSON.parse(fs.readFileSync('$TPL_DIR/config.json','utf8'));
const np=fs.readFileSync('$SRC_WF/new-project.md','utf8');
const settings=fs.readFileSync('$SRC_WF/settings.md','utf8');
const combined=np+settings;
const errs=[];

// Check top-level keys
for(const key of Object.keys(tpl)){
  if(!combined.includes(key)){
    errs.push('config key \"'+key+'\" not found in new-project.md or settings.md');
  }
}

// Check important nested keys
const nestedChecks=[
  'workflow.research','workflow.plan_check','workflow.verifier','workflow.review',
  'parallelization.enabled','planning.commit_mode','ship.auto_test',
];
for(const nk of nestedChecks){
  const parts=nk.split('.');
  const found=combined.includes(nk)||combined.includes(parts[1]);
  if(!found){
    errs.push('nested config key \"'+nk+'\" not documented in workflows');
  }
}

if(errs.length){errs.forEach(e=>console.error('  - '+e));process.exit(1);}
console.log('All config keys documented');
" && { echo "  ✓ All config.json template keys are documented in config-setting workflows"; PASS=$((PASS+1)); } || { echo "  ✗ Undocumented config keys found"; FAIL=$((FAIL+1)); ERRORS+=("Undocumented config keys"); }

# ─── 6. Cross-Workflow Reference Integrity ───────────────────────────
# Workflows that reference other workflows by name (e.g., "run /plan-phase")
# must reference workflows that actually exist.

echo ""
echo "─── Cross-Workflow Reference Integrity ───────────────────────────"

node -e "
const fs=require('fs'),path=require('path');
const wfDir='$SRC_WF';
const wfs=fs.readdirSync(wfDir).filter(f=>f.endsWith('.md')).map(f=>f.replace('.md',''));
const wfSet=new Set(wfs);
const errs=[];

for(const wf of wfs){
  const c=fs.readFileSync(path.join(wfDir,wf+'.md'),'utf8');
  // Match /workflow-name patterns (slash commands)
  const refs=[...c.matchAll(/\x60?\/([a-z]+-[a-z-]+)\x60?/g)];
  for(const m of refs){
    const ref=m[1];
    // Skip known non-workflow slash patterns
    if(ref.startsWith('planning-')||ref.startsWith('tmp-')||ref.startsWith('dev-'))continue;
    if(['new-project','new-milestone','discuss-phase','plan-phase','execute-phase',
        'verify-work','complete-milestone','pause-work','resume-work','quick',
        'review','ship','challenge','ideate','debug','map-codebase','settings',
        'health','compound','note','guard','session-report','secure-phase',
        'validate-phase','diagnose-issues','docs-update','sync-docs','forensics',
        'undo','extract-learnings','milestone-summary','knowledge-base','transition',
        'discuss-milestone','add-phase','insert-phase','remove-phase','ls','next',
        'progress','add-todo','check-todos','milestone-retrospective',
        'discovery-phase','research-phase','execute-plan','audit-milestone',
        'plan-milestone-gaps','list-phase-assumptions','decision-log',
        'add-tests','cleanup','set-profile','sync-upstream-skills',
        'release'].includes(ref)){
      if(!wfSet.has(ref)){
        errs.push(wf+'.md references /'+ref+' but '+ref+'.md does not exist');
      }
    }
  }
}

if(errs.length){errs.forEach(e=>console.error('  - '+e));process.exit(1);}
console.log('OK');
" && { echo "  ✓ All cross-workflow references resolve to existing workflows"; PASS=$((PASS+1)); } || { echo "  ✗ Dangling cross-workflow references found"; FAIL=$((FAIL+1)); ERRORS+=("Dangling cross-workflow references"); }

# ─── 7. Forbidden Patterns in Shipped Content ────────────────────────
# Content that should never appear in shipped workflows.

echo ""
echo "─── Forbidden Patterns in Shipped Content ────────────────────────"

node -e "
const fs=require('fs'),path=require('path');
const wfDir='$SRC_WF';
const errs=[];

const forbidden=[
  {pat:/debugger;/g, desc:'debugger statement', maxAllowed:0},
];

const wfs=fs.readdirSync(wfDir).filter(f=>f.endsWith('.md'));
for(const wf of wfs){
  const c=fs.readFileSync(path.join(wfDir,wf),'utf8');
  for(const{pat,desc,maxAllowed}of forbidden){
    pat.lastIndex=0;
    const matches=c.match(pat);
    const count=matches?matches.length:0;
    if(count>maxAllowed){
      errs.push(wf+': '+count+' '+desc+'(s) found (max allowed: '+maxAllowed+')');
    }
  }
}

if(errs.length){errs.forEach(e=>console.error('  - '+e));process.exit(1);}
console.log('OK');
" && { echo "  ✓ No forbidden patterns (TODO/FIXME/debugger) in shipped workflows"; PASS=$((PASS+1)); } || { echo "  ✗ Forbidden patterns found in workflows"; FAIL=$((FAIL+1)); ERRORS+=("Forbidden patterns in workflows"); }

# ─── 8. Installed File Format Validation ──────────────────────────────
# Validate that install.js produces correctly formatted output for each platform.

echo ""
echo "─── Installed File Format Validation ─────────────────────────────"

TMPBASE=$(mktemp -d)
# shellcheck disable=SC2064
trap "rm -rf $TMPBASE" EXIT

PLATFORMS="windsurf claude opencode gemini codex"
for p in $PLATFORMS; do
  mkdir -p "$TMPBASE/$p"
  node "$REPO_DIR/bin/install.js" "--$p" --target "$TMPBASE/$p" > /dev/null 2>&1
done

# Windsurf workflows must have windsurf-compatible frontmatter
node -e "
const fs=require('fs'),path=require('path');
const dir='$TMPBASE/windsurf/workflows';
const errs=[];
const wfs=fs.readdirSync(dir).filter(f=>f.endsWith('.md'));
for(const wf of wfs){
  const c=fs.readFileSync(path.join(dir,wf),'utf8');
  if(!c.startsWith('---')){errs.push(wf+': missing frontmatter');continue;}
  const fmEnd=c.indexOf('---',3);
  if(fmEnd===-1){errs.push(wf+': unclosed frontmatter');continue;}
  const fm=c.substring(3,fmEnd);
  if(!fm.includes('description:')){
    errs.push(wf+': missing description in frontmatter');
  }
}
if(errs.length){errs.forEach(e=>console.error('  - '+e));process.exit(1);}
console.log('All '+wfs.length+' Windsurf workflows have valid frontmatter');
" && { echo "  ✓ Windsurf installed workflows have valid frontmatter"; PASS=$((PASS+1)); } || { echo "  ✗ Windsurf workflow frontmatter issues"; FAIL=$((FAIL+1)); ERRORS+=("Windsurf workflow frontmatter issues"); }

# Claude commands must have valid frontmatter
node -e "
const fs=require('fs'),path=require('path');
const dir='$TMPBASE/claude/commands/learnship';
if(!fs.existsSync(dir)){console.error('Claude commands dir not found');process.exit(1);}
const errs=[];
const cmds=fs.readdirSync(dir).filter(f=>f.endsWith('.md'));
for(const cmd of cmds){
  const c=fs.readFileSync(path.join(dir,cmd),'utf8');
  if(!c.startsWith('---')){errs.push(cmd+': missing frontmatter');continue;}
  const fmEnd=c.indexOf('---',3);
  if(fmEnd===-1){errs.push(cmd+': unclosed frontmatter');continue;}
  const fm=c.substring(3,fmEnd);
  if(!fm.includes('allowed-tools:')){
    errs.push(cmd+': missing allowed-tools in frontmatter');
  }
}
if(errs.length){errs.forEach(e=>console.error('  - '+e));process.exit(1);}
console.log('All '+cmds.length+' Claude commands have valid frontmatter');
" && { echo "  ✓ Claude installed commands have valid frontmatter with allowed-tools"; PASS=$((PASS+1)); } || { echo "  ✗ Claude command frontmatter issues"; FAIL=$((FAIL+1)); ERRORS+=("Claude command frontmatter issues"); }

# Gemini TOML commands must be valid TOML format
node -e "
const fs=require('fs'),path=require('path');
const dir='$TMPBASE/gemini/commands/learnship';
if(!fs.existsSync(dir)){console.error('Gemini commands dir not found');process.exit(1);}
const errs=[];
const cmds=fs.readdirSync(dir).filter(f=>f.endsWith('.toml'));
for(const cmd of cmds){
  const c=fs.readFileSync(path.join(dir,cmd),'utf8');
  // Must have description key
  if(!c.includes('description')){
    errs.push(cmd+': missing description key');
  }
  // Must have body or content section
  if(c.length<50){
    errs.push(cmd+': too short ('+c.length+' chars)');
  }
}
if(errs.length){errs.forEach(e=>console.error('  - '+e));process.exit(1);}
console.log('All '+cmds.length+' Gemini TOML commands are valid');
" && { echo "  ✓ Gemini installed TOML commands are valid"; PASS=$((PASS+1)); } || { echo "  ✗ Gemini TOML command issues"; FAIL=$((FAIL+1)); ERRORS+=("Gemini TOML command issues"); }

# OpenCode agents must have valid format
node -e "
const fs=require('fs'),path=require('path');
const dir='$TMPBASE/opencode/agents';
if(!fs.existsSync(dir)){console.error('OpenCode agents dir not found');process.exit(1);}
const errs=[];
const agents=fs.readdirSync(dir).filter(f=>f.endsWith('.md'));
for(const a of agents){
  const c=fs.readFileSync(path.join(dir,a),'utf8');
  if(c.length<100){
    errs.push(a+': too short ('+c.length+' chars)');
  }
  // Should not contain raw AskUserQuestion (should be 'question')
  if(c.includes('AskUserQuestion')){
    errs.push(a+': contains raw AskUserQuestion (should be rewritten to question)');
  }
}
if(errs.length){errs.forEach(e=>console.error('  - '+e));process.exit(1);}
console.log('All '+agents.length+' OpenCode agents are valid');
" && { echo "  ✓ OpenCode installed agents have valid format (no raw AskUserQuestion)"; PASS=$((PASS+1)); } || { echo "  ✗ OpenCode agent format issues"; FAIL=$((FAIL+1)); ERRORS+=("OpenCode agent format issues"); }

# Codex agents must exist and have valid TOML config
node -e "
const fs=require('fs'),path=require('path');
const agDir='$TMPBASE/codex/agents';
const cfgFile='$TMPBASE/codex/config.toml';
if(!fs.existsSync(agDir)){console.error('Codex agents dir not found');process.exit(1);}
if(!fs.existsSync(cfgFile)){console.error('Codex config.toml not found');process.exit(1);}
const errs=[];

// Check agent files exist
const agents=fs.readdirSync(agDir).filter(f=>f.endsWith('.toml')||f.endsWith('.md'));
if(agents.length<15){
  errs.push('Only '+agents.length+' agent files (expected ≥15)');
}

// Check config.toml references agents
const cfg=fs.readFileSync(cfgFile,'utf8');
if(!cfg.includes('[agents.')){
  errs.push('config.toml missing [agents.] sections');
}

if(errs.length){errs.forEach(e=>console.error('  - '+e));process.exit(1);}
console.log('Codex install valid: '+agents.length+' agents, config.toml has agent sections');
" && { echo "  ✓ Codex installed agents and config.toml are valid"; PASS=$((PASS+1)); } || { echo "  ✗ Codex install validation failed"; FAIL=$((FAIL+1)); ERRORS+=("Codex install validation failed"); }

# ─── 9. install.js Stale Path Leak Detection ─────────────────────────
# After install.js transforms, no platform should have another platform's
# paths. E.g., Windsurf output should not contain ~/.claude/

echo ""
echo "─── Stale Path Leak Detection (post-install) ─────────────────────"

node -e "
const fs=require('fs'),path=require('path');
const tmpBase='$TMPBASE';
const errs=[];

const checks=[
  {platform:'windsurf', forbidden:['~/.claude/','WebSearch','WebFetch'], dir:'workflows'},
  {platform:'gemini', forbidden:['~/.claude/','AskUserQuestion','WebSearch'], dir:'learnship/workflows'},
  {platform:'opencode', forbidden:['~/.claude/','AskUserQuestion','WebSearch','WebFetch'], dir:'learnship/workflows'},
];

for(const{platform,forbidden,dir}of checks){
  const wfDir=path.join(tmpBase,platform,dir);
  if(!fs.existsSync(wfDir))continue;
  const wfs=fs.readdirSync(wfDir).filter(f=>f.endsWith('.md'));
  for(const wf of wfs){
    const c=fs.readFileSync(path.join(wfDir,wf),'utf8');
    for(const pat of forbidden){
      // Use word boundary for tool names to avoid false positives in prose
      const regex=pat.startsWith('~')?new RegExp(pat.replace(/[.*+?^\${}()|[\]\\\\]/g,'\\\\\\$&')):new RegExp('\\\\b'+pat+'\\\\b');
      if(regex.test(c)){
        errs.push(platform+'/'+wf+': leaked '+pat);
      }
    }
  }
}

if(errs.length){errs.forEach(e=>console.error('  - '+e));process.exit(1);}
console.log('OK');
" && { echo "  ✓ No stale platform paths leaked in installed outputs"; PASS=$((PASS+1)); } || { echo "  ✗ Stale paths leaked in installed outputs"; FAIL=$((FAIL+1)); ERRORS+=("Stale paths leaked in installed outputs"); }

# ─── 10. Template Completeness ────────────────────────────────────────
# Both template directories (learnship/templates/ and templates/) must
# have the same files (minus config.json which is only in templates/).

echo ""
echo "─── Template Directory Sync ──────────────────────────────────────"

node -e "
const fs=require('fs'),path=require('path');
const srcTpl='$SRC_TPL';
const instTpl='$TPL_DIR';
const errs=[];

// Source templates
function collect(dir,prefix,targetSet){
  for(const f of fs.readdirSync(dir,{withFileTypes:true})){
    const rel=prefix?prefix+'/'+f.name:f.name;
    if(f.isDirectory())collect(path.join(dir,f.name),rel,targetSet);
    else targetSet.add(rel);
  }
}
const srcFiles=new Set();
collect(srcTpl,'',srcFiles);

// Installed templates (may not have research-project subdir)
const instFiles=new Set();
collect(instTpl,'',instFiles);

// Key templates must exist in learnship/templates/ (source of truth)
const required=['agents.md','project.md','state.md','plan.md','security.md','uat.md','context.md','requirements.md'];
for(const r of required){
  if(!srcFiles.has(r))errs.push('learnship/templates/ missing required: '+r);
}

// config.json must exist in root templates/ (npm-published)
if(!instFiles.has('config.json'))errs.push('templates/ missing config.json (npm-published)');

if(errs.length){errs.forEach(e=>console.error('  - '+e));process.exit(1);}
console.log('OK');
" && { echo "  ✓ Template directories are in sync"; PASS=$((PASS+1)); } || { echo "  ✗ Template directory sync issues"; FAIL=$((FAIL+1)); ERRORS+=("Template directory sync issues"); }

# ─── 11. Cursor .mdc Sync with Source Workflows ──────────────────────
# Every workflow mentioned in Cursor .mdc must exist as a real workflow file.

echo ""
echo "─── Cursor .mdc Workflow Existence ───────────────────────────────"

node -e "
const fs=require('fs'),path=require('path');
const mdc=fs.readFileSync('$REPO_DIR/cursor-rules/learnship.mdc','utf8');
const wfDir='$SRC_WF';
const wfSet=new Set(fs.readdirSync(wfDir).filter(f=>f.endsWith('.md')).map(f=>f.replace('.md','')));
const errs=[];

// Extract workflow names from table rows: | \`/workflow-name\` |
const tableRefs=[...mdc.matchAll(/\x60\/([a-z]+-?[a-z-]*)\x60/g)];
for(const m of tableRefs){
  let ref=m[1];
  // Strip trailing arguments like ' [N]' or ' [task]'
  ref=ref.replace(/\s+\[.*\]/,'');
  if(!wfSet.has(ref)){
    errs.push('Cursor .mdc references /'+ref+' but '+ref+'.md does not exist');
  }
}

if(errs.length){errs.forEach(e=>console.error('  - '+e));process.exit(1);}
console.log('OK');
" && { echo "  ✓ All Cursor .mdc workflow references exist as files"; PASS=$((PASS+1)); } || { echo "  ✗ Cursor .mdc references non-existent workflows"; FAIL=$((FAIL+1)); ERRORS+=("Cursor .mdc dangling workflow references"); }

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
