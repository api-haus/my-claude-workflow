#!/usr/bin/env bash
# enforce: Load CLAUDE.md constraints into session context

CLAUDE_MD="${CLAUDE_MD:-./CLAUDE.md}"
TODO_DIR="${TODO_DIR:-./docs/todo}"

if [[ ! -f "$CLAUDE_MD" ]]; then
    echo "No CLAUDE.md found in current directory"
    exit 1
fi

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  CONSTRAINTS                                               ║"
echo "╠════════════════════════════════════════════════════════════╣"

# Extract hard rules from CLAUDE.md
echo "║  Parsing $(basename "$CLAUDE_MD")..."
echo "║"

# Pattern 1: NEVER/ALWAYS/MUST/DON'T sentences
grep -E "^\s*[-*]?\s*(NEVER|ALWAYS|MUST|DON'T|NO|DO NOT)" "$CLAUDE_MD" 2>/dev/null | \
    head -10 | while read line; do
    clean=$(echo "$line" | sed 's/^\s*[-*]\s*//' | cut -c1-50)
    printf "║  • %s\n" "$clean"
done

# Pattern 2: Code block Wrong/Right comments
grep -B1 "✗ Bad\|Wrong\|✓ Good\|Right" "$CLAUDE_MD" 2>/dev/null | \
    grep -v "^[✗✓]" | head -5 | while read line; do
    clean=$(echo "$line" | sed 's/^\s*[-*]\s*//' | cut -c1-50)
    [[ -n "$clean" ]] && printf "║  • %s\n" "$clean"
done

# Pattern 3: Section headers that imply rules
echo "║"
echo "║  SECTIONS:"
grep "^##\s" "$CLAUDE_MD" 2>/dev/null | \
    sed 's/^##\s*/║  • /' | head -8

# Check for active todos
if [[ -d "$TODO_DIR" ]]; then
    active_todos=$(find "$TODO_DIR" -name "*.md" -type f 2>/dev/null | wc -l)
    if (( active_todos > 0 )); then
        echo "║"
        echo "║  ACTIVE TODOS ($active_todos):"
        find "$TODO_DIR" -name "*.md" -type f | head -5 | while read todo; do
            name=$(basename "$todo" .md)
            printf "║  • %s\n" "$name"
        done
    fi
fi

echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "These constraints are now active for this session."
echo "I will reference them before making changes."
echo ""
