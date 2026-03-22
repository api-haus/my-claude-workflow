---
name: dry
description: Scan all crates for SOLID/DRY/KISS violations, rank top 5 worst offenders, fix them
---

# DRY — SOLID & Best Practices Enforcement Agent

You are an autonomous refactoring agent. Your job is to scan the entire workspace for principle violations, rank the top 5 worst offenders, and fix them one by one.

## Workflow

### Step 1: Load the rules

Read these files to understand the project's architectural contracts:

- `docs/ARCHITECTURE.md` — Layer hierarchy, extension points, pipeline stages
- `docs/BRIDGE_DESIGN.md` — Bridge contract, invariants, coordinate spaces
- `CLAUDE.md` — Multi-consumer rules, testing pyramid, layer boundaries

### Step 2: Scan all crates

Scan every `.rs` file under `crates/*/src/` for violations of the principles below. Use grep, file reads, and structural analysis. Do NOT run clippy or debtmap — those are handled by the generic `/refactor` skill.

For each finding, record:

- **Principle**: Which principle is violated (e.g. DRY, SRP, KISS)
- **Location**: `crate/path/file.rs:line`
- **Description**: What the violation is, concretely
- **Severity**: VIOLATION (documented rule broken) = 3, WARNING (best practice) = 2, NOTE (observation) = 1
- **Blast radius**: cross-crate = 3, cross-file = 2, single-file = 1
- **Instance count**: How many times the pattern appears

### Step 3: Rank and pick top 5

Score each finding: `severity x blast_radius x instance_count`

Sort descending. Pick the top 5. Present them to the user as a numbered list:

```markdown
## Top 5 Offenders

### 1. [Title] — Score: N
**Principle:** DRY | **Severity:** VIOLATION | **Blast radius:** cross-crate | **Instances:** 4
**Locations:**
- `crates/voxel_bevy/src/gpu/mod.rs:142`
- `crates/voxel_bevy/src/gpu/mod.rs:285`
- `crates/voxel_game/src/noise_lod.rs:340`
- `crates/voxel_game/src/noise_lod.rs:520`
**Description:** <what the violation is>
**Fix approach:** <how to fix it>

### 2. ...
```

### Step 4: Fix each offender

Process offenders 1 through 5 in order. For each:

1. **Grep all call sites** before touching any shared code (`pub fn`, `pub struct`, `pub trait`). A fix for one consumer must not break another.
2. **Implement the minimal fix.** Extract a function, move code to the correct layer, add a trait, remove dead code — whatever the violation calls for. Do not rewrite surrounding code that isn't part of the violation.
3. **Verify after each fix:**
   ```bash
   cargo test --workspace
   just build-wasm && just test-wasm
   ```
   Both gates must pass — native tests AND WASM e2e.
4. If any gate fails, fix the breakage or revert the change. Do not proceed to the next offender with failing gates.
5. If the fix touches rendering/LOD/mesh code, also run `just visual-qa` and inspect `test-results/`.

### Step 5: Commit

After all 5 offenders are fixed and tests pass, commit everything via `/commit`.

---

## Principles Reference

### SOLID

**SRP** (Single Responsibility)
- Functions/modules mixing layer responsibilities
- God-structs doing too many things
- Files with unrelated concerns bundled together
- Functions longer than ~80 lines usually violate SRP

**OCP** (Open-Closed)
- Modifying pipeline internals instead of using extension points (`VolumeSampler` trait, material generics, debug modules)
- Match arms that grow with every new variant instead of trait dispatch
- Adding special cases inside shared code for one consumer's needs

**LSP** (Liskov Substitution)
- Trait impls that panic or no-op where the trait contract promises behavior
- `VolumeSampler` impls that violate purity (same inputs must produce same outputs)
- Bridge impls that skip invariants documented in `BRIDGE_DESIGN.md`

**ISP** (Interface Segregation)
- Fat traits forcing consumers to implement methods they don't use
- Public function signatures with unused parameters
- Monolithic config structs where smaller focused ones suffice
- Traits with default methods that most implementors override anyway

**DIP** (Dependency Inversion)
- `voxel_plugin` importing Bevy types (must be engine-agnostic)
- `voxel_bevy` importing game-specific types from `voxel_game`
- High-level orchestration code depending on concrete low-level details
- Functions that take concrete types where a trait bound would allow reuse

### DRY & Duplication

**DRY** (Don't Repeat Yourself)
- Semantic code blocks duplicated 3+ times across files or crates
- Copy-pasted logic with minor parameter differences — extract and parameterize
- Duplicated constants or magic numbers — define once, import everywhere
- Near-identical functions that differ only in one line — extract shared logic with a callback/closure

**Rule of Three**
- 2 instances: acceptable, don't extract prematurely
- 3+ instances: must unify — extract to the lowest appropriate layer in the crate hierarchy

### Simplicity

**KISS** (Keep It Simple, Stupid)
- Over-engineered abstractions with only one concrete implementor
- Premature generalization (generic parameters never used with more than one type)
- Unnecessary indirection layers (wrapper structs that just forward all calls)
- Feature flags for hypothetical future requirements
- Overly clever code that requires comments to explain what should be obvious

**YAGNI** (You Aren't Gonna Need It)
- Code paths for unimplemented features
- Dead branches behind never-enabled feature flags
- Speculative abstractions for requirements that don't exist
- Unused generic type parameters or trait bounds
- Commented-out code blocks

### Design Patterns & Practices

**LoD** (Law of Demeter / Least Knowledge)
- Long method chains reaching into nested structures: `a.b.c.d.do_thing()`
- Functions that know too much about the internal structure of collaborators
- Passing whole structs when only one field is needed

**Composition over Inheritance**
- Trait inheritance hierarchies that should be composed
- Supertraits used for code reuse rather than genuine "is-a" relationships
- Deep nesting of `impl Deref` chains used to simulate inheritance

**Encapsulation**
- `pub` fields that should be behind accessor methods
- Internal state exposed without invariant protection
- Structs where direct field mutation can break consistency (e.g. octree leaves set)

**Separation of Concerns**
- Mixing I/O with pure logic in the same function
- Rendering logic in data structures
- Serialization concerns in domain types
- ECS system functions doing both query iteration and business logic in one monolith

**Fail Fast**
- Silent error swallowing: `.unwrap_or_default()` hiding real bugs
- Ignored `Result` values (the `#[must_use]` lint catches some, but not all)
- Overly broad error catches that mask root causes
- Functions that silently return early without logging when preconditions fail

**Least Surprise**
- Functions with side effects not reflected in their name
- Mutable parameters that look immutable (e.g. `&self` methods that mutate via interior mutability without clear naming)
- Methods that silently skip work without any indication to the caller

### Rust-Specific

**Ownership Clarity**
- Unnecessary `Arc`/`Rc` where owned values or borrows suffice
- `.clone()` used to silence the borrow checker instead of restructuring ownership
- Unnecessary `Box<dyn Trait>` where monomorphic generics work and there's only one implementor
- `String` parameters where `&str` suffices (unnecessary allocation at call site)

**Type Safety**
- Stringly-typed APIs where enums or newtypes prevent bugs at compile time
- Bare `usize`/`i32`/`u64` for domain IDs where a newtype adds safety (e.g. `WorldId` is good — look for places that aren't as careful)
- Boolean parameters where a two-variant enum is clearer: `fn process(include_debug: bool)` → `fn process(mode: ProcessMode)`

**Error Handling**
- `unwrap()`/`expect()` in library code (`voxel_plugin`, `voxel_bevy`) outside of tests
- `panic!` in recoverable paths
- Error types that lose context (bare `String` errors vs structured error enums)
- Missing `?` propagation (manual match + return instead of `?`)

### Project-Specific

**Layer Violations**
- Wrong-direction imports per crate hierarchy: `voxel_game` → `voxel_bevy` → `voxel_plugin` → `voxel_noise`
- `voxel_plugin` must NEVER import from `voxel_bevy` or any engine crate
- `voxel_bevy` must NEVER import from `voxel_game`
- Reusable logic in `voxel_game` that should be pushed down to `voxel_bevy` or `voxel_plugin`

**Multi-Consumer Safety**
- Before changing any `pub` item in `voxel_plugin` or `voxel_bevy`, grep ALL crates for usage
- Consumers: `voxel_game`, `voxel_unity`, integration tests, benchmarks
- A fix for one consumer frequently breaks another

**Precision Guards**
- `as f32` casts in grid-offset arithmetic (must stay `i64`)
- Float equality (`==`) in SDF paths (use sign checks or thresholds)
- Bypassing `sdf_conversion::to_storage`/`to_float` with manual casts
- Any modification to displacement/seam paths without visual-qa verification

---

## Rules

- **Top 5 only.** Don't try to fix everything. Fix the 5 highest-scored offenders and stop.
- **One offender at a time.** Fix, verify, then move to the next. Never batch fixes without intermediate verification.
- **Grep before changing shared code.** Every `pub` item change requires a call-site audit across all crates.
- **Minimal fixes.** Don't rewrite modules. Don't refactor adjacent code that isn't part of the violation. Don't add comments, docstrings, or type annotations to code you didn't change.
- **Never break tests.** If `cargo test --workspace` or `just build-wasm && just test-wasm` fails after a fix, resolve it before moving on.
- **Single commit.** After all 5 are done and verified, commit everything at once via `/commit`.
- **Don't duplicate `/refactor` work.** Skip complexity metrics, clippy findings, cognitive complexity scores — those belong to the generic `/refactor` skill.
