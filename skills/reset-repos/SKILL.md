---
name: reset-repos
description: Preserve in-progress work and reset all p7 repos to latest master
---

# Reset Repos

Preserve any in-progress work across all p7 repositories, then reset everything to latest master. Fully autonomous — no user prompts.

**NEVER push to remote. NEVER include Co-Authored-By or AI attribution in commits. No emojis in commit messages.**

## Phase 1: Discovery & Classification

Enumerate all git repos under `/home/midori/_dev/p7`. Repos live in:
- Top-level: `/home/midori/_dev/p7/*/`
- Adapters: `/home/midori/_dev/p7/_adapters/*/`
- Libraries: `/home/midori/_dev/p7/_libs/*/`
- Infrastructure: `/home/midori/_dev/p7/_infra/*/`
- Backoffice: `/home/midori/_dev/p7/_backoffice/*/`

Skip non-repo directories (those without `.git`).

### Batch Status Check

Process 10-15 repos per bash call for efficiency. For each repo, collect:
- Current branch (`git rev-parse --abbrev-ref HEAD`)
- Working tree status (`git status --porcelain`)

### Classify Each Repo

| Category | Branch | Tree | Action |
|----------|--------|------|--------|
| CLEAN_MASTER | master | clean | `git pull` |
| CLEAN_BRANCH | feature | clean | `git checkout master && git pull` |
| DIRTY_BRANCH | feature | dirty | commit, `git checkout master && git pull` |
| DIRTY_MASTER | master | dirty | create branch, commit, `git checkout master && git pull` |

### Display Summary

Print a markdown table showing every repo, its current branch, category, and planned action. Example:

```
| Repo | Branch | Status | Action |
|------|--------|--------|--------|
| game-api | feat/coin-fraction | CLEAN_BRANCH | checkout master, pull |
| client-api | master | DIRTY_MASTER | branch + commit, checkout master, pull |
| common-errors | master | CLEAN_MASTER | pull |
```

## Phase 2: Commit Dirty Repos

Process each dirty repo **individually** (need to read diffs for meaningful commit messages).

### DIRTY_MASTER repos

1. Run `git diff --stat` and `git diff` (truncate if huge) to understand changes
2. Derive a branch type and slug from the changes:
   - Type: `feat`, `fix`, `refactor`, `chore`, `docs`, `test`, etc.
   - Slug: lowercase, hyphens, max 55 chars after prefix — e.g. `feat/add-retry-logic`
   - Must match pattern: `^(build|chore|ci|docs|feat|fix|perf|refactor|revert|style|test)\/[a-z0-9\-]{1,55}$`
3. Create the branch: `git checkout -b <type>/<slug>`
4. Stage and commit (see commit rules below)

### DIRTY_BRANCH repos

1. Run `git diff --stat` and `git diff` to understand changes
2. Stage and commit (see commit rules below)

### Commit Rules

- `git add -A` to stage everything
- Write a conventional commit message: `type(scope): description`
- Scope is the repo name collapsed (no hyphens): `gameapi`, `slotcatalog`, `commonerrors`, `clientapi`
- Keep to a single line
- Use a HEREDOC to pass the message:
  ```bash
  git commit -m "$(cat <<'EOF'
  type(scope): description
  EOF
  )"
  ```
- NEVER include Co-Authored-By lines
- NEVER include AI attribution of any kind

## Phase 3: Checkout Master & Pull

Batch all repos (10-15 per bash call). For each repo:

```bash
cd /path/to/repo && git checkout master && git pull
```

Use `;` (not `&&`) between repos so one failure doesn't block others. Handle pull failures gracefully — log them and continue.

For repos already on clean master, just `git pull`.

## Phase 4: Final Summary

Print a final report:

```
## Reset Complete

- **Repos processed:** 78
- **Already clean on master:** 65
- **Branches preserved:** 8 (list them with repo name + branch)
- **Commits created:** 5 (list them with repo name + message)
- **Errors:** 0 (or list any failures)

All repos are now on master.
```

Include the list of preserved branches so the user knows where their work-in-progress lives.
