---
name: tdd
description: RED/GREEN TDD — write a failing test first (Phase 1), then fix (Phase 2). Enforces strict phase separation.
---

Three strict phases. Never blend them. The argument is the plan or description of the bug/feature.

# Plan Mode Awareness

If plan mode is active when this skill is invoked, you MUST embed the full TDD rules below into the plan file itself. Skill context is wiped on the plan→execution transition — the executing agent will only see the plan file. Structure the plan as follows:

1. **Begin with a `## TDD Rules (enforced)` section** at the top of the plan. Copy the Phase 1, Phase 2, Phase 3, Rules, and checklist sections verbatim into this block.
2. **Structure the rest of the plan into three clearly labeled phases:**
   - `## Phase 1: RED` — what test to write, where, why it must fail, and the exact run command. No production code changes described here.
   - `## Phase 2: ROOT CAUSE` — analyze RED output, trace the code path, identify the exact root cause. No code changes — only investigation. Present findings to user.
   - `## Phase 3: GREEN` — the minimal production code fix derived from root cause analysis. Include verification commands.
3. **Include the gate rules prominently**:
   - "Do NOT begin Phase 2 until Phase 1 test is RED and user has confirmed."
   - "Do NOT begin Phase 3 until root cause is identified and user has confirmed."
4. After writing the plan, call ExitPlanMode as normal.

The executing agent must be able to follow TDD discipline from the plan file alone.

# Phase 1: RED

Goal: a test that **fails** and proves the problem exists. This proves the bug is real and reproducible — it does NOT explain why it happens. Understanding "why" is Phase 2's job.

1. **Read the plan/description.** Identify what the test must assert.
2. **Write the test.** Follow project test design rules (CLAUDE.md). No production code changes.
3. **Run the test.** It MUST fail.
   - If it **passes**: the test is wrong — it doesn't actually catch the bug. Diagnose why, fix the test, re-run. Loop until RED.
4. **Report RED to the user.** Show the failure output. Confirm it matches the expected bug symptom.
5. **Stop.** Do not proceed to Phase 2 until the user confirms RED.

### RED checklist
- [ ] Test written — no production code touched
- [ ] Test ran and FAILED
- [ ] Failure reason matches the bug/feature description (not a test setup error)
- [ ] User confirmed RED

# Phase 2: ROOT CAUSE

Goal: understand **why** the bug happens. Phase 1 proved it exists — Phase 2 explains it. **No code changes.**

1. **Analyze the failure output.** What failed, where, and why?
2. **Trace the code path.** Read the production code that the test exercises. Follow the call chain from the failure point back to the origin.
3. **Identify the root cause.** State it precisely: what condition triggers the bug, why the current code doesn't handle it, and what the minimal fix is.
4. **Report findings to the user.** Present the root cause and proposed fix. Do not write any code yet.
5. **Stop.** Do not proceed to Phase 3 until the user confirms the root cause and approach.

### ROOT CAUSE checklist
- [ ] Failure output analyzed
- [ ] Code path traced — call chain documented
- [ ] Root cause identified — precise condition stated
- [ ] Minimal fix proposed (described, not implemented)
- [ ] User confirmed root cause and approach

# Phase 3: GREEN

Goal: minimal production code change that makes the test pass.

1. **Apply the fix.** Only what's needed — no extras.
2. **Run the RED test again.** It MUST pass.
   - If it **fails**: the fix is wrong. Iterate on production code only. Loop until GREEN.
3. **Run the full test suite** (project-specific commands from CLAUDE.md).
4. **Report GREEN to the user.** Show pass output.

### GREEN checklist
- [ ] Fix applied — minimal change
- [ ] RED test now passes
- [ ] Full suite passes (no regressions)
- [ ] User confirmed GREEN

# Rules

- **Phase 1 is a gate.** Never write production code during Phase 1. Never skip to Phase 2 because "the fix is obvious."
- **Phase 2 is a gate.** Never write production code during Phase 2. Never skip to Phase 3 because "the fix is obvious." The root cause must be confirmed before any fix is written.
- **A test that passes without the fix is not a test.** It's decoration. If the test passes on first run, it's broken — fix the test, not the code.
- **Loop, don't bail.** If RED doesn't arrive on first try, diagnose and iterate. Don't report "the test passes without the fix" and ask what to do — figure out why and make it fail.
- **The failure message IS the spec.** The assertion message should describe the bug clearly enough that someone reading the test output understands what broke.
