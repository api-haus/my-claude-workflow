---
name: review-plan
description: Audit plan file for completeness before exiting plan mode — context is wiped on transition to work
---

Read the plan file. A fresh agent with zero conversation history must be able to execute it.

Verify presence of:
- **Context**: why, what prompted it
- **File paths**: every file to touch
- **Reuse targets** (if applicable): existing functions/patterns to use (file:name)
- **Steps**: ordered, concrete, no ambiguity
- **Done when**: acceptance criteria + how to verify (commands, expected outcomes)

Flag gaps to the user. No fluff — only missing substance. Never remove user intent.
