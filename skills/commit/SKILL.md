---
name: commit
description: Commit all changes including untracked files
---

Commit all changes in the current working directory (or worktree).

1. Run `git status` and `git diff --stat` to see changes
2. If the project is Node.js-based (has `package.json`), run `pnpm lint:fix && pnpm test` before proceeding. If either fails, fix the issues first — do not commit broken code.
3. Stage ALL files including untracked: `git add -A`
4. Write a commit message following the repo's conventional commit style:
   - `feat:` for new features
   - `fix:` for bug fixes
   - `docs:` for documentation
   - `refactor:` for refactoring
   - `build:` for build system changes
5. Do NOT include `Co-Authored-By` lines or any AI attribution
6. Do NOT push unless explicitly requested
