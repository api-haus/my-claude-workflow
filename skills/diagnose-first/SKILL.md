---
name: diagnose-first
description: Methodology for debugging confusing, intermittent, or "magical" bugs. Forces observation before action. Invoke when symptoms have multiple plausible causes, when one or more speculative fixes have failed, or when the user pushes back with "stop guessing."
---

# diagnose-first

When you can't read the actual values flowing through the system, you are guessing. **Make it observable before you make it work.** One five-minute diagnostic dump eliminates more hypothesis space than one hour of theorizing — and far less than one wrong fix.

## When this skill applies

Invoke when **any** of these are true:

- The user reports symptoms with multiple plausible causes.
- You've already proposed one or more fixes that didn't resolve the issue.
- The bug is intermittent, position-dependent, time-dependent, or "magical."
- The user has said something like "stop guessing," "let's diagnose," "we can run tests."
- You catch yourself writing "this explains the symptom" about a third or fourth different hypothesis.

If you're already confidently iterating on a known-correct mental model, you don't need this skill. It's specifically for the moments when your model is wrong and you don't yet know it.

## The core protocol

1. **Stop proposing fixes.** Edit nothing. Catalog the user's observations *literally*. Each phrase the user used is a hard constraint on the hypothesis space — don't summarize them away.
2. **Generate ≥ 3 hypotheses.** Resist fixating on the most plausible. Plausibility is not proof; multiple hypotheses can explain the same symptom equally well.
3. **For each hypothesis, ask: what would the broken intermediate state *look like* if this were true?** If you can't name a concrete observable that would distinguish it, the hypothesis is too vague to fix.
4. **Pick the cheapest probe that discriminates the most hypotheses at once.** Usually a buffer dump, a value-range log, a constant-pattern override. Implement the probe — *not a fix*.
5. **Read every column of the probe output.** The bug-revealing signal is often in something you weren't focused on. Notice anomalies that *contradict* your current hypothesis — those are gold.
6. **Once you have data, the fix is usually obvious.** If it isn't, you need a sharper probe; not another fix.

## Anti-patterns — name them in yourself

- **"Most likely it's X — let me fix X."** Likely ≠ confirmed. Fix-first burns trust and muddies the signal for the next attempt.
- **"This explains the symptom."** So might four other hypotheses. Explanation is not test.
- **"Let me try Y and see if it helps."** Now the user is your test harness. Their time is more expensive than yours; your diagnostic is cheaper than their re-test cycle.
- **Stacked fixes.** Multiple speculative changes in flight = nobody knows which (if any) helped. When stuck, *revert speculation* before adding more.
- **"It's just a quick fix, no need to instrument."** Quick fixes that miss become hours. The instrument is the quick fix.
- **"The user's observation is probably imprecise."** Treat user-reported phrasing as load-bearing. "Exactly 3 seconds," "stays culled," "only when far" — every word constrains.

## Symptom → probe mapping

| Symptom shape | What to dump / probe |
|---|---|
| **Stuck state, doesn't recover when inputs change** | The intermediate data values that *should* change frame-to-frame. Are they actually updating? Hash or sample across frames. Identical = frozen upstream. |
| **Random pattern that locks when motion stops** | Sub-pixel / sub-texel alignment between producer write coords and consumer read coords. Off-by-half is common. |
| **Works near, breaks far / works low, breaks high** | Storage layout per range. Different mips, LODs, precision tiers, regions — dump each *independently* to find which bucket is corrupt. |
| **Specific timing repeats per action (e.g., "exactly 3 s")** | Pipeline depth or async warmup, *not* one-time compile. One-time events don't repeat per toggle. |
| **Math looks right but values are wrong** | Suspect API/hardware contracts: constant-buffer alignment, `globallycoherent` semantics, format reinterpretation, OOB writes silently dropped, sampler-state defaults. |
| **Tile-aligned / texel-aligned artifact boundaries** | Coordinate-system mismatch between producer and consumer. Or layout-stride mismatch in a flat buffer. |
| **Intermittent crash / flicker tied to camera state** | State leak across cameras / frames in shared resources (atomic counters, pool-aliased transients, persistent SamplerStates). |

## Diagnostic templates

- **Buffer scan.** Walk the data once and report `min / max / mean / NaN / INF / negative / out-of-range` counts per logical region. One log line per call. Reveals corruption, freezing, range violations, and layout bugs simultaneously.
- **Constant-pattern producer.** Replace the producer with a known constant (`0.5`, `0xDEADBEEF`, etc.). If the consumer doesn't see the pattern, the bug is in the *path*, not in the math. If it sees a *shifted* pattern, you have an offset bug.
- **Per-region statistics.** When data has natural buckets (mips, layers, LODs, time slices), report each independently. A bug that affects only some buckets is a layout / addressing bug, full stop.
- **Frame-to-frame diff.** Hash or sample data across frames. Identical hash = frozen pipeline; drifting = updating (but possibly wrong); diverging = nondeterminism (race, uninit memory).
- **Round-trip identity test.** Write known values, read them back. If they differ, the path corrupts. Cheap and conclusive.
- **Two views of the same buffer.** Bind a buffer with one type as the producer and a different type as a debug consumer. Reveals format / packing assumptions.

## After the probe runs

Before generating a fix:
- Can you name the *exact data layout or value class* that's wrong?
- Does the new hypothesis predict every observation, including the ones that surprised you?
- Is there one more probe (≤ 5 min) that would *confirm* before you change code?

If yes to all three, fix. If not, sharpen the probe.

## Honest self-checks (run silently when stuck)

- "Am I about to propose another fix without observing new data?"
- "Does my current hypothesis predict observable behavior I haven't checked?"
- "Have I been asking the user to verify fixes when one diagnostic dump would tell us both?"
- "When was the last time I *read* probe output instead of theorizing?"
- "How many speculative changes are in flight right now? Should I revert before adding more?"

If you answer any of these unfavorably, stop and instrument.

## Worked example (composite, drawn from real session)

Symptom: HiZ occlusion culling over-culls foreground tiles intermittently. Symptoms shifted with each fix attempt:

- "Rotation-bistable" → tried per-camera atomic counter (real bug, didn't fix).
- "Off-by-quarter sample alignment" → tried UV math fix (real bug, didn't fix).
- "Burst FloatMode async takeover" → wrong; user disqualified ("this would only happen once after recompile, but it repeats").
- Tried four more hypotheses without testing.

The user said: *"we don't have to guess, we can literally DIAGNOSE THIS BY RUNNING SPECIFIC TESTS."*

Five-minute fix: a buffer-scan diagnostic logging `min/max/mean/NaN/INF/...` per mip on every readback. First run output:

```
m0=128² min=0 max=2.0e-4 mean=1.8e-4
m1=64²  min=0 max=0    mean=0    ← all zero
m2=32²  min=0 max=0    mean=0    ← all zero
m3=16²  min=0 max=0    mean=0    ← all zero
m4=8²   min=1.7e-4 max=1.9e-4    ← values resemble m0
```

Mip 1/2/3 all-zero, mip 4–7 carrying mip-0-magnitude values. Layout bug, not a math bug. Root cause: HLSL `uint _HiZFlatOffsets[12]` packs each scalar at 16-byte stride; `SetComputeIntParams` writes at 4-byte stride. Shader read garbage offsets for mips 1+, sending mip-1 writes into mip-4's region. *Every* prior symptom — close-up working, far culling, "tiles stay culled," "exactly 3 seconds" — fell out of this one cause.

Lesson: **the diagnostic should have been the first action, not the seventh.** Total wall-clock cost of fix-first detours: hours. Total cost of the diagnostic: ~5 minutes of code, ~5 seconds to read.
