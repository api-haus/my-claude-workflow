---
name: hygiene
description: Compact CLAUDE.md files and memory — strip redundancy, preserve sharp rules
---

# hygiene — Configuration Hygiene Agent

Compact and deduplicate all Claude configuration files. Every token in these files costs context window space in every session. Ruthlessly eliminate waste while preserving essential rules, corrections, and gotchas.

## Targets

1. `~/.claude/CLAUDE.md` — global rules
2. `CLAUDE.md` — project rules (repo root)
3. Auto-memory files in `.claude/projects/*/memory/`

## Workflow

### Step 1: Read all targets

Read all three files. Build a mental model of what each one says.

### Step 2: Identify waste

Flag for removal:

- **Redundancy across files**: same rule stated in both CLAUDE.md and memory — keep in CLAUDE.md, remove from memory
- **Redundancy with code**: implementation details that are obvious from reading the source (function signatures, field names, module structure)
- **Redundancy with docs**: information that's in `docs/ARCHITECTURE.md` or other checked-in docs
- **Verbose phrasing**: multi-sentence explanations where a single line suffices
- **Stale information**: references to removed features, old APIs, or resolved issues
- **Generic advice**: rules that restate Claude's default behavior (e.g. "read files before editing")
- **Examples within rules**: if the rule is clear without the example, drop it

Flag for preservation:

- **Sharp corrections**: "do X, NOT Y" gotchas learned from real bugs (e.g. Bevy observer API)
- **Non-obvious gotchas**: pixel format surprises, warmup frame counts, driver workarounds
- **Hard rules**: things the user explicitly mandated that override defaults
- **Practical shortcuts**: constructor patterns, test helpers, paths that save lookup time

### Step 3: Rewrite

For each file, produce a compact version:

- One line per rule/fact where possible
- Group related items under minimal headers
- Use `code formatting` for identifiers, paths, commands
- Remove all filler words ("Note that", "It's important to", "Make sure to")
- Merge near-duplicate entries
- Remove section headers that have only one item (inline the item into parent section)

### Step 4: Write

Overwrite each file with the compact version.

### Step 5: Verify

Count lines before and after. Report reduction percentage per file.

## Rules

- **Never remove hard user mandates** (git rules, attribution rules, verification requirements, WASM build/test gates, worktree rules).
- **Never add new content.** This is subtraction only.
- **Memory is cheapest to cut.** If something is in both CLAUDE.md and memory, delete it from memory.
- **CLAUDE.md is most expensive.** It's loaded every session. Every line must earn its keep.
- **Don't touch skills.** Skill files have their own structure and are only loaded on invocation.
