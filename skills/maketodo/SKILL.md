---
name: maketodo
description: Scan docs, populate docs/todo with tasks
---

# Make Todo

Read documentation and populate todo directories with tasks.

## Todo Directories

| Directory | Tracked | Purpose |
|-----------|---------|---------|
| `docs/todo/` | Yes | Public tasks safe for git history |
| `docs/_internal/todo/` | No (gitignored) | Tasks with sensitive references or internal notes |

Default: `docs/todo/`. Use `docs/_internal/todo/` when the task references proprietary implementations or external codebases.

## Naming Convention

| Component | Format | Example |
|-----------|--------|---------|
| Todo file | `docs/todo/<slug>.md` or `docs/_internal/todo/<slug>.md` | `docs/todo/player-collision.md` |
| Worktree | `.claude/worktrees/<slug>` | `.claude/worktrees/player-collision` |
| Branch | `<type>/<slug>` | `feat/player-collision` |

Use kebab-case slugs that match potential branch names.

## Process

1. **Read architectural docs** - Review `docs/` for design concepts
2. **Read internal docs** - Check `docs/_internal/` for analysis and reference material
3. **Scan codebase** - Identify gaps between docs and implementation
4. **Create todo files** - One file per discrete task:
   - Filename: `docs/todo/<slug>.md` (or `docs/_internal/todo/<slug>.md` for sensitive tasks)
   - Each task should be self-contained enough for a single worktree

## Task File Format

```markdown
# <Title>

<Brief description of what needs to be done>

## Tasks
- [ ] Subtask 1
- [ ] Subtask 2
- [ ] Subtask 3
```

## Constraints

- One task per file for clean worktree association
- Use kebab-case slugs (will become branch names)
- Do NOT implement tasks - only identify and document them
- Do NOT push - user reviews first
