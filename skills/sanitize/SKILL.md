---
name: sanitize
description: Audit all tracked files for leaked references to external proprietary code
---

# Sanitize — Attribution Leak Audit

You are a read-only audit agent. Your job is to scan every tracked file in the repository for references to external proprietary implementations that should have been removed during sanitization. You do NOT modify any files.

## When to Use

After sanitizing a repo to remove references to external codebases studied as reference material — squashed histories, rewritten comments, moved sensitive docs to gitignored directories.

## Source of Truth

The project's code attribution rules are defined in the root `CLAUDE.md` and/or `~/.claude/CLAUDE.md`. Read both before starting. These define:

- **Banned terms**: Names, URLs, identifiers, or naming conventions from the external codebase
- **Allowed exceptions**: Your own identifiers that happen to match (e.g. your own plugin names)
- **Safe zones**: Gitignored directories where cross-references are intentionally kept

If no attribution rules exist in CLAUDE.md, ask the user what terms to scan for before proceeding.

## Audit Process

### Step 1: Extract rules

Read `CLAUDE.md` (project root) and `~/.claude/CLAUDE.md` (global). Extract:

- **Hard-ban patterns**: Names, URLs, identifiers that must have zero hits in tracked files
- **Exceptions**: Your own identifiers that are allowed
- **Gitignored safe zones**: Directories excluded from audit (e.g. `docs/_internal/`)

### Step 2: Get file list

```bash
git ls-files
```

This is the audit scope. Only tracked files. Never audit gitignored directories.

### Step 3: Hard match scan

For each hard-ban pattern, grep all tracked files (case-insensitive where appropriate):

```bash
git ls-files | xargs grep -n -i '<pattern>'
```

Filter out allowed exceptions. Every remaining hit is severity **HARD**.

Also scan for:

- External naming conventions (e.g. `FPrefix*` or `TPrefix*` for C++ codebases)
- URLs to the external project
- Author names associated with the external project

### Step 4: Soft match scan

Scan for indirect attribution patterns:

- `"inspired by"`, `"based on"`, `"adapted from"`, `"ported from"` — without self-contained technical justification
- `"matches the"`, `"follows the"`, `"equivalent to"` — in proximity to language/framework names of the external codebase
- CamelCase or naming patterns that look like they came from the external codebase's conventions
- Comments that describe "how X does it" where X could be inferred as the external project

Every hit needs context review. Severity **SOFT**.

### Step 5: Structural checks

- Verify gitignored safe zones do NOT appear in `git ls-files` output
- Scan all commit messages in the current branch: `git log --format='%B'` — apply same hard-ban patterns
- Check license fields in manifest files (`Cargo.toml`, `package.json`, etc.) match intended license

### Step 6: Report

Present findings as a structured table:

```markdown
# Sanitization Audit Report

**Repo:** <repo name>
**Date:** <ISO date>
**Tracked files scanned:** <count>
**Commit messages scanned:** <count>

## Summary

| Severity | Count |
|----------|-------|
| HARD     | N     |
| SOFT     | N     |
| CLEAN    | (if zero findings) |

## Findings

### HARD: <short title>
**File:** `path/to/file.rs:42`
**Match:** `the offending text`
**Suggestion:** <replacement text or "delete line">

### SOFT: <short title>
**File:** `path/to/file.rs:99`
**Match:** `the text in context`
**Assessment:** <why this might or might not be a problem>

## Commands Run

<list every grep command and its output for reproducibility>
```

If everything is clean, confirm with the exact commands run and their zero-match output.

## Rules

- **Read-only.** Do NOT modify any files. This is an audit only.
- **Never audit gitignored directories.** Even if you can read them. They are intentional safe zones.
- **Never audit `~/.claude/CLAUDE.md`.** Global config is not in the repo.
- **Show your work.** Every grep command and its output must be in the report for reproducibility.
- **No false positives.** Filter out documented exceptions before reporting. If an identifier is your own (documented in CLAUDE.md as allowed), do not flag it.
- **Context matters for SOFT matches.** A `C++` mention in FFI build docs is legitimate. The same mention in a design comment comparing your approach to an external one is a leak.
