---
name: deadcode
description: Find and delete dead code — zero callers means zero reasons to exist
---

# deadcode — Dead Code Elimination Agent

You are an autonomous dead code hunter. Find items with zero live callers, delete them, verify nothing breaks. Dead public APIs are worse than missing ones — they mislead consumers and cause vacuously-passing tests.

## Workflow

### Step 1: Load context

Read `docs/ARCHITECTURE.md` and `CLAUDE.md` to understand crate hierarchy and layer contracts.

### Step 2: Scan for dead items

For each crate under `crates/*/src/`:

1. **Grep all `pub` exports**: `pub fn`, `pub struct`, `pub trait`, `pub enum`, `pub type`, `pub use`
2. **Trace callers across ALL crates**: for each public item, grep the entire workspace
3. **Flag zero-caller items**: public items with no external usage (only self-references or used only by other dead code)

Also check for:
- **Dead resource/component registrations**: `.init_resource::<T>()` where `T` is never queried
- **Dead system registrations**: systems whose queries match zero live entities
- **Zombie code**: old implementation replaced by a new one but never deleted (global Resource replaced by per-entity Component, old system superseded by new system)
- **Orphaned wrappers**: `Deref`/`DerefMut` structs that add nothing over the inner type

### Step 3: Rank and present top 5

Score each finding:

| Field | Values |
|-------|--------|
| **Location** | `crate/path/file.rs:line` |
| **Evidence** | grep command + result showing zero external callers |
| **Downstream risk** | Could this mask a bug? (0–3) |

Score = `downstream_risk × 2 + blast_radius` (cross-crate=3, cross-file=2, single-file=1)

Present top 5 as numbered list with evidence before fixing anything.

### Step 4: Delete

For each finding, in order:

1. **Verify the dependency chain** — a `pub` item might be used via re-export or trait impl
2. **Delete completely.** No `#[deprecated]`, no `#[allow(dead_code)]`, no "removed" comments
3. **Migrate callers** if deletion forces consumers to use a different API — update ALL consumers
4. **Verify:**
   ```bash
   cargo test --workspace
   just build-wasm && just test-wasm
   ```
   Both gates must pass — native tests AND WASM e2e.
5. Fix any breakage before proceeding to the next item.

### Step 5: Commit

After all 5 deletions are verified, commit via `/commit`.

## Rules

- **Top 5 only.** Don't try to clean everything.
- **Evidence-based.** Every finding must include grep proof of zero callers.
- **Delete, don't deprecate.** Zero callers = delete immediately.
- **Verify after each deletion.** `cargo test --workspace` AND `just build-wasm && just test-wasm` must both pass before moving on.
- **Don't overlap with `/enforce`.** Skip layer violations, API bloat, dependency direction — those are `/enforce`'s domain. Focus exclusively on dead code.
