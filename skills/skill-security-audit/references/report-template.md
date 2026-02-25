# Audit Report Template

Use this template to produce the final structured report after completing all six audit phases.

---

## Report Format

```markdown
# Security Audit Report

**Target:** [skill/plugin name]
**Path:** [local path or repository URL]
**Date:** [YYYY-MM-DD]
**Auditor:** Claude Code (skill-security-audit)

---

## Executive Summary

| Severity | Count |
|----------|-------|
| CRITICAL | [n] |
| HIGH     | [n] |
| MEDIUM   | [n] |
| LOW      | [n] |
| INFO     | [n] |

**Verdict:** [SAFE / CAUTION / DO NOT INSTALL]

[1-3 sentence summary of overall risk posture]

---

## Repository Scorecard

**Source:** [OpenSSF Security Scorecards](https://securityscorecards.dev/)
**Score:** [n]/10 — [LOW/MEDIUM/HIGH risk]
**Scanned:** [date] (commit: [short SHA])

| Check | Score | Status |
|-------|-------|--------|
| [check name] | [score]/10 | [reason summary] |
| ... | ... | ... |

[If no scorecard available: "No OpenSSF Security Scorecard available for this repository. The repository has not been evaluated for supply chain security practices."]

[If target is a local path with no GitHub remote: "Scorecard not available — target is a local path with no GitHub remote."]

---

## Permission Summary

| File | allowed-tools | Risk Level |
|------|---------------|------------|
| [SKILL.md path] | [tool list] | [LOW/MEDIUM/HIGH/CRITICAL] |
| ... | ... | ... |

---

## Findings

### [FINDING-001] [Title]

- **Severity:** [CRITICAL / HIGH / MEDIUM / LOW / INFO]
- **Confidence:** [HIGH / MEDIUM / LOW]
- **Category:** [PI/CE/DE/SC/BD/PE — from threat catalog]
- **Phase:** [1-6 — which audit phase detected this]
- **File:** [file path]
- **Line:** [line number or range, if applicable]
- **Evidence:**
  ```
  [exact text or code that triggered the finding]
  ```
- **Risk:** [what could happen if this is exploited]
- **Recommendation:** [specific remediation advice]

---

[Repeat for each finding, numbered sequentially: FINDING-001, FINDING-002, etc.]

---

## File Inventory

| File | Type | Size | Risk Notes |
|------|------|------|------------|
| [path] | [SKILL.md / command / hook / script / config / other] | [size] | [brief note or "Clean"] |
| ... | ... | ... | ... |

---

## Verdict Explanation

[Detailed justification for the SAFE / CAUTION / DO NOT INSTALL verdict]

### Verdict Criteria

- **SAFE:** No CRITICAL or HIGH findings. Any MEDIUM findings are well-understood and acceptable for the skill's purpose. No prompt injection detected. Permissions are appropriate.

- **CAUTION:** One or more HIGH findings, OR multiple MEDIUM findings that together pose elevated risk. The skill may be usable but requires careful review of flagged items. User should understand and accept the specific risks.

- **DO NOT INSTALL:** Any CRITICAL finding, OR HIGH findings involving prompt injection or data exfiltration, OR evidence of deliberate obfuscation or anti-audit countermeasures. The skill poses unacceptable risk.
```

---

## Formatting Rules

1. **Number findings sequentially** starting from FINDING-001
2. **Order findings by severity** (CRITICAL first, then HIGH, MEDIUM, LOW, INFO)
3. **Include exact evidence** — copy the relevant text/code, don't just describe it
4. **Be specific about file and line** — the user should be able to find the exact location
5. **Distinguish instruction from documentation** — if a pattern appears in an example/illustration, note reduced confidence
6. **Aggregate related findings** — if the same pattern appears in multiple files, group them into one finding with multiple locations rather than separate findings
7. **Always include the file inventory** — even files with no findings should be listed as "Clean"
8. **Verdict must be justified** — explicitly reference which findings drove the verdict decision
