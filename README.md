# my-claude-workflow

Personal Claude Code skills and workflow automation.

## Installation

```bash
./install.sh
```

This symlinks `skills/` into `~/.claude/skills`.

## Skills

| Skill | Description |
|-------|-------------|
| `commit` | Commit all changes with conventional commits |
| `merge` | Merge worktree branch into main, cleanup |
| `rebase` | Rebase worktree branch onto latest main |
| `worktree` | Create/switch git worktrees for isolated work |
| `todo` | Add tasks discovered during work |
| `maketodo` | Scan docs, populate docs/todo |
| `picktodo` | Pick a todo task, create worktree, begin work |
| `refactor` | Review codebase for refactoring opportunities |
| `refine-docs` | Interactive document refinement Q&A |
| `rustrover` | Open RustRover in current directory |
| `docs` | Edit documentation only (no source code) |
| `claude-status` | Show active Claude sessions across projects |
| `enforce` | Load CLAUDE.md constraints into session |

## Worktree Workflow

The worktree skills follow a user-controlled sequence for clean main history:

```
/worktree → develop → /rebase → manual verify → /merge
```

### Phases

1. **Create & develop** (`/worktree`, `/picktodo`)
   - Create isolated worktree for the feature
   - Develop and commit changes

2. **Rebase** (`/rebase`)
   - Replay feature commits on top of latest main
   - Ensures linear history without merge commits

3. **Verify** (manual)
   - User tests the rebased feature works correctly
   - This step is intentionally manual—only the user knows when it's ready

4. **Merge** (`/merge`)
   - Fast-forward merge into main (no merge commit due to prior rebase)
   - Cleanup: remove worktree, delete branch, remove todo file

### Why rebase-before-merge?

Rebasing produces clean, linear history on main. Each feature appears as a sequential set of commits rather than a branching merge. This makes `git log`, `git bisect`, and rollbacks simpler.

## Parameterization

Five skills use `${PROJECT_NAME}` for project-specific paths:

- `merge` - worktree paths
- `worktree` - worktree paths
- `todo` - worktree path examples
- `maketodo` - worktree path examples
- `picktodo` - worktree paths

Claude resolves `${PROJECT_NAME}` at runtime from the current working directory basename.

**Example:** In `/home/midori/_dev/sim2d`, `${PROJECT_NAME}` becomes `sim2d`, so `../${PROJECT_NAME}-feature` becomes `../sim2d-feature`.

## Directory Structure

```
my-claude-workflow/
├── README.md
├── install.sh
└── skills/
    ├── commit/SKILL.md
    ├── merge/SKILL.md
    ├── rebase/SKILL.md
    ├── worktree/SKILL.md
    ├── todo/SKILL.md
    ├── maketodo/SKILL.md
    ├── picktodo/SKILL.md
    ├── refactor/SKILL.md
    ├── refine-docs/SKILL.md
    ├── rustrover/SKILL.md
    ├── docs/SKILL.md
    ├── claude-status/
    │   ├── SKILL.md
    │   └── claude-status.sh
    └── enforce/
        ├── SKILL.md
        └── enforce.sh
```
