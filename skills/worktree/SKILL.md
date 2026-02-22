---
name: worktree
description: Create or switch to a git worktree for isolated feature/fix development
---

# MANDATORY WORKFLOW

When this skill is invoked, you MUST follow these steps IN ORDER. Do NOT skip any step.

## Step 1: Determine Slug (REQUIRED)

Generate a slug from the user's task description:
- Extract the core concept (2-3 words max)
- Convert to kebab-case: `player-collision`, `fix-auth-timeout`, `add-retry-logic`
- Do NOT ask the user for the slug name - generate it automatically

Examples:
- "Fix the player collision detection" → `player-collision`
- "Add retry logic to API calls" → `api-retry-logic`
- "Refactor authentication flow" → `auth-flow`

## Step 2: Determine Branch Type (REQUIRED)

| Task type | Branch prefix |
|-----------|---------------|
| Features  | `feat/`       |
| Fixes     | `fix/`        |
| Refactors | `refactor/`   |
| Docs      | `docs/`       |

## Step 3: Get Project Name

```bash
basename "$(pwd)"
```

## Step 4: Create or Switch to Worktree

```bash
PROJECT_NAME=$(basename "$(pwd)")
SLUG="<your-generated-slug>"
TYPE="<feat|fix|refactor|docs>"

if [ -d "../${PROJECT_NAME}-${SLUG}" ]; then
    cd "../${PROJECT_NAME}-${SLUG}"
    echo "Switched to existing worktree"
else
    git worktree add "../${PROJECT_NAME}-${SLUG}" -b "${TYPE}/${SLUG}"
    cd "../${PROJECT_NAME}-${SLUG}"
    echo "Created new worktree"
fi
```

## Step 5: Install JS Dependencies (if applicable)

After creating a **new** worktree, check for `package.json` and run `pnpm install`:

```bash
if [ -f "package.json" ]; then
    pnpm install
fi
```

Skip this step when switching to an existing worktree.

## Step 6: Plan Header (MANDATORY when entering plan mode)

If entering plan mode, you MUST write this EXACT header at the TOP of the plan file BEFORE any other content.
Use **absolute paths** so the header survives context compression and fresh sessions:

```markdown
## Worktree Context
- **Slug:** `<slug>`
- **Todo:** `docs/todo/<slug>.md`
- **Worktree:** `/home/midori/_dev/${PROJECT_NAME}-<slug>`
- **Branch:** `<type>/<slug>`

### ⚠️ CRITICAL: Working Directory
**ALL file operations (Read, Edit, Write, Glob, Grep) MUST use absolute paths in the worktree:**
- ✅ `/home/midori/_dev/${PROJECT_NAME}-<slug>/src/...`
- ❌ `/home/midori/_dev/${PROJECT_NAME}/src/...` (WRONG - this is main tree)

Do NOT work in the main repository. The worktree is your working directory.

---

```

This is NOT optional. The plan file MUST start with this header.

## Naming Convention

| Component | Format | Example |
|-----------|--------|---------|
| Slug | kebab-case, 2-3 words | `player-collision` |
| Todo file | `docs/todo/<slug>.md` | `docs/todo/player-collision.md` |
| Worktree | `/home/midori/_dev/${PROJECT_NAME}-<slug>` | `/home/midori/_dev/myproject-player-collision` |
| Branch | `<type>/<slug>` | `feat/player-collision` |

The `<slug>` MUST be identical across all three for `/merge` cleanup to work.

## Rules

1. NEVER ask user for slug name - generate automatically
2. Location: sibling dirs (`../${PROJECT_NAME}-<slug>`)
3. Shared target dir via `~/.cargo/config.toml` -- no cache copying needed
4. All work happens in the worktree, not the main repo
5. Never push -- user pushes after review
6. Plan mode ALWAYS gets the worktree context header
