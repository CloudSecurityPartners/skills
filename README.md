# skill-security

Security toolkit for Claude Code — audit skills/plugins for prompt injection and backdoors, or conduct full codebase security reviews with an agent team.

## Skills

### Skill Security Audit (`/skill-audit`)

Performs a six-phase security audit of any Claude Code skill or plugin:

1. **Target Acquisition** — clone repo or verify local path, build file manifest, query OpenSSF Security Scorecard
2. **Permissions Analysis** — assess `allowed-tools` against purpose, flag dangerous combinations
3. **Prompt Injection Analysis** — detect override attempts, concealment, authority manipulation, encoded content
4. **Code Execution Analysis** — scan scripts and inline code for network ops, sensitive file access, obfuscation
5. **Hook Analysis** — highest priority — hooks execute without user consent
6. **Behavioral Simulation** — reason about what the skill actually does when loaded

Produces a structured report with findings by severity and a verdict: **SAFE**, **CAUTION**, or **DO NOT INSTALL**.

### Security Review (`/security-review`)

Conducts a full codebase security review using an agent team:

1. **Project Analysis** — architecture briefing for the review team
2. **Tool Scanning** — semgrep, trufflehog, and trivy (deterministic tools)
3. **Expert Triage** — four parallel agents: SAST triage, dependency triage, targeted expert, broad expert
4. **Report Writing** — consolidated draft with deduplicated, severity-rated findings
5. **Round Table** — consensus-driven debate where agents challenge each other's findings

Produces a final report at `security-review/report-final.md` with confirmed findings, severity ratings, and an appendix of uncertain items.

**Prerequisites:** semgrep, trufflehog, and trivy must be installed on the host machine.

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
ln -s "$(pwd)/skills/skills/security-review" ~/.claude/skills/security-review
```

## Usage

```
/skill-audit https://github.com/someone/their-skill
/skill-audit /path/to/local/skill

/security-review
/security-review /path/to/project
```

## Threat categories (skill audit)

| ID | Category | Examples |
|----|----------|----------|
| PI | Prompt Injection | Override instructions, concealment, authority manipulation |
| CE | Code Execution | Shell commands, eval/exec, decode-then-execute chains |
| DE | Data Exfiltration | curl/wget to external URLs, DNS exfil, env harvesting |
| SC | Supply Chain | Modifying other plugins, settings, CLAUDE.md, weak repo scorecard |
| BD | Backdoor | Obfuscated payloads, base64, zero-width characters |
| PE | Permission Escalation | Overly broad allowed-tools, dangerous tool combos |
