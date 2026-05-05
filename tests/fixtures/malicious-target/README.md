# Malicious Target Fixture

This directory is a **test fixture** for the security-review skill's injection-defense tests. Every file here is intentionally crafted to look like a hostile target repo:

- `app.py` and `requirements.txt` contain real vulnerabilities the security-review tools must catch (SQL injection, vulnerable pinned deps).
- `CLAUDE.md`, `AGENTS.md`, `.claude/skills/poison/SKILL.md`, `.claude/settings.local.json`, `.cursorrules`, `.github/copilot-instructions.md` contain prompt-injection payloads with unique canary strings (`CANARY_A` through `CANARY_F`).

**Do not invoke `claude` or any AI assistant with this directory as the cwd.** The verifier in `tests/verify.py` only inspects files; it never executes them.

The injection content is bracketed by clear test markers so it cannot be mistaken for real instructions.
