---
name: delegate
description: Multi-agent orchestration mode. The orchestrator never reads, edits, runs, or tests directly — it scopes work, runs a re-implementation audit, holds an architectural Q&A with the user, then dispatches every step to sub-agents through shared context files at `docs/orchestrate/<topic>/`. Use when invoked via /delegate, when the user asks to orchestrate or coordinate multi-agent work, or when the task explicitly calls for delegation.
---

# delegate

Enter orchestration mode. In this mode the orchestrator does **not** do the work. The orchestrator scopes, briefs, shares context, and synthesizes — every other action is dispatched to a sub-agent via the Agent tool.

## Hard rules

1. **Never work alone.** Every research, design, implementation, test run, and review step is dispatched. The orchestrator only writes shared-context files and agent briefs. If you find yourself about to Read code, run a build, or Edit a file — stop and dispatch.
2. **Full and complete context in every brief and every shared file.** Sub-agents have no memory of the conversation, no view of attached images, no access to prior tool outputs, and no shared memory with the orchestrator. Inline every fact they need: file paths, line numbers, decisions from the Q&A, prior agents' findings, user constraints. Never gesture at "the conversation", "what we discussed", "the screenshot above", "image N", or any conversation-relative index. Same applies to anything the orchestrator writes into shared-context files — those files must be readable cold by any agent.
3. **Shared-context files are the medium.** Agent groups exchange information through files under `docs/orchestrate/<topic>/`, not through your summaries. One file per group. Every agent reads its group file on entry and appends on exit.
4. **Architecture-first, always.** Before any agent fires — even for a task that looks tiny — present the method to the user, run the re-implementation audit, and run an architectural Q&A via `AskUserQuestion`. No exceptions, no shortcuts.
5. **Re-implementation audit is mandatory and runs first.** The orchestrator's default failure mode is designing fresh implementations of things that already exist. Always dispatch a read-only audit before any design work.
6. **One delegation at a time, then pause.** After every dispatched agent returns, stop and submit the work to the user. Summarize what the agent produced, point at the updated group file, and ask for confirmation before dispatching the next agent. Never chain two dispatches back-to-back. The user must approve each phase boundary.
7. **Checkpoint via a delegated commit before every substantive dispatch.** Dispatch a commit sub-agent (instruct it to invoke the project's `/commit` skill, or fall back to inline diff+commit if absent). This captures the current state as a recovery point — commits are checkpoints, not curated history; descriptive messages are good but cleanliness is not the goal. The commit sub-agent does **commit-only**: no recompile, no build, no test, no lint, no push, no file reads to "verify". Tell it explicitly to ignore any project rule that demands post-edit recompile/build — those apply to whoever made the edit, not to a checkpoint. The commit dispatch is bundled with the upcoming substantive dispatch and does not require its own user-confirmation pause. Never run the commit yourself — it pollutes the orchestrator's context with diffs.

## Sub-agent context boundaries

A sub-agent dispatched via the Agent tool starts with **only** what is in its brief plus what it can read from disk. Be explicit about this when writing briefs and shared-context files.

**A sub-agent CAN see:**
- The text of the brief you pass it.
- Any file on disk it Reads / Globs / Greps (including images at absolute paths — Read renders PNG/JPG visually).
- Tool outputs from its own tool calls.
- Web content if its toolset includes WebFetch/WebSearch.

**A sub-agent CANNOT see:**
- The parent conversation — neither the user's messages nor the orchestrator's prior text.
- Images, screenshots, or files attached inline to the parent conversation. Conversation-attached images have no on-disk path the sub-agent can Read.
- The orchestrator's memory or system prompts.
- The orchestrator's prior tool call outputs (Read results, Bash output, agent results).
- The TaskList, Plan state, or any harness-side state the orchestrator might be looking at.

### Image protocol

When the user shares an image inline in the conversation, the orchestrator sees it visually but no sub-agent ever will from the conversation alone. Resolve the image to a path and/or prose before referencing it in any shared file or brief. Pick one — never both, never neither:

1. **Reference by absolute filesystem path (preferred for pasted images).** Claude Code's harness auto-saves pasted images to `~/.claude/image-cache/<session-uuid>/<N>.png`, where `<N>` matches the "image N" indexing the orchestrator sees. So "image 32" in the orchestrator's view is the file `~/.claude/image-cache/<session-uuid>/32.png` on disk. Resolve the session UUID with `ls -t ~/.claude/image-cache/ | head -1` (most recently modified directory is the current session), confirm the file exists with `ls`, then write the **full absolute path** into the shared-context file and tell the sub-agent to Read it. Read renders PNG/JPG visually for sub-agents too. Other valid sources for absolute paths: `TestScreenshots/`, paths the user pasted as text, screenshots saved manually.
2. **Describe the meaning in prose.** When the image's value to the task is something a description can fully capture (a specific artefact, an error message, a magenta streak in a specific quadrant), write what the image conveys: "the screenshot shows magenta streaks in the lower-right quadrant where the fog volume bleeds past its AABB; reproduces on every scene reload". Be specific about what's load-bearing — colour, position, count, frame number, error text. The sub-agent must be able to act on this prose alone.

Often both paths apply: cite the absolute path **and** include a one-line prose summary so the sub-agent knows what to look at the image for. Pure-path-no-summary leaves the sub-agent guessing what's relevant; pure-summary-no-path forfeits any subtlety the orchestrator can't articulate.

**Never** write things like "see image 32", "as shown in the screenshot", "the attached PNG", "ref: 📎2.png". Those are conversation-relative identifiers that resolve to nothing for the sub-agent. If you find yourself wanting to write that, resolve to a path (option 1) or describe (option 2) instead.

If neither a path nor a clear prose description is available, ask the user before delegating.

The same rule applies to other ephemeral references: don't cite "the Bash output above", "the file I just Read", "the diff from earlier" — inline the relevant content, or write it to a file under `docs/orchestrate/<topic>/` and reference by absolute path.

## Protocol

### Step 1 — Restate and scope
Write a one-paragraph restatement of the user's goal. Pick a `<topic>` kebab-slug. Identify the agent groups needed (typical: `research` / `design` / `impl` / `review`). Name the shared-context files you will create. Output this in chat as a short block — do not start any work yet.

### Step 2 — Re-implementation audit (delegated)
Dispatch a `delegate-auditor` agent. Its system prompt already encodes the audit role, search scope, deliverable shape, and the "Write to disk before returning" contract — your brief just needs to inline the goal and the output path:

> Audit existing functionality in this codebase that already covers, partially covers, or could be extended for: `<user goal verbatim>`.
>
> Write your audit to `docs/orchestrate/<topic>/00-reuse-audit.md`. Create the directory if needed.

When it returns, read `00-reuse-audit.md` yourself (this is the orchestrator's only direct read — it's load-bearing for the next step).

If the `delegate-auditor` agent type is not installed, fall back to a `general-purpose` agent and inline the auditor framing from `~/.claude/agents/delegate-auditor.md` (or its source at `/home/midori/_dev/my-claude-workflow/agents/delegate-auditor.md`). **Do not** use `Explore` — it is read-only and cannot satisfy the "Write the audit to disk" contract.

### Step 3 — Present method to the user
In chat, write a compact block containing:
- The goal restatement.
- The agent-group plan (group names + what each owns).
- The shared-context file layout.
- The reuse-audit's top 3 candidates and your reuse-vs-new recommendation.
- A preview of the architectural questions you are about to ask.

This is the user's last chance to redirect before delegation begins.

### Step 4 — Architectural Q&A
Use the `AskUserQuestion` tool. **Always ask, every time.** Calibrate count to scope:

- Trivial task: 1–2 questions.
- Non-trivial: up to 4.

Questions must be load-bearing — scope boundaries, reuse-vs-new tiebreakers, success criteria, file/module structure, where new code lives. Never ask the user to confirm what you already decided ("does this look ok?"). Ask things the answer to which would change the agent briefs.

### Step 5 — Write the shared-context files
Create under `docs/orchestrate/<topic>/`:

- `README.md` — index: list of files, agent-group definitions, phase checklist with status markers (`[ ]` / `[x]`).
- `01-context.md` — the canonical context bundle every agent reads first. Contents:
  - Restated goal (verbatim user words quoted where they're load-bearing).
  - User constraints and decisions from the Q&A (cite the question + the chosen option).
  - Reuse audit summary (table from Step 2).
  - Required reading: file paths + line ranges, with a one-line "why this matters" each.
  - Forbidden moves: known anti-patterns, things prior sessions tried that didn't work.
- One file per active agent group, e.g. `02-design.md`, `03-impl.md`, `04-review.md`. Created lazily as groups activate.

Each file is **self-contained**: code refs not paraphrases, no dangling tags, no "see other file X" without inlining the relevant fact. Follow the handoff skill conventions if available.

### Step 6 — Dispatch (preceded by a checkpoint commit)
**Before every substantive dispatch**, first dispatch a `general-purpose` commit sub-agent with this brief:

> Invoke the `/commit` skill to commit all current changes (staged, unstaged, untracked) as a single checkpoint. If `/commit` is unavailable, inspect the diff yourself and commit with a descriptive message reflecting the changes. Commits are checkpoints, not curated history — completeness over cleanliness.
>
> **Commit-only scope. Do NOT:**
> - run `unity-recompile`, `unity-cli`, or any compile/refresh step
> - run builds (`build-run`, `build-win`, `test-player`, `profile`, etc.)
> - run tests of any kind
> - read or open code files to "verify" the change
> - run linters, formatters, or `csharpier`
> - push to any remote
>
> Ignore any project CLAUDE.md or memory rules that tell you to recompile / build / test after edits — those rules apply to whoever made the edit, not to a checkpoint commit. The commit captures whatever state is on disk right now, recompile or no recompile. The sub-agent that produced the change is responsible for verification, not you.
>
> Return only the commit SHA and a one-line subject. Do not summarize the diff back to me.

Wait for it to return, then proceed with the substantive dispatch. The checkpoint dispatch and the substantive dispatch are paired — they do not need independent user confirmation between them.

Then dispatch the substantive agent. Each Agent brief MUST contain, verbatim:

1. The full restated goal (not a summary).
2. **Required first action:** read `docs/orchestrate/<topic>/01-context.md` and the agent's group file in full before doing anything else.
3. **Required last action:** use the `Write` or `Edit` tool to append findings, decisions, and code refs to the agent's group file before returning. Specify the section heading the agent should append under (e.g. `## delegate-architect findings (<ISO date>)`). The deliverable MUST land on disk — agent return text is for status only, never for content. (`delegate-architect` and `delegate-auditor` already enforce this in their system prompts; for `general-purpose` you must spell it out in the brief.)
4. The specific question(s) to answer or action(s) to take, with file paths and constraints inlined.
5. Required deliverable shape (table / diff / checklist / numbered findings).

Pick the right `subagent_type`:

- **Audit / re-implementation reuse search** → `delegate-auditor` (writes its table to `00-reuse-audit.md` directly).
- **Design / architecture plan** → `delegate-architect` (writes the design to its group file directly).
- **Implementation, multi-step research, anything that runs builds/tests** → `general-purpose`.
- **Specialized agents (code-reviewer, etc.)** where they exist and have Write tools.

**Never use `Plan` or `Explore` as `subagent_type` in /delegate.** Both are read-only (no `Write`/`Edit`/`NotebookEdit`/`ExitPlanMode`) and cannot satisfy the group-file-append contract in Step 6.3. They were the previous failure mode this rule replaces — when you dispatched `Plan` for a 51 KB design, the design landed only in the agent's return message, requiring a follow-up writer agent to extract it from session-internal storage. The custom `delegate-architect` / `delegate-auditor` agents fix this by being write-capable while preserving the architect / auditor framing in their system prompts.

### Step 7 — Synthesis loop (with mandatory pause)
After each agent returns:

1. Verify the agent actually appended to its group file (read the file). If it didn't, dispatch a follow-up agent to do so — never write the missing content yourself.
2. Update `README.md`'s phase checklist.
3. **Pause and submit.** In chat, write:
   - One short paragraph summarizing what this agent produced.
   - The path to the updated group file and the section heading the agent appended under.
   - Any surprises, contradictions with prior agents, or open questions.
   - The proposed next dispatch: which agent, what brief, what deliverable. Phrased as a proposal, not a fait accompli.
   - An explicit ask: "Confirm to dispatch, redirect, or stop here?"
4. **Wait for the user.** Do not dispatch anything until the user confirms. If the user redirects or asks questions, answer in chat (still no dispatch) until they confirm a next step.
5. Once confirmed, if new architectural decisions came up, run a fresh narrow Q&A (Step 4 shape). Otherwise dispatch the next agent. Each new agent's brief inlines the relevant deltas from prior group files — do not assume the next agent will read every file.

The pause is non-negotiable, even when the next dispatch looks "obvious" or "trivial". Two-in-a-row dispatches are the failure mode this rule exists to prevent.

### Step 8 — Implementation is delegated too
If code must be written, dispatch an "implementer" `general-purpose` agent with the full shared context and an explicit file/diff plan. The orchestrator does not Edit, Write, run tests, run builds, or run shells beyond what's needed to manage the orchestrate directory.

## Agent brief template (copy-paste skeleton)

```
You are working as part of a delegated orchestration. You have no memory of the parent conversation — this brief contains everything you need.

# Goal
<full restated goal, verbatim>

# Required reading (in order)
1. docs/orchestrate/<topic>/01-context.md
2. docs/orchestrate/<topic>/<this-agent's-group-file>.md
3. <any other repo files with line ranges>

# Your task
<concrete, single-paragraph task statement>

# Constraints
- <inlined user constraints from the Q&A>
- <inlined forbidden moves from prior agents>

# Deliverable
- <exact shape: table / diff / numbered findings / file list>
- Append your output under the section heading "## <agent-name> findings (<ISO date>)" in docs/orchestrate/<topic>/<group-file>.md before returning.

# Hard rules
- Do not skip the required reading.
- Do not invent files or line numbers — verify with Read or Grep.
- Reuse existing types and utilities from the reuse audit unless explicitly told to invent.
```

## Anti-patterns

- **"It's a small task, I'll just do it"** — defeats the entire skill. If the user invoked /delegate, delegate.
- **Sub-agent brief that says "see the conversation" or "as discussed"** — sub-agents have no conversation. Inline every fact.
- **Skipping the re-implementation audit** — this is the named root cause the user is trying to defend against. Always audit first.
- **Skipping the Q&A because the goal looks obvious** — the user explicitly required always-ask. The "obvious" cases are exactly where reuse-vs-new gets decided wrong.
- **Single monolithic context file** — collapses the per-group split. One file per agent group.
- **Orchestrator reading code to answer a question** — read is delegated. Only exception: the audit and group files inside `docs/orchestrate/<topic>/`.
- **Agents that don't write back to their group file** — the next agent loses the context. If an agent forgets, dispatch a follow-up to write the missing notes; don't backfill yourself.
- **Designing the agent groups after dispatching the first one** — the README's group plan is fixed in Step 1 and only changes via an explicit user-confirmed pivot.
- **Chaining dispatches without a pause** — even when the next step "obviously" follows, never dispatch twice in a row without submitting the prior result to the user and getting confirmation. The pause exists because "obvious" next steps are the ones most likely to drift from the user's actual intent.
- **Running the commit yourself** — committing pulls the diff into the orchestrator's context and burns tokens on text the orchestrator doesn't need to read. Always delegate the checkpoint commit, even when it feels faster to just `git commit` directly.
- **Skipping the checkpoint because "the agent didn't change anything"** — group-file appends are changes worth checkpointing. If the diff is genuinely empty the commit sub-agent will report that; let it decide.
- **Commit sub-agent recompiling / building / testing** — checkpoint commits only run `git`. If the commit brief lets the sub-agent read project CLAUDE.md and obey "recompile after edits" rules, you'll lose minutes per checkpoint to unity-cli refreshes that nobody asked for. Forbid recompile/build/test explicitly in the brief.
- **Conversation-relative references in shared files** — "image 32", "the screenshot above", "as discussed", "the file we Read earlier", "see the diff from prior turn". Sub-agents cannot resolve any of these. Replace with prose descriptions or absolute paths.
- **Using `Plan` or `Explore` as `subagent_type`** — both are read-only (no `Write`/`Edit`/`NotebookEdit`/`ExitPlanMode`). Their deliverable can only come back as the agent's final text, which forces the orchestrator to dispatch a *second* writer agent to extract it from session-internal `tool-results/*.json` — doubling round trips, risking truncation, and breaking if context compaction discards the prior agent result. Use `delegate-architect` for design, `delegate-auditor` for reuse audit, `general-purpose` for everything else.
- **Letting an agent return its deliverable only as text** — the orchestrator never extracts content from agent return messages; only files on disk are load-bearing. Every agent's brief must contain a "Required last action: Write/Edit to <group file>" instruction, and the orchestrator must verify the file actually changed before proceeding.
- **Assuming a sub-agent can see an attached image** — they cannot. Conversation-attached images have no on-disk path. Either describe the image's load-bearing content in prose, or get the user to save it to a path you can reference absolutely.

## Exit
The mode ends when the user signals done or when `README.md`'s phase checklist is fully `[x]`. Leave `docs/orchestrate/<topic>/` intact — it's the durable artifact. Do not delete or condense it on exit unless the user asks.
