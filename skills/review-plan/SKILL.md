---
name: review-plan
description: Audit plan file for completeness before exiting plan mode — context is wiped on transition to work
---

Read the plan file. A fresh agent with zero conversation history must be able to execute it.

Verify presence of:
- **Context**: why, what prompted it
- **Acceptance criteria**: what "done" looks like
- **File paths**: absolute paths for every file to touch
- **Reuse targets**: existing functions/patterns to use (file:line)
- **Steps**: ordered, concrete, no ambiguity
- **Verification**: commands to run, expected outcomes

Fill gaps directly in the plan file. No fluff — only missing substance. Never remove user intent.
