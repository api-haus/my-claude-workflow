---
name: webstorm
description: Open webstorm in current worktree (nohup webstorm . > /dev/null &)
---

Open WebStorm at the current project root.

## Default behavior

When invoked as `/webstorm`, open the **project / service root** for the current task:

```bash
nohup webstorm <project-dir> >/dev/null 2>&1 &
disown
```

Pick the directory of the service the user has been working in (e.g. `game-api`, `client-api`). Do NOT open a single file when the user just says `/webstorm` — they want the IDE-level state (indexes, run configs, navigation).

If you can't tell which service from context, default to the cwd (`.`).

## Syntax notes

- ✅ `webstorm <project-dir>` — preferred form for `/webstorm`.
- ✅ `webstorm --line <N> <file>` — correct flag if a specific file+line is genuinely requested.
- ❌ `webstorm <path>:<line>` — wrong, WebStorm does not parse this.
