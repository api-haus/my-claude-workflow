#!/usr/bin/env bash
# claude-status: Show active Claude sessions across projects

set -euo pipefail

CLAUDE_DIR="${HOME}/.claude"
PROJECTS_DIR="${CLAUDE_DIR}/projects"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

show_help() {
    cat << 'EOF'
Usage: claude-status [OPTIONS]

Show active Claude Code sessions across all projects.

OPTIONS:
    --here      Show only sessions for current directory project
    --clean     Identify stale sessions (>24h) with uncommitted changes
    --json      Output as JSON for scripting
    -h, --help  Show this help

EXAMPLES:
    claude-status           # Full status of all projects
    claude-status --here    # Status for current project only
    claude-status --clean   # Find sessions needing cleanup
EOF
}

# Parse project path from project name (e.g., -home-midori--dev-sim2d)
# Claude encodes paths: -- = /, _ gets eaten, leading - is root
parse_project_path() {
    local name="$1"
    # Handle common patterns
    case "$name" in
        *"--dev-")
            name="${name//--dev-/--_dev-}"
            ;;
        *"--dev")
            name="${name//--dev/--_dev}"
            ;;
    esac
    # Remove leading dash, replace -- with /, - with /
    echo "/$name" | sed 's/^-//; s/--/\//g; s/-/\//g'
}

# Get last modified time of session file in hours
get_session_age_hours() {
    local session_file="$1"
    if [[ ! -f "$session_file" ]]; then
        echo "unknown"
        return
    fi
    local mtime epoch_now epoch_file hours
    epoch_file=$(stat -c %Y "$session_file" 2>/dev/null || stat -f %m "$session_file" 2>/dev/null)
    epoch_now=$(date +%s)
    hours=$(( (epoch_now - epoch_file) / 3600 ))
    echo "$hours"
}

# Format age nicely
format_age() {
    local hours="$1"
    if [[ "$hours" == "unknown" ]]; then
        echo "?"
        return
    fi
    if (( hours < 1 )); then
        echo "<1h"
    elif (( hours < 24 )); then
        echo "${hours}h"
    else
        local days=$(( hours / 24 ))
        echo "${days}d"
    fi
}

# Check git status for a project path
check_git_status() {
    local project_path="$1"
    if [[ ! -d "$project_path/.git" ]]; then
        echo "no-git"
        return
    fi

    cd "$project_path" || { echo "error"; return; }

    # Check for uncommitted changes
    if git diff --quiet && git diff --cached --quiet; then
        echo "clean"
    else
        local unstaged=$(git diff --name-only | wc -l)
        local staged=$(git diff --cached --name-only | wc -l)
        if (( staged > 0 && unstaged > 0 )); then
            echo "${staged}+${unstaged} changes"
        elif (( staged > 0 )); then
            echo "${staged} staged"
        else
            echo "${unstaged} unstaged"
        fi
    fi
}

# Check for worktrees in a project
check_worktrees() {
    local project_path="$1"
    if [[ ! -d "$project_path/.git" ]]; then
        return
    fi

    cd "$project_path" || return
    git worktree list --porcelain 2>/dev/null | grep -E "^worktree " | wc -l
}

# Main status display
show_status() {
    local filter_here="${1:-false}"
    local current_project=""

    if [[ "$filter_here" == "true" ]]; then
        current_project=$(pwd)
    fi

    if [[ ! -d "$PROJECTS_DIR" ]]; then
        echo "No Claude projects found at $PROJECTS_DIR"
        exit 1
    fi

    local total_sessions=0
    local stale_sessions=0
    local projects_with_work=0

    # Header
    echo ""
    echo "Active Claude Sessions"
    echo "═══════════════════════════════════════════════════════════════"
    echo ""

    # Iterate through project directories
    for project_dir in "$PROJECTS_DIR"/*; do
        [[ -d "$project_dir" ]] || continue

        local project_name=$(basename "$project_dir")
        local project_path="/$(parse_project_path "$project_name")"

        # Skip if filtering to current directory
        if [[ "$filter_here" == "true" && "$project_path" != "$current_project" ]]; then
            continue
        fi

        # Count session files
        local sessions=()
        for session in "$project_dir"/*.jsonl; do
            [[ -f "$session" ]] || continue
            sessions+=("$session")
        done

        (( ${#sessions[@]} > 0 )) || continue

        total_sessions=$((total_sessions + ${#sessions[@]}))

        # Project header
        local display_name=$(echo "$project_name" | sed 's/^-home-midori-//; s/^-dev-//; s/--/\//g')
        printf "${BLUE}%-24s${NC} %s\n" "$display_name" "$project_path"

        # Check git/worktree status once per project
        local git_status=$(check_git_status "$project_path")
        local worktree_count=$(check_worktrees "$project_path")

        # Show sessions
        for session in "${sessions[@]}"; do
            local session_id=$(basename "$session" .jsonl)
            local age_hours=$(get_session_age_hours "$session")
            local age_display=$(format_age "$age_hours")

            # Determine status indicator
            local indicator=""
            if (( age_hours > 24 )) && [[ "$git_status" != "clean" && "$git_status" != "no-git" ]]; then
                indicator="${RED}[STALE]${NC}"
                ((stale_sessions++))
            elif (( age_hours < 2 )); then
                indicator="${GREEN}[ACTIVE]${NC}"
            else
                indicator="${YELLOW}[IDLE]${NC}"
            fi

            # Shorten session ID
            local short_id="${session_id:0:8}"

            printf "  ├─ %-18s %6s ago  %-16s %b\n" \
                "$short_id..." "$age_display" "$git_status" "$indicator"
        done

        if (( worktree_count > 1 )); then
            printf "  └─ ${YELLOW}%d worktrees${NC}\n" "$((worktree_count - 1))"
        fi

        echo ""
    done

    # Footer stats
    echo "─────────────────────────────────────────────────────────────────"
    printf "Total: ${BLUE}%d${NC} sessions across projects\n" "$total_sessions"

    if (( stale_sessions > 0 )); then
        printf "⚠️  ${RED}%d stale sessions${NC} (>24h with uncommitted work)\n" "$stale_sessions"
    fi
    echo ""
}

# Show cleanup recommendations
show_cleanup() {
    echo ""
    echo "Sessions Requiring Attention"
    echo "═══════════════════════════════════════════════════════════════"
    echo ""

    local found=0

    for project_dir in "$PROJECTS_DIR"/*; do
        [[ -d "$project_dir" ]] || continue

        local project_name=$(basename "$project_dir")
        local project_path="/$(parse_project_path "$project_name")"
        [[ -d "$project_path/.git" ]] || continue

        for session in "$project_dir"/*.jsonl; do
            [[ -f "$session" ]] || continue

            local age_hours=$(get_session_age_hours "$session")
            (( age_hours > 24 )) || continue

            local git_status=$(check_git_status "$project_path")
            [[ "$git_status" == "clean" ]] && continue

            local session_id=$(basename "$session" .jsonl)
            local short_id="${session_id:0:16}"
            local display_name=$(echo "$project_name" | sed 's/^-home-midori-//; s/^-dev-//')

            printf "${YELLOW}⚠️  %s${NC}\n" "$display_name"
            printf "   Session: %s...\n" "$short_id"
            printf "   Age: %s ago\n" "$(format_age "$age_hours")"
            printf "   Status: %s\n" "$git_status"
            printf "   Action: cd %s && git status\n" "$project_path"
            echo ""

            ((found++))
        done
    done

    if (( found == 0 )); then
        echo "${GREEN}✓ No stale sessions found${NC}"
        echo ""
    fi
}

# Main
main() {
    case "${1:-}" in
        --here)
            show_status "true"
            ;;
        --clean)
            show_cleanup
            ;;
        --json)
            echo "JSON output not yet implemented"
            exit 1
            ;;
        -h|--help|help)
            show_help
            ;;
        "")
            show_status
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
