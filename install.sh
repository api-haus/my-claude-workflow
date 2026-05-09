#!/usr/bin/env bash
# install.sh: Symlink skills and agents into ~/.claude/

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${HOME}/.claude"

echo "Installing my-claude-workflow..."
echo ""

link_dir() {
    local name="$1"
    local target="$SCRIPT_DIR/$name"
    local link="$CLAUDE_DIR/$name"

    if [[ -d "$link" && ! -L "$link" ]]; then
        local backup_name="${name}.bak.$(date +%Y%m%d-%H%M%S)"
        echo "Backing up existing $name to $CLAUDE_DIR/$backup_name"
        mv "$link" "$CLAUDE_DIR/$backup_name"
    elif [[ -L "$link" ]]; then
        echo "Removing existing symlink at $link"
        rm "$link"
    fi

    echo "Creating symlink: $link -> $target"
    ln -s "$target" "$link"
}

link_dir skills
link_dir agents

# Make shell scripts executable
chmod +x "$SCRIPT_DIR/skills/claude-status/claude-status.sh"
chmod +x "$SCRIPT_DIR/skills/enforce/enforce.sh"

echo ""
echo "Installation complete!"
echo ""
echo "Skills installed:"
ls -1 "$SCRIPT_DIR/skills" | sed 's/^/  - /'
echo ""
echo "Agents installed:"
ls -1 "$SCRIPT_DIR/agents" | sed 's/^/  - /'
echo ""
echo "Parameterized skills (use \${PROJECT_NAME}):"
echo "  - merge, worktree, todo, maketodo, picktodo"
