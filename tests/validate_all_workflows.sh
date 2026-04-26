#!/usr/bin/env bash
# learnship — Comprehensive workflow integrity validation
#
# Validates ALL critical workflows (not just new-project) across all 6 platforms:
#   - Agent persona wiring: every persona_context has @./agents/ ref, files exist
#   - Task() subagent definitions: every Task() has agent_definition block
#   - STOP gates: every AskUserQuestion has a blocking STOP gate
#   - Key structural phrases: must-have content that defines workflow behavior
#   - Cross-platform consistency: content survives install.js for all 5 installable platforms
#   - Cursor .mdc: condensed rule file covers all critical workflows
#
# This catches the class of bugs where:
#   - An edit to one workflow breaks persona wiring
#   - install.js drops content during transforms
#   - Cursor .mdc drifts from the real workflow set

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALLER="$REPO_DIR/bin/install.js"
SRC_WF="$REPO_DIR/learnship/workflows"
SRC_AG="$REPO_DIR/learnship/agents"
TMPBASE=$(mktemp -d)
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

cleanup() { rm -rf "$TMPBASE"; }
trap cleanup EXIT

echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo " All-Workflows Integrity Validation"
echo "═══════════════════════════════════════════════════════════════════"

# ─── Install all 5 platforms to temp dirs ─────────────────────────────
echo ""
echo "─── Installing platforms ─────────────────────────────────────────"
PLATFORMS="windsurf claude opencode gemini codex"
for p in $PLATFORMS; do
  mkdir -p "$TMPBASE/$p"
  node "$INSTALLER" "--$p" --target "$TMPBASE/$p" > /dev/null 2>&1
done
echo "  Installed: $PLATFORMS"

# ─── 1. Phase Loop Workflows ─────────────────────────────────────────
# The core phase loop must be intact: discuss → plan → execute → verify

echo ""
echo "─── Phase Loop Workflows ─────────────────────────────────────────"

# discuss-phase.md
check "discuss-phase: has downstream_awareness (discussion persona)" grep -q '<downstream_awareness>' "$SRC_WF/discuss-phase.md"
check "discuss-phase: has STOP gates" grep -q '🛑 STOP' "$SRC_WF/discuss-phase.md"
check "discuss-phase: writes CONTEXT.md" grep -q 'CONTEXT.md' "$SRC_WF/discuss-phase.md"
check "discuss-phase: has scope_guardrail" grep -q '<scope_guardrail>' "$SRC_WF/discuss-phase.md"
check "discuss-phase: references ROADMAP.md" grep -q 'ROADMAP.md' "$SRC_WF/discuss-phase.md"

# plan-phase.md
check "plan-phase: has persona_context" grep -q '<persona_context>' "$SRC_WF/plan-phase.md"
check "plan-phase: references REQUIREMENTS.md" grep -q 'REQUIREMENTS.md' "$SRC_WF/plan-phase.md"
check "plan-phase: references ROADMAP.md" grep -q 'ROADMAP.md' "$SRC_WF/plan-phase.md"
check "plan-phase: writes PLAN.md" grep -q 'PLAN.md' "$SRC_WF/plan-phase.md"
check "plan-phase: has Task() for researcher" grep -q 'learnship-researcher\|learnship-phase-researcher' "$SRC_WF/plan-phase.md"
check "plan-phase: has @./agents/ ref" grep -q '@./agents/' "$SRC_WF/plan-phase.md"
check "plan-phase: checks config for research setting" grep -q 'workflow.research\|config.*research' "$SRC_WF/plan-phase.md"
check "plan-phase: checks config for plan_check setting" grep -q 'workflow.plan_check\|plan_check' "$SRC_WF/plan-phase.md"

# execute-phase.md
check "execute-phase: has persona_context" grep -q '<persona_context>' "$SRC_WF/execute-phase.md"
check "execute-phase: references PLAN.md" grep -q 'PLAN.md' "$SRC_WF/execute-phase.md"
check "execute-phase: has Task() calls" grep -q 'Task(' "$SRC_WF/execute-phase.md"
check "execute-phase: has @./agents/ ref" grep -q '@./agents/' "$SRC_WF/execute-phase.md"
check "execute-phase: writes SUMMARY.md" grep -q 'SUMMARY.md' "$SRC_WF/execute-phase.md"
check "execute-phase: checks parallelization config" grep -q 'parallelization' "$SRC_WF/execute-phase.md"
check "execute-phase: enforces atomic commits" grep -q 'atomic commit\|one commit\|One task = one commit' "$SRC_WF/execute-phase.md"

# verify-work.md
check "verify-work: has persona_context" grep -q '<persona_context>' "$SRC_WF/verify-work.md"
check "verify-work: references UAT" grep -q 'UAT' "$SRC_WF/verify-work.md"
check "verify-work: has @./agents/ ref" grep -q '@./agents/' "$SRC_WF/verify-work.md"
check "verify-work: checks must_haves" grep -q 'must_haves\|must_have' "$SRC_WF/verify-work.md"

# review.md
check "review: has persona_context" grep -q '<persona_context>' "$SRC_WF/review.md"
check "review: has Task() calls" grep -q 'Task(' "$SRC_WF/review.md"
check "review: has @./agents/ ref" grep -q '@./agents/' "$SRC_WF/review.md"
check "review: has multi-persona structure" grep -q 'correctness\|security\|performance\|maintainability' "$SRC_WF/review.md"

echo ""
echo "─── Planning & Research Workflows ────────────────────────────────"

# research-phase.md
check "research-phase: has persona_context" grep -q '<persona_context>' "$SRC_WF/research-phase.md"
check "research-phase: has Task() calls" grep -q 'Task(' "$SRC_WF/research-phase.md"
check "research-phase: has @./agents/ ref" grep -q '@./agents/' "$SRC_WF/research-phase.md"
check "research-phase: writes RESEARCH.md" grep -q 'RESEARCH.md' "$SRC_WF/research-phase.md"
check "research-phase: uses web search" grep -q 'WebSearch\|web search\|web_search' "$SRC_WF/research-phase.md"

# map-codebase.md
check "map-codebase: has persona_context" grep -q '<persona_context>' "$SRC_WF/map-codebase.md"
check "map-codebase: has @./agents/ ref" grep -q '@./agents/' "$SRC_WF/map-codebase.md"
check "map-codebase: writes to .planning/codebase/" grep -q '.planning/codebase' "$SRC_WF/map-codebase.md"
check "map-codebase: writes ARCHITECTURE.md" grep -q 'ARCHITECTURE.md' "$SRC_WF/map-codebase.md"

echo ""
echo "─── Debug & Diagnostic Workflows ─────────────────────────────────"

# debug.md
check "debug: has persona_context" grep -q '<persona_context>' "$SRC_WF/debug.md"
check "debug: has STOP gate" grep -q '🛑 STOP' "$SRC_WF/debug.md"
check "debug: has Task() calls" grep -q 'Task(' "$SRC_WF/debug.md"
check "debug: has @./agents/ ref" grep -q '@./agents/' "$SRC_WF/debug.md"
check "debug: writes session file" grep -q 'session\|SESSION' "$SRC_WF/debug.md"
check "debug: has hypothesis structure" grep -q 'hypothesis\|Hypothesis' "$SRC_WF/debug.md"

# diagnose-issues.md
check "diagnose-issues: has persona_context" grep -q '<persona_context>' "$SRC_WF/diagnose-issues.md"
check "diagnose-issues: has STOP gate" grep -q '🛑 STOP' "$SRC_WF/diagnose-issues.md"
check "diagnose-issues: has @./agents/ ref" grep -q '@./agents/' "$SRC_WF/diagnose-issues.md"

echo ""
echo "─── Security & Validation Workflows ──────────────────────────────"

# secure-phase.md
check "secure-phase: has persona_context" grep -q '<persona_context>' "$SRC_WF/secure-phase.md"
check "secure-phase: has STOP gates" grep -q '🛑 STOP' "$SRC_WF/secure-phase.md"
check "secure-phase: has Task() calls" grep -q 'Task(' "$SRC_WF/secure-phase.md"
check "secure-phase: references STRIDE" grep -q 'STRIDE' "$SRC_WF/secure-phase.md"
check "secure-phase: writes SECURITY.md" grep -q 'SECURITY.md' "$SRC_WF/secure-phase.md"

# validate-phase.md
check "validate-phase: has persona_context" grep -q '<persona_context>' "$SRC_WF/validate-phase.md"
check "validate-phase: has STOP gate" grep -q '🛑 STOP' "$SRC_WF/validate-phase.md"
check "validate-phase: has Task() calls" grep -q 'Task(' "$SRC_WF/validate-phase.md"

echo ""
echo "─── Milestone & Meta Workflows ───────────────────────────────────"

# new-milestone.md
check "new-milestone: has persona_context" grep -q '<persona_context>' "$SRC_WF/new-milestone.md"
check "new-milestone: references ROADMAP.md" grep -q 'ROADMAP.md' "$SRC_WF/new-milestone.md"
check "new-milestone: references STATE.md" grep -q 'STATE.md' "$SRC_WF/new-milestone.md"
check "new-milestone: references PROJECT.md" grep -q 'PROJECT.md' "$SRC_WF/new-milestone.md"
check "new-milestone: has codebase map check (Step 6a)" grep -q 'codebase.*map\|map.*codebase\|\.planning/codebase' "$SRC_WF/new-milestone.md"

# complete-milestone.md
check "complete-milestone: references ROADMAP.md" grep -q 'ROADMAP.md' "$SRC_WF/complete-milestone.md"
check "complete-milestone: references STATE.md" grep -q 'STATE.md' "$SRC_WF/complete-milestone.md"

# challenge.md
check "challenge: has persona_context" grep -q '<persona_context>' "$SRC_WF/challenge.md"
check "challenge: has STOP gate" grep -q '🛑 STOP' "$SRC_WF/challenge.md"
check "challenge: has Task() calls" grep -q 'Task(' "$SRC_WF/challenge.md"

# compound.md
check "compound: has persona_context" grep -q '<persona_context>' "$SRC_WF/compound.md"
check "compound: writes to solutions/" grep -q 'solutions/' "$SRC_WF/compound.md"

# ideate.md
check "ideate: has persona_context" grep -q '<persona_context>' "$SRC_WF/ideate.md"
check "ideate: has STOP gate" grep -q '🛑 STOP' "$SRC_WF/ideate.md"
check "ideate: has Task() calls" grep -q 'Task(' "$SRC_WF/ideate.md"
check "ideate: has scan/explore modes" grep -q 'scan\|explore' "$SRC_WF/ideate.md"

echo ""
echo "─── Navigation & Settings Workflows ──────────────────────────────"

# ls.md
check "ls: checks PROJECT.md existence" grep -q 'PROJECT.md' "$SRC_WF/ls.md"
check "ls: references STATE.md" grep -q 'STATE.md' "$SRC_WF/ls.md"

# settings.md
check "settings: has STOP gates" grep -q '🛑 STOP' "$SRC_WF/settings.md"
check "settings: reads config.json" grep -q 'config.json' "$SRC_WF/settings.md"
check "settings: writes config.json" grep -q 'writeFileSync.*config.json\|fs.writeFileSync' "$SRC_WF/settings.md"

# health.md
check "health: checks PROJECT.md" grep -q 'PROJECT.md' "$SRC_WF/health.md"
check "health: checks config.json" grep -q 'config.json' "$SRC_WF/health.md"

# quick.md
check "quick: has STOP gate" grep -q '🛑 STOP' "$SRC_WF/quick.md"
check "quick: has persona_context" grep -q '<persona_context>' "$SRC_WF/quick.md"

echo ""
echo "─── 2. Agent Persona File Completeness ───────────────────────────"

# Every agent file referenced by workflows must exist
node -e "
const fs=require('fs'),path=require('path');
const wfDir='$SRC_WF', agDir='$SRC_AG';
const wfs=fs.readdirSync(wfDir).filter(f=>f.endsWith('.md'));
const referencedAgents=new Set();
const missingAgents=[];

for(const wf of wfs){
  const c=fs.readFileSync(path.join(wfDir,wf),'utf8');
  const refs=[...c.matchAll(/@\.\/agents\/([a-z-]+\.md)/g)];
  for(const m of refs) referencedAgents.add(m[1]);
}

for(const ag of referencedAgents){
  if(!fs.existsSync(path.join(agDir,ag))){
    missingAgents.push(ag);
  }
}

console.log('Referenced agents: '+referencedAgents.size);
console.log('Missing: '+missingAgents.length);
if(missingAgents.length){
  missingAgents.forEach(a=>console.error('  MISSING: '+a));
  process.exit(1);
}
" && { echo "  ✓ All referenced agent persona files exist"; PASS=$((PASS+1)); } || { echo "  ✗ Some agent persona files are missing"; FAIL=$((FAIL+1)); ERRORS+=("Missing agent persona files"); }

# Every agent file must have meaningful content (>100 bytes)
node -e "
const fs=require('fs'),path=require('path');
const agDir='$SRC_AG';
const files=fs.readdirSync(agDir).filter(f=>f.endsWith('.md'));
const tiny=files.filter(f=>fs.statSync(path.join(agDir,f)).size<100);
if(tiny.length){
  tiny.forEach(f=>console.error('  TOO SMALL: '+f));
  process.exit(1);
}
console.log('All '+files.length+' agent files have substantive content');
" && { echo "  ✓ All agent files have substantive content (>100 bytes)"; PASS=$((PASS+1)); } || { echo "  ✗ Some agent files are too small"; FAIL=$((FAIL+1)); ERRORS+=("Agent files too small"); }

echo ""
echo "─── 3. Cross-Platform: Key Phrases Survive install.js ────────────"

# Critical enforcement phrases that MUST survive install.js transforms
# If any of these disappear on a platform, the workflow breaks silently
PHRASES=(
  "persona_context|plan-phase.md"
  "persona_context|execute-phase.md"
  "persona_context|verify-work.md"
  "persona_context|review.md"
  "persona_context|debug.md"
  "persona_context|new-project.md"
  "persona_context|research-phase.md"
  "persona_context|secure-phase.md"
  "@./agents/|plan-phase.md"
  "@./agents/|execute-phase.md"
  "@./agents/|review.md"
  "@./agents/|new-project.md"
  "PLAN.md|execute-phase.md"
  "REQUIREMENTS.md|plan-phase.md"
  "ROADMAP.md|plan-phase.md"
  "CONTEXT.md|discuss-phase.md"
  "UAT|verify-work.md"
  "SUMMARY.md|execute-phase.md"
  "STRIDE|secure-phase.md"
  "CONFIG_VALID|new-project.md"
  "MANDATORY INTERACTIVE|new-project.md"
  "HARD STOP|new-project.md"
  "MANDATORY USER CHOICE|new-project.md"
)

PHRASE_FAILS=0
for entry in "${PHRASES[@]}"; do
  phrase="${entry%%|*}"
  wf="${entry##*|}"
  for p in $PLATFORMS; do
    installed="$TMPBASE/$p/learnship/workflows/$wf"
    if [ -f "$installed" ]; then
      if ! grep -q "$phrase" "$installed" 2>/dev/null; then
        echo "  ✗ $p/$wf: missing '$phrase'"
        PHRASE_FAILS=$((PHRASE_FAILS+1))
      fi
    fi
  done
done

if [ "$PHRASE_FAILS" -eq 0 ]; then
  echo "  ✓ All critical phrases survive install.js across all 5 platforms (${#PHRASES[@]} phrases × 5 platforms = $((${#PHRASES[@]} * 5)) checks)"
  PASS=$((PASS+1))
else
  echo "  ✗ $PHRASE_FAILS phrase(s) lost during install"
  FAIL=$((FAIL+1))
  ERRORS+=("$PHRASE_FAILS phrases lost during install.js transforms")
fi

echo ""
echo "─── 4. Cross-Platform: Agent @./agents/ Refs Survive ─────────────"

# Every workflow with @./agents/ in source must still have it after install
node -e "
const fs=require('fs'),path=require('path');
const srcDir='$SRC_WF';
const platforms='$PLATFORMS'.split(' ');
const tmpBase='$TMPBASE';
const errs=[];

const srcFiles=fs.readdirSync(srcDir).filter(f=>f.endsWith('.md'));
for(const wf of srcFiles){
  const srcContent=fs.readFileSync(path.join(srcDir,wf),'utf8');
  if(!srcContent.includes('@./agents/'))continue;

  const srcRefs=[...srcContent.matchAll(/@\.\/agents\/([a-z-]+\.md)/g)].map(m=>m[1]);

  for(const p of platforms){
    const installed=path.join(tmpBase,p,'learnship','workflows',wf);
    if(!fs.existsSync(installed))continue;
    const instContent=fs.readFileSync(installed,'utf8');
    for(const ref of srcRefs){
      if(!instContent.includes(ref)){
        errs.push(p+'/'+wf+': lost @./agents/'+ref);
      }
    }
  }
}

if(errs.length){errs.forEach(e=>console.error('  - '+e));process.exit(1);}
console.log('OK');
" && { echo "  ✓ All @./agents/ references preserved across all 5 platforms"; PASS=$((PASS+1)); } || { echo "  ✗ Some @./agents/ references lost during install"; FAIL=$((FAIL+1)); ERRORS+=("@./agents/ references lost during install"); }

echo ""
echo "─── 5. Cross-Platform: STOP Gates Preserved ──────────────────────"

# Every workflow that has STOP gates in source must have them after install
node -e "
const fs=require('fs'),path=require('path');
const srcDir='$SRC_WF';
const platforms='$PLATFORMS'.split(' ');
const tmpBase='$TMPBASE';
const errs=[];

const srcFiles=fs.readdirSync(srcDir).filter(f=>f.endsWith('.md'));
for(const wf of srcFiles){
  const srcContent=fs.readFileSync(path.join(srcDir,wf),'utf8');
  const srcStops=(srcContent.match(/🛑 STOP/g)||[]).length;
  if(srcStops===0)continue;

  for(const p of platforms){
    const installed=path.join(tmpBase,p,'learnship','workflows',wf);
    if(!fs.existsSync(installed))continue;
    const instContent=fs.readFileSync(installed,'utf8');
    const instStops=(instContent.match(/🛑 STOP/g)||[]).length;
    if(instStops<srcStops){
      errs.push(p+'/'+wf+': source has '+srcStops+' STOP gates, installed has '+instStops);
    }
  }
}

if(errs.length){errs.forEach(e=>console.error('  - '+e));process.exit(1);}
console.log('OK');
" && { echo "  ✓ STOP gate counts preserved across all 5 platforms"; PASS=$((PASS+1)); } || { echo "  ✗ STOP gates lost during install"; FAIL=$((FAIL+1)); ERRORS+=("STOP gates lost during install"); }

echo ""
echo "─── 6. Cross-Platform: Task() Definitions Preserved ──────────────"

# Every workflow that has Task() in source must still have it
node -e "
const fs=require('fs'),path=require('path');
const srcDir='$SRC_WF';
const platforms='$PLATFORMS'.split(' ');
const tmpBase='$TMPBASE';
const errs=[];

const srcFiles=fs.readdirSync(srcDir).filter(f=>f.endsWith('.md'));
for(const wf of srcFiles){
  const srcContent=fs.readFileSync(path.join(srcDir,wf),'utf8');
  const srcTasks=(srcContent.match(/Task\(/g)||[]).length;
  if(srcTasks===0)continue;

  for(const p of platforms){
    const installed=path.join(tmpBase,p,'learnship','workflows',wf);
    if(!fs.existsSync(installed))continue;
    const instContent=fs.readFileSync(installed,'utf8');
    const instTasks=(instContent.match(/Task\(/g)||[]).length;
    if(instTasks<srcTasks){
      errs.push(p+'/'+wf+': source has '+srcTasks+' Task() calls, installed has '+instTasks);
    }
  }
}

if(errs.length){errs.forEach(e=>console.error('  - '+e));process.exit(1);}
console.log('OK');
" && { echo "  ✓ Task() call counts preserved across all 5 platforms"; PASS=$((PASS+1)); } || { echo "  ✗ Task() calls lost during install"; FAIL=$((FAIL+1)); ERRORS+=("Task() calls lost during install"); }

echo ""
echo "─── 7. Cursor .mdc: Workflow Table Coverage ──────────────────────"

MDC="$REPO_DIR/cursor-rules/learnship.mdc"

# Critical workflows that MUST be in the Cursor .mdc workflow table
CURSOR_REQUIRED=(
  "new-project"
  "new-milestone"
  "discuss-phase"
  "plan-phase"
  "execute-phase"
  "verify-work"
  "review"
  "ship"
  "complete-milestone"
  "ls"
  "next"
  "quick"
  "debug"
  "map-codebase"
  "ideate"
  "challenge"
  "settings"
  "health"
  "compound"
  "pause-work"
  "resume-work"
  "secure-phase"
  "validate-phase"
  "diagnose-issues"
)

CURSOR_MISSING=0
for wf in "${CURSOR_REQUIRED[@]}"; do
  if ! grep -q "$wf" "$MDC" 2>/dev/null; then
    echo "  ✗ Cursor .mdc missing workflow: $wf"
    CURSOR_MISSING=$((CURSOR_MISSING+1))
  fi
done

if [ "$CURSOR_MISSING" -eq 0 ]; then
  echo "  ✓ Cursor .mdc references all ${#CURSOR_REQUIRED[@]} critical workflows"
  PASS=$((PASS+1))
else
  echo "  ✗ Cursor .mdc missing $CURSOR_MISSING critical workflows"
  FAIL=$((FAIL+1))
  ERRORS+=("Cursor .mdc missing $CURSOR_MISSING workflows")
fi

echo ""
echo "─── 8. Cursor .mdc: Config Schema Coverage ──────────────────────"

check "Cursor .mdc: has config schema section" grep -q '## Config Schema' "$MDC"
check "Cursor .mdc: mode key mapping" grep -q '"mode"' "$MDC"
check "Cursor .mdc: granularity key mapping" grep -q '"granularity"' "$MDC"
check "Cursor .mdc: model_profile key mapping" grep -q '"model_profile"' "$MDC"
check "Cursor .mdc: learning_mode key mapping" grep -q '"learning_mode"' "$MDC"
check "Cursor .mdc: workflow.research key mapping" grep -q '"workflow.research"' "$MDC"
check "Cursor .mdc: parallelization.enabled key mapping" grep -q '"parallelization.enabled"' "$MDC"
check "Cursor .mdc: forbidden flat keys warning" grep -q 'working_style.*model_tier\|model_tier.*working_style' "$MDC"
check "Cursor .mdc: CONFIG_VALID reference" grep -q 'CONFIG_VALID' "$MDC"
check "Cursor .mdc: round-by-round instruction" grep -q 'EACH round\|each round' "$MDC"

echo ""
echo "─── 9. Correct Subagent Types in Task() Calls ──────────────────"

# Verify specialized personas are used (not generic learnship-researcher) where they should be
check "new-project: 4 research Task() use learnship-project-researcher" \
  test "$(grep -c 'subagent_type="learnship-project-researcher"' "$SRC_WF/new-project.md")" -eq 4

check "new-project: synthesizer Task() uses learnship-research-synthesizer" \
  grep -q 'subagent_type="learnship-research-synthesizer"' "$SRC_WF/new-project.md"

check "plan-phase: research Task() uses learnship-phase-researcher" \
  grep -q 'subagent_type="learnship-phase-researcher"' "$SRC_WF/plan-phase.md"

check "research-phase: Task() uses learnship-phase-researcher" \
  grep -q 'subagent_type="learnship-phase-researcher"' "$SRC_WF/research-phase.md"

check "plan-phase: planner Task() uses learnship-planner" \
  grep -q 'subagent_type="learnship-planner"' "$SRC_WF/plan-phase.md"

check "plan-phase: checker Task() uses learnship-plan-checker" \
  grep -q 'subagent_type="learnship-plan-checker"' "$SRC_WF/plan-phase.md"

check "execute-phase: Task() uses learnship-executor" \
  grep -q 'subagent_type="learnship-executor"' "$SRC_WF/execute-phase.md"

check "docs-update: Task() uses learnship-doc-writer" \
  grep -q 'subagent_type="learnship-doc-writer"' "$SRC_WF/docs-update.md"

check "docs-update: Task() uses learnship-doc-verifier" \
  grep -q 'subagent_type="learnship-doc-verifier"' "$SRC_WF/docs-update.md"

# Regression guard: no generic learnship-researcher in workflows that should use specialized personas
check "new-project: no generic learnship-researcher in Task() calls" \
  test "$(grep 'subagent_type="learnship-researcher"' "$SRC_WF/new-project.md" | wc -l)" -eq 0

check "plan-phase: no generic learnship-researcher in Task() calls" \
  test "$(grep 'subagent_type="learnship-researcher"' "$SRC_WF/plan-phase.md" | wc -l)" -eq 0

check "research-phase: no generic learnship-researcher in Task() calls" \
  test "$(grep 'subagent_type="learnship-researcher"' "$SRC_WF/research-phase.md" | wc -l)" -eq 0

echo ""
echo "─── 10. Every Task() Has <agent_definition> ────────────────────"

# Every real Task() call (inside code blocks, not description text) must have an <agent_definition>
node -e "
const fs=require('fs'),path=require('path');
const wfDir='$SRC_WF';
const errs=[];
const wfs=fs.readdirSync(wfDir).filter(f=>f.endsWith('.md'));

for(const wf of wfs){
  const c=fs.readFileSync(path.join(wfDir,wf),'utf8');
  const codeBlocks=[...c.matchAll(/\`\`\`[^\`]*?\`\`\`/gs)];
  for(const block of codeBlocks){
    const b=block[0];
    const taskCount=(b.match(/Task\(/g)||[]).length;
    const defCount=(b.match(/<agent_definition>/g)||[]).length;
    if(taskCount>0 && defCount<taskCount){
      errs.push(wf+': '+taskCount+' Task() but only '+defCount+' <agent_definition> blocks');
    }
  }
}

if(errs.length){errs.forEach(e=>console.error('  - '+e));process.exit(1);}
console.log('OK');
" && { echo "  ✓ Every Task() call has a matching <agent_definition> block"; PASS=$((PASS+1)); } || { echo "  ✗ Some Task() calls missing <agent_definition>"; FAIL=$((FAIL+1)); ERRORS+=("Task() calls missing agent_definition"); }

echo ""
echo "─── 11. Persona Announcements ──────────────────────────────────"

# Every <persona_context> block must have a matching "Announce persona" instruction
node -e "
const fs=require('fs'),path=require('path');
const wfDir='$SRC_WF';
const errs=[];
const wfs=fs.readdirSync(wfDir).filter(f=>f.endsWith('.md'));

for(const wf of wfs){
  const c=fs.readFileSync(path.join(wfDir,wf),'utf8');
  const pcCount=(c.match(/<persona_context>/g)||[]).length;
  const annCount=(c.match(/Announce persona/g)||[]).length;
  if(pcCount!==annCount){
    errs.push(wf+': '+pcCount+' persona_context blocks but '+annCount+' announcements');
  }
}

if(errs.length){errs.forEach(e=>console.error('  - '+e));process.exit(1);}
console.log('OK — all persona_context blocks have announcements');
" && { echo "  ✓ Every <persona_context> has a matching 'Announce persona' instruction"; PASS=$((PASS+1)); } || { echo "  ✗ Some persona_context blocks missing announcements"; FAIL=$((FAIL+1)); ERRORS+=("persona_context blocks missing announcements"); }

# Persona announcements must contain ANSI color codes
check "Persona announcements have ANSI color escapes" \
  grep -q '033\[' "$SRC_WF/new-project.md"

# Persona announcements must use correct agent names
check "new-project: roadmapper announcement uses learnship-roadmapper" \
  grep -q 'learnship-roadmapper(' "$SRC_WF/new-project.md"

check "new-project: project-researcher announcement uses learnship-project-researcher" \
  grep -q 'learnship-project-researcher(' "$SRC_WF/new-project.md"

check "plan-phase: announcements for phase-researcher, planner, plan-checker" \
  test "$(grep -c 'learnship-phase-researcher\|learnship-planner\|learnship-plan-checker' "$SRC_WF/plan-phase.md")" -ge 3

echo ""
echo "─── 12. Persona Announcements Survive Install ──────────────────"

# Announcements must survive install.js across all 5 platforms
node -e "
const fs=require('fs'),path=require('path');
const srcDir='$SRC_WF';
const platforms='$PLATFORMS'.split(' ');
const tmpBase='$TMPBASE';
const errs=[];

const srcFiles=fs.readdirSync(srcDir).filter(f=>f.endsWith('.md'));
for(const wf of srcFiles){
  const srcContent=fs.readFileSync(path.join(srcDir,wf),'utf8');
  const srcAnn=(srcContent.match(/Announce persona/g)||[]).length;
  if(srcAnn===0)continue;

  for(const p of platforms){
    const installed=path.join(tmpBase,p,'learnship','workflows',wf);
    if(!fs.existsSync(installed))continue;
    const instContent=fs.readFileSync(installed,'utf8');
    const instAnn=(instContent.match(/Announce persona/g)||[]).length;
    if(instAnn<srcAnn){
      errs.push(p+'/'+wf+': source has '+srcAnn+' announcements, installed has '+instAnn);
    }
  }
}

if(errs.length){errs.forEach(e=>console.error('  - '+e));process.exit(1);}
console.log('OK');
" && { echo "  ✓ Persona announcement counts preserved across all 5 platforms"; PASS=$((PASS+1)); } || { echo "  ✗ Persona announcements lost during install"; FAIL=$((FAIL+1)); ERRORS+=("Persona announcements lost during install"); }

echo ""
echo "─── 13. Sequential Fallback Uses Correct Persona ───────────────"

# The sequential (inline) path must reference the same persona as the Task() path
check "plan-phase: sequential fallback uses plan-checker (not verifier)" \
  grep -q 'learnship plan checker' "$SRC_WF/plan-phase.md"

check "plan-phase: sequential fallback references @./agents/plan-checker.md" \
  grep -q '@./agents/plan-checker.md' "$SRC_WF/plan-phase.md"

check "docs-update: sequential fallback uses doc-writer" \
  grep -q 'learnship doc writer' "$SRC_WF/docs-update.md"

check "docs-update: sequential fallback uses doc-verifier" \
  grep -q 'learnship doc verifier' "$SRC_WF/docs-update.md"

echo ""
echo "─── 14. v2.3.4: Deep Questioning & Vertical Slices ───────────────"

# discuss-phase --deep flag documented
check "discuss-phase: --deep flag documented in usage" \
  grep -q '\-\-deep' "$SRC_WF/discuss-phase.md"

# discuss-phase has DEEP_MODE detection
check "discuss-phase: DEEP_MODE detection logic present" \
  grep -q 'DEEP_MODE' "$SRC_WF/discuss-phase.md"

# discuss-phase deep mode wrap-up question
check "discuss-phase: deep mode shared understanding check present" \
  grep -q 'Shared Understanding Check' "$SRC_WF/discuss-phase.md"

# discuss-phase CONTEXT.md Mode field
check "discuss-phase: CONTEXT.md frontmatter includes Mode field" \
  grep -q '\*\*Mode:\*\*' "$SRC_WF/discuss-phase.md"

# new-project Step 3 questioning depth AskUserQuestion
check "new-project: Questioning Depth AskUserQuestion present" \
  grep -q 'Questioning Depth' "$SRC_WF/new-project.md"

# new-project QUESTIONING_MODE variable
check "new-project: QUESTIONING_MODE variable present" \
  grep -q 'QUESTIONING_MODE' "$SRC_WF/new-project.md"

# new-project deep mode shared understanding check
check "new-project: deep mode Shared Understanding Check present" \
  grep -q 'Shared Understanding Check' "$SRC_WF/new-project.md"

# settings.md discuss_mode deep documented
check "settings.md: discuss_mode deep option documented" \
  grep -q '"deep"' "$SRC_WF/settings.md"

# planner agent: vertical slice principle
check "planner agent: vertical slice principle present" \
  grep -q 'Vertical slices, not horizontal layers' "$SRC_AG/planner.md"

# planner agent: single_layer_justified field
check "planner agent: single_layer_justified field in PLAN.md format" \
  grep -q 'single_layer_justified' "$SRC_AG/planner.md"

# plan-checker agent: vertical slice check (#7)
check "plan-checker agent: vertical slice check (section 7) present" \
  grep -q 'Vertical Slice (tracer bullet)' "$SRC_AG/plan-checker.md"

# plan-checker agent: single_layer_justified escape hatch
check "plan-checker agent: single_layer_justified escape hatch" \
  grep -q 'single_layer_justified' "$SRC_AG/plan-checker.md"

# plan-phase workflow: vertical slice guidance in planner Task()
check "plan-phase: vertical slice guidance in Task() agent_definition" \
  grep -q 'VERTICAL SLICE' "$SRC_WF/plan-phase.md"

# plan-phase workflow: anti-pattern warning in sequential path
check "plan-phase: vertical slice check before writing instruction" \
  grep -q 'Vertical slice check before writing' "$SRC_WF/plan-phase.md"

# plan-phase workflow: plan-checker Task() includes vertical slice
check "plan-phase: plan-checker Task() includes vertical slice integrity" \
  grep -q 'vertical slice integrity' "$SRC_WF/plan-phase.md"

# plan.md template: vertical slice planning section
check "plan.md template: vertical slice planning guidelines present" \
  grep -q 'Vertical slice planning' "$REPO_DIR/templates/plan.md"

# Published agents synced
check "published learnship-planner: vertical slice in description" \
  grep -q 'vertical slice' "$REPO_DIR/agents/learnship-planner.md"

check "published learnship-plan-checker: vertical slice in description" \
  grep -q 'vertical slice integrity' "$REPO_DIR/agents/learnship-plan-checker.md"

# planning-config.md: discuss_mode deep documented
check "planning-config.md: discuss_mode deep option documented" \
  grep -q '"deep"' "$REPO_DIR/learnship/references/planning-config.md"

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
