#!/usr/bin/env bash
# install.sh: Symlink skills into ~/.claude/

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${HOME}/.claude"

echo "Installing my-claude-workflow..."
echo ""

# Backup existing skills if it's a directory (not a symlink)
if [[ -d "$CLAUDE_DIR/skills" && ! -L "$CLAUDE_DIR/skills" ]]; then
    backup_name="skills.bak.$(date +%Y%m%d-%H%M%S)"
    echo "Backing up existing skills to $CLAUDE_DIR/$backup_name"
    mv "$CLAUDE_DIR/skills" "$CLAUDE_DIR/$backup_name"
elif [[ -L "$CLAUDE_DIR/skills" ]]; then
    echo "Removing existing symlink at $CLAUDE_DIR/skills"
    rm "$CLAUDE_DIR/skills"
fi

# Create symlink
echo "Creating symlink: $CLAUDE_DIR/skills -> $SCRIPT_DIR/skills"
ln -s "$SCRIPT_DIR/skills" "$CLAUDE_DIR/skills"

# Make shell scripts executable
chmod +x "$SCRIPT_DIR/skills/claude-status/claude-status.sh"
chmod +x "$SCRIPT_DIR/skills/enforce/enforce.sh"

echo ""
echo "Installation complete!"
echo ""
echo "Skills installed:"
ls -1 "$SCRIPT_DIR/skills" | sed 's/^/  - /'
echo ""
echo "Parameterized skills (use \${PROJECT_NAME}):"
echo "  - merge, worktree, todo, maketodo, picktodo"
