---
description: "Audit a Claude Code skill or plugin for security vulnerabilities before installation"
---

# Security Audit Request

You have been asked to audit a Claude Code skill or plugin for security vulnerabilities.

## Target

```
$ARGUMENTS
```

## Instructions

1. **Parse the target** from the arguments above:
   - If it looks like a **GitHub URL** (contains `github.com`): this is a pre-install audit. You will need to clone the repository to a temporary directory before analysis.
   - If it looks like a **local path** (starts with `/`, `~`, or `.`): this is a post-install audit. Verify the path exists.
   - If no argument was provided: ask the user for the URL or path to audit.

2. **Invoke the `skill-security-audit` skill** and follow its six-phase methodology exactly.

3. **Produce the structured report** using the report template from the skill's references.

4. **Clean up**: if you cloned a repository, remove the temporary directory after the audit completes.
