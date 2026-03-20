---
description: "Conduct a security review of a codebase using an agent team with deterministic tools and expert analysis"
---

# Security Review Request

You have been asked to conduct a security review of a codebase.

## Target

```
$ARGUMENTS
```

## Instructions

1. **Parse the target** from the arguments above:
   - If it looks like a **local path** (starts with `/`, `~`, or `.`): use that as the project root.
   - If no argument was provided: use the current working directory as the project root.

2. **Invoke the `security-review` skill** and follow its orchestration steps exactly.

3. **Produce the final report** at `security-review/report-final.md` in the project root.
