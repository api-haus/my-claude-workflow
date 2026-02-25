---
name: picktodo
description: Pick a todo task, create worktree if needed, and begin work
---

# Pick Todo

Select a todo task and begin work.

## Usage

`/picktodo [task-slug]` - Pick a task, work in current directory
`/picktodo [task-slug] /worktree` - Pick a task and create an isolated worktree

Arguments can appear in any order. `/worktree` is detected anywhere in the arguments.

## Process

1. **Parse arguments** - Extract `<slug>` and check for `/worktree` flag

2. **List available todos** if no slug given:
   ```bash
   ls docs/todo/*.md
   ```

3. **Parse the task** from `docs/todo/<slug>.md`

4. **If `/worktree` was specified**, set up isolated worktree:
   - Check for existing worktree:
     ```bash
     REPO_ROOT=$(git rev-parse --show-toplevel)
     if [ -d "${REPO_ROOT}/.claude/worktrees/<slug>" ]; then
         echo "Worktree exists, switching..."
         cd "${REPO_ROOT}/.claude/worktrees/<slug>"
     fi
     ```
   - Create worktree if needed:
     ```bash
     mkdir -p "${REPO_ROOT}/.claude/worktrees"
     git worktree add "${REPO_ROOT}/.claude/worktrees/<slug>" -b <type>/<slug> main
     cd "${REPO_ROOT}/.claude/worktrees/<slug>"
     ```

5. **If `/worktree` was NOT specified**, work in the current directory:
   - Create a local branch (optional, based on user preference)
   - Stay in the current working directory

6. **Begin work** - Read the todo file and start implementation

## Worktree Naming Convention

Only relevant when `/worktree` is used:

| Component | Format | Example |
|-----------|--------|---------|
| Todo file | `docs/todo/<slug>.md` | `docs/todo/player-collision.md` |
| Worktree | `.claude/worktrees/<slug>` | `.claude/worktrees/player-collision` |
| Branch | `<type>/<slug>` | `feat/player-collision` |

The `<slug>` must be identical across all three.

## Plan Mode Requirement

When entering plan mode, ALWAYS include at the top of the plan:

```markdown
## Context
- **Todo:** `docs/todo/<slug>.md`
```

If working in a worktree, also include:
```markdown
- **Worktree:** `${REPO_ROOT}/.claude/worktrees/<slug>`
- **Branch:** `<type>/<slug>`
```

This persists context across conversation clears.

## Branch Type Selection

| Task content | Branch type |
|--------------|-------------|
| New feature, capability | `feat/` |
| Bug fix, correction | `fix/` |
| Code restructuring | `refactor/` |
| Documentation only | `docs/` |

## Constraints

- Never push - user pushes after review
- When using `/worktree`: one task = one worktree = one branch
- Use `/merge` when done with a worktree (removes todo file)
