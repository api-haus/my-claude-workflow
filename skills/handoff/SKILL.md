---
name: handoff
description: Write a handoff prompt for a future session. Use when the user asks to write a handoff, prepare a handoff, or document context for a next agent to pick up the investigation.
---

Write a handoff prompt as a markdown file under `/tmp`. The file must be usable by a fresh agent that has no memory of this conversation.

## Hard rules

- **Self-contained.** No dangling references. Do NOT cite tags, hypothesis labels (H1/H2/…), code names, or prior document titles without inlining their meaning. If a fact came from an earlier handoff, copy the fact — not the reference. Assume the next agent will not read any other file you name unless you explicitly tell them to.

- **Pick one mode, not both.**
  1. **Diagnosed.** State a single root cause per distinct symptom, with file + line references, and the fix to apply. No alternatives. No ranked hypothesis list.
  2. **Investigate.** Point at concrete code ranges that must be read end-to-end, and the specific questions to answer after reading. No "probably" or "maybe" commentary in this mode either — the agent decides after reading.

  Never produce a handoff that mixes both ("here's what I think AND here's what to check"). That is the circular-hypothesis pattern that wastes sessions.

- **No ranked-hypothesis dumps.** A numbered list of 3–5 "maybe" causes is the failure mode this skill exists to prevent. If you feel like writing one, you have not read enough code — read more, then pick one of the two modes above.

- **Forbid inherited bad patterns.** If prior sessions went in circles, say so explicitly and list the already-tried-and-disproven directions under "do not revisit" with one-line inlined summaries (not tag refs).

- **Code refs, not paraphrases.** For every load-bearing claim about what code does, quote the file path and line number the next agent must Read directly. Do not paraphrase — paraphrased summaries silently drop early-outs, guards, and branches that change the diagnosis.

- **Deliverable shape.** Close with an explicit "Deliverable" section describing what the next session's reply must contain (walkthrough / diagnosis / fix / verification). This prevents the next agent from defaulting to "here are some more hypotheses".

## Structure

```
# Handoff: <short topic>

## Why this handoff exists
<one short paragraph: what went wrong in prior sessions, if anything; why this document exists>

## Symptom(s)
<concrete user-visible behaviour, with repro steps and image paths if relevant>

## Mode: <Diagnosed | Investigate>

### If Diagnosed
- Root cause (one sentence, code-grounded)
- Fix (file + line + new code)

### If Investigate
- Required reading (file paths + line ranges)
- Questions to answer after reading (numbered, code-grounded)

## Already-tried and do-not-revisit
<bulleted list; each item is a one-line inlined summary, not a tag reference>

## Forbidden moves
<explicit rules for the next agent — e.g. "no ranked-hypothesis lists", "verify load-bearing claims with direct Read before quoting them">

## Deliverable
<exact shape the next session's reply must take>

## Repro / env
<minimal steps + asset/config versions>
```

## Filename

`/tmp/<short-kebab-topic>-handoff.md`. If a previous handoff exists at a similar name, add `-v2`, `-v3`, etc. — never overwrite, the prior file is evidence of what didn't work.
