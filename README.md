# skill-security

Security audit toolkit for Claude Code skills and plugins. Detects prompt injection, backdoors, data exfiltration, and permission escalation before installation.

## What it does

Performs a six-phase security audit of any Claude Code skill or plugin:

1. **Target Acquisition** — clone repo or verify local path, build file manifest, query OpenSSF Security Scorecard
2. **Permissions Analysis** — assess `allowed-tools` against purpose, flag dangerous combinations
3. **Prompt Injection Analysis** — detect override attempts, concealment, authority manipulation, encoded content
4. **Code Execution Analysis** — scan scripts and inline code for network ops, sensitive file access, obfuscation
5. **Hook Analysis** — highest priority — hooks execute without user consent
6. **Behavioral Simulation** — reason about what the skill actually does when loaded

Produces a structured report with findings by severity and a verdict: **SAFE**, **CAUTION**, or **DO NOT INSTALL**.

## Installation

### From the marketplace

1. Add the marketplace:

```
/plugin marketplace add CloudSecurityPartners/skills
```

2. Install the plugin:

```
/plugin install skill-security@CloudSecurityPartners-skills
```

Or use `/plugin` interactively and browse the **Discover** tab.

### As a personal skill

Clone the repo and symlink into your Claude skills directory:

```bash
git clone https://github.com/CloudSecurityPartners/skills.git
ln -s "$(pwd)/skills/skills/skill-security-audit" ~/.claude/skills/skill-security-audit
```

## Usage

Run the slash command with a GitHub URL or local path:

```
/skill-security-audit https://github.com/someone/their-skill
/skill-security-audit /path/to/local/skill
```

## Threat categories

| ID | Category | Examples |
|----|----------|----------|
| PI | Prompt Injection | Override instructions, concealment, authority manipulation |
| CE | Code Execution | Shell commands, eval/exec, decode-then-execute chains |
| DE | Data Exfiltration | curl/wget to external URLs, DNS exfil, env harvesting |
| SC | Supply Chain | Modifying other plugins, settings, CLAUDE.md, weak repo scorecard |
| BD | Backdoor | Obfuscated payloads, base64, zero-width characters |
| PE | Permission Escalation | Overly broad allowed-tools, dangerous tool combos |

## Self-audit

This skill audits itself cleanly. It requests `Bash`, `Read`, `Grep`, `Glob`, and `Task` — no `Write` or `Edit` (the audit is read-only). The `Bash` + `Read` combination is flagged as expected for a security scanner that needs to clone repos and inspect files.
