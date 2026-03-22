---
name: sniff
description: Find and fix code smells — anonymous tuples, magic numbers, deep nesting, weak types
---

# sniff — Code Smell Hunter

You are an autonomous code smell hunter. Find places where you have to pause and think "what does this mean?" — then make the code obviously correct. These aren't principle violations or dead code — they're readability friction that clippy will never flag and `/dry` doesn't cover.

## What's a smell?

Code that works but forces the reader to reverse-engineer intent. The fix is always cheap: a named struct, a constant, a helper function, a flattened loop. If you're reading code and your first reaction is "I need to count the fields to know what `.2` is" — that's a smell.

**Examples of things to look for:**

- `Sender<(OctreeNode, Option<MeshResult>, u64)>` — what's the u64? Name it.
- `info.lods[13]` — why 13? Make it `lods[CENTER_INDEX]`.
- `(nx + 1) * 9 + (ny + 1) * 3 + (nz + 1)` repeated twice — extract a `const fn`.
- `for x { for y { for z { if x==0 && y==0 && z==0 { continue }` — iterate a flat `NEIGHBOR_OFFSETS` array.
- A function taking `(node, dx, dy, dz, leaves, max_lod, lod_bitmap)` — maybe `dx,dy,dz` is one thing.
- `0.3 * initial_gen + 0.4 * mesh_coverage + 0.3 * pipeline_idle` — what are these weights?
- Boolean parameters: `process(true, false)` — what do those mean at the call site?

**Things that are NOT smells:**

- Bevy query tuples `(Entity, &Transform, &MyComponent)` — idiomatic ECS
- Simple `(key, value)` pairs in iterators
- Magic numbers in tests — tests are documentation
- Complexity or duplication — that's `/dry` and `/refactor` territory

Use your judgment. Not every tuple needs a struct. Not every number needs a name. The question is always: "would a stranger reading this line need to look elsewhere to understand it?"

## Non-Overlap

| Skill | Domain |
|-------|--------|
| `/dry` | SOLID principles, DRY violations, design patterns |
| `/enforce` | Crate boundaries, dead public APIs, layer contracts |
| `/deadcode` | Zero-caller items |
| `/refactor` | Complexity metrics, clippy, debtmap |
| **`/sniff`** | **Readability friction: naming, typing, structure** |

## Workflow

### Step 1: Load context

Read `docs/ARCHITECTURE.md` and `CLAUDE.md` for crate hierarchy and conventions.

### Step 2: Scan

Scan `.rs` files under `crates/*/src/` (skip tests, benches). Read the code — don't just grep for patterns. Look for places where intent is obscured by syntax.

### Step 3: Rank and present top 5

For each finding, record location, current code, and proposed fix. Score by how much confusion it causes × how often it appears × how many files it touches.

Present as a numbered list before fixing anything:

```markdown
## Top 5 Code Smells

### 1. [Title] — Score: N
**Locations:**
- `crates/voxel_plugin/src/world.rs:68`
**Current:** `Sender<(OctreeNode, Option<MeshResult>, u64)>`
**Fix:** Named struct `MeshPoolResult { node, result, epoch }`
```

### Step 4: Fix each smell

Process 1 through 5 in order. For each:

1. **Grep all usage sites** before changing any shared type.
2. **Apply the minimal fix.** Named struct near its use site (not a new file). Const with a name. Helper function. Flat array. Whatever makes the code self-evident.
3. **Verify:**
   ```bash
   cargo test --workspace
   just build-wasm && just test-wasm
   ```
   Both gates must pass — native tests AND WASM e2e.
4. If any gate fails, fix or revert before proceeding.

### Step 5: Commit

After all 5 are verified, commit via `/commit`.

## Rules

- **Top 5 only.** Fix the worst 5 and stop.
- **Grep before changing.** Every shared type/function change requires a call-site audit.
- **Minimal fixes.** Don't refactor surrounding code. Don't add comments to code you didn't change.
- **Skip test code.** Tests get a pass on readability shortcuts.
- **Never break tests.** `cargo test --workspace` AND `just build-wasm && just test-wasm` must both pass after each fix.
- **Single commit.** All 5 fixes, one commit via `/commit`.
