#!/usr/bin/env bash
# learnship — Legacy Windsurf-only Installer
# NOTE: The primary installer is bin/install.js (supports all 6 platforms).
#       This script is a convenience wrapper for Windsurf-only installs from a git clone.
#       For npm installs, use: npx learnship --windsurf --global
#
# Usage:
#   bash install.sh                    # interactive
#   bash install.sh --local            # project install (non-interactive)
#   bash install.sh --global           # global install (non-interactive)
#   bash install.sh --uninstall --local
#   bash install.sh --uninstall --global

set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLATFORM_NAME="learnship"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
RESET='\033[0m'

# ─── Helpers ─────────────────────────────────────────────────────────────────

print_header() {
  echo ""
  echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo -e "${BOLD}  ${PLATFORM_NAME}${RESET}"
  echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo ""
}

print_success() { echo -e "${GREEN}✓${RESET} $1"; }
print_error()   { echo -e "${RED}✗${RESET} $1" >&2; }
print_info()    { echo -e "${BLUE}→${RESET} $1"; }
print_warn()    { echo -e "${YELLOW}!${RESET} $1"; }

# ─── Argument Parsing ────────────────────────────────────────────────────────

SCOPE=""
UNINSTALL=false

for arg in "$@"; do
  case "$arg" in
    --local)     SCOPE="local" ;;
    --global)    SCOPE="global" ;;
    --uninstall) UNINSTALL=true ;;
    --help|-h)
      echo "Usage: bash install.sh [--local|--global] [--uninstall]"
      echo ""
      echo "  --local      Install to current project's .windsurf/ directory"
      echo "  --global     Install to ~/.codeium/windsurf/ (available in all projects)"
      echo "  --uninstall  Remove the installation"
      echo ""
      echo "Run without flags for interactive mode."
      exit 0
      ;;
    *)
      print_error "Unknown argument: $arg"
      echo "Run 'bash install.sh --help' for usage."
      exit 1
      ;;
  esac
done

# ─── Determine Target Directory ──────────────────────────────────────────────

get_target_dir() {
  local scope="$1"
  if [[ "$scope" == "global" ]]; then
    echo "$HOME/.codeium/windsurf"
  else
    # When run via npx, pwd() is the npx cache — use LEARNSHIP_INSTALL_CWD
    # (set by bin/learnship.js from INIT_CWD) to get the user's actual project dir
    local project_dir="${LEARNSHIP_INSTALL_CWD:-$(pwd)}"
    echo "${project_dir}/.windsurf"
  fi
}

# ─── Interactive Prompt ──────────────────────────────────────────────────────

if [[ -z "$SCOPE" ]]; then
  print_header

  echo -e "${BOLD}Where would you like to install?${RESET}"
  echo ""
  echo "  [1] Project  — installs to ./.windsurf/ (current project only)"
  echo "  [2] Global   — installs to ~/.codeium/windsurf/ (all Windsurf projects)"
  echo ""
  read -p "Choice [1/2]: " choice

  case "$choice" in
    1|"") SCOPE="local" ;;
    2)    SCOPE="global" ;;
    *)
      print_error "Invalid choice. Run again and enter 1 or 2."
      exit 1
      ;;
  esac
fi

TARGET_DIR="$(get_target_dir "$SCOPE")"

# ─── Uninstall ───────────────────────────────────────────────────────────────

if [[ "$UNINSTALL" == true ]]; then
  print_header
  echo -e "Uninstalling from: ${BOLD}${TARGET_DIR}${RESET}"
  echo ""

  REMOVED=0

  if [[ -d "${TARGET_DIR}/workflows" ]]; then
    # Only remove our workflows (non-destructive: checks for our files)
    for wf in new-project discuss-phase plan-phase execute-phase verify-work quick progress ls next pause-work resume-work complete-milestone; do
      if [[ -f "${TARGET_DIR}/workflows/${wf}.md" ]]; then
        rm "${TARGET_DIR}/workflows/${wf}.md"
        print_info "Removed workflows/${wf}.md"
        ((REMOVED++)) || true
      fi
    done
  fi

  if [[ -d "${TARGET_DIR}/skills/agentic-learning" ]]; then
    rm -rf "${TARGET_DIR}/skills/agentic-learning"
    print_info "Removed skills/agentic-learning/"
    ((REMOVED++)) || true
  fi

  if [[ -d "${TARGET_DIR}/skills/impeccable" ]]; then
    rm -rf "${TARGET_DIR}/skills/impeccable"
    print_info "Removed skills/impeccable/"
    ((REMOVED++)) || true
  fi

  if [[ -d "${TARGET_DIR}/skills/frontend-design" ]]; then
    rm -rf "${TARGET_DIR}/skills/frontend-design"
    print_info "Removed skills/frontend-design/ (legacy)"
    ((REMOVED++)) || true
  fi

  if [[ $REMOVED -eq 0 ]]; then
    print_warn "Nothing found to remove at ${TARGET_DIR}"
  else
    echo ""
    print_success "Uninstall complete. Removed ${REMOVED} item(s)."
  fi
  exit 0
fi

# ─── Install ─────────────────────────────────────────────────────────────────

print_header
echo -e "Installing to: ${BOLD}${TARGET_DIR}${RESET}"
if [[ "$SCOPE" == "global" ]]; then
  print_info "Global install — workflows and skills will be available in all Windsurf projects"
else
  print_info "Project install — workflows and skills available in this project only"
fi
echo ""

# Validate source directory has the required files
if [[ ! -d "${REPO_DIR}/.windsurf/workflows" ]]; then
  print_error "Source workflows not found at ${REPO_DIR}/.windsurf/workflows"
  print_error "Make sure you are running install.sh from the agentic-development repo root."
  exit 1
fi

# Create target directories
mkdir -p "${TARGET_DIR}/workflows"
mkdir -p "${TARGET_DIR}/skills"

# ── Install Workflows ──────────────────────────────────────────────────────

echo -e "${BOLD}Installing workflows...${RESET}"

WORKFLOW_COUNT=0
for wf_file in "${REPO_DIR}/.windsurf/workflows/"*.md; do
  wf_name="$(basename "$wf_file")"
  dest="${TARGET_DIR}/workflows/${wf_name}"
  if [[ "$(realpath "$wf_file")" != "$(realpath "$dest" 2>/dev/null)" ]]; then
    cp "$wf_file" "$dest"
    print_success "workflows/${wf_name}"
    ((WORKFLOW_COUNT++)) || true
  fi
done

echo ""

# ── Install Skills ─────────────────────────────────────────────────────────

echo -e "${BOLD}Installing skills...${RESET}"

# agentic-learning
if [[ -d "${REPO_DIR}/.windsurf/skills/agentic-learning" ]]; then
  mkdir -p "${TARGET_DIR}/skills/agentic-learning"
  if [[ "$(realpath "${REPO_DIR}/.windsurf/skills/agentic-learning")" != "$(realpath "${TARGET_DIR}/skills/agentic-learning" 2>/dev/null)" ]]; then
    cp -r "${REPO_DIR}/.windsurf/skills/agentic-learning/"* "${TARGET_DIR}/skills/agentic-learning/"
  fi
  print_success "skills/agentic-learning/ (learning partner)"
else
  print_warn "skills/agentic-learning/ not found in source — skipping"
fi

# impeccable (full design skill suite)
if [[ -d "${REPO_DIR}/.windsurf/skills/impeccable" ]]; then
  if [[ "$(realpath "${REPO_DIR}/.windsurf/skills/impeccable")" != "$(realpath "${TARGET_DIR}/skills/impeccable" 2>/dev/null)" ]]; then
    cp -r "${REPO_DIR}/.windsurf/skills/impeccable" "${TARGET_DIR}/skills/impeccable"
  fi
  IMPECCABLE_COUNT=$(find "${REPO_DIR}/.windsurf/skills/impeccable" -name "SKILL.md" | wc -l | tr -d ' ')
  print_success "skills/impeccable/ (${IMPECCABLE_COUNT} design skills — audit, critique, polish, colorize + more)"
else
  print_warn "skills/impeccable/ not found in source — skipping"
fi

echo ""

# ── Done ──────────────────────────────────────────────────────────────────

echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${GREEN}${BOLD}  Installation complete!${RESET}"
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""
echo -e "  ${BOLD}Installed:${RESET} ${WORKFLOW_COUNT} workflows + 2 skill suites (agentic-learning, impeccable)"
echo -e "  ${BOLD}Location:${RESET}  ${TARGET_DIR}"
echo ""

if [[ "$SCOPE" == "global" ]]; then
  echo -e "  ${BOLD}Next steps:${RESET}"
  echo -e "  • Restart Windsurf (or reload the window) to activate"
  echo -e "  • Open any project and type ${BOLD}/new-project${RESET} to start"
else
  echo -e "  ${BOLD}Next steps:${RESET}"
  echo -e "  • Workflows are immediately available in this project"
  echo -e "  • Type ${BOLD}/new-project${RESET} in Cascade to start"
fi

echo ""
echo -e "  ${BOLD}Quick reference:${RESET}"
echo -e "  /ls                   Where am I? What's next? (start every session here)"
echo -e "  /next                 Auto-pilot — runs the right workflow automatically"
echo -e "  /new-project          Initialize a new project"
echo -e "  /discuss-phase [N]    Capture implementation decisions"
echo -e "  /plan-phase [N]       Create executable plans"
echo -e "  /execute-phase [N]    Run all plans in a phase"
echo -e "  /verify-work [N]      Manual acceptance testing"
echo -e "  /quick [description]  Ad-hoc task with full guarantees"
echo ""
echo -e "  ${BOLD}Learning mode:${RESET} Set ${BOLD}learning_mode${RESET} in .planning/config.json"
echo -e "  ${BOLD}  auto${RESET}   (default) Offered at workflow checkpoints"
echo -e "  ${BOLD}  manual${RESET} Only when you invoke @agentic-learning"
echo ""
echo -e "  See ${BOLD}README.md${RESET} or ${BOLD}https://github.com/FavioVazquez/learnship${RESET} for full documentation."
echo ""
