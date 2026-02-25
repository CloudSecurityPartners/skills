# OpenSSF Scorecard Policy

How to query and interpret [OpenSSF Security Scorecards](https://securityscorecards.dev/) for GitHub repositories during Phase 0 of the audit.

---

## API

```
GET https://api.securityscorecards.dev/projects/github.com/{owner}/{repo}
```

Returns JSON with:
- `score` — overall score (0–10)
- `repo.name` — canonical repo path
- `repo.commit` — commit SHA that was scored
- `date` — when the scorecard was generated
- `checks[]` — array of individual check results

Each check has:
- `name` — check identifier
- `score` — 0–10 (or -1 for error/not-applicable)
- `reason` — human-readable explanation
- `details` — array of specific findings (may be null)
- `documentation.short` — brief description
- `documentation.url` — link to full docs

### Querying via Bash

```bash
curl -s "https://api.securityscorecards.dev/projects/github.com/${OWNER}/${REPO}"
```

A **404** means the repository has no scorecard (not yet scanned by the OpenSSF infrastructure). This is common for small or new repositories and is itself informative — it means the repo hasn't been analyzed for supply chain security practices.

---

## Risk Mapping

### Overall Score

| Score Range | Risk Assessment | Interpretation |
|-------------|----------------|----------------|
| 7.0–10.0 | LOW | Strong security practices — repo demonstrates mature supply chain hygiene |
| 4.0–6.9 | MEDIUM | Mixed practices — some security measures in place but gaps exist |
| 0.0–3.9 | HIGH | Weak security practices — significant supply chain risks |
| No scorecard (404) | INFO | Unscored — no external validation of repo security practices |

### Security-Critical Checks

These checks are most relevant when evaluating a Claude Code skill/plugin repository. Flag failures in these as findings.

| Check | Why It Matters for Skills | Score Threshold |
|-------|--------------------------|-----------------|
| **Code-Review** | Unreviewed code can contain injected malicious content | < 5 = HIGH |
| **Maintained** | Unmaintained repos won't receive security fixes | < 5 = MEDIUM |
| **Vulnerabilities** | Known vulns in dependencies could affect scripts | < 5 = HIGH |
| **Branch-Protection** | Unprotected branches allow force-push of malicious commits | < 5 = MEDIUM |
| **Token-Permissions** | Overly broad CI tokens could be exploited | < 5 = MEDIUM |
| **Dangerous-Workflow** | CI that runs untrusted code (e.g., pull_request_target) | < 5 = HIGH |
| **SAST** | No static analysis means no automated vulnerability detection | < 5 = LOW |
| **Pinned-Dependencies** | Unpinned deps are vulnerable to dependency confusion | < 5 = MEDIUM |
| **Binary-Artifacts** | Binary blobs can hide malicious executables | < 5 = HIGH |
| **Signed-Releases** | Unsigned releases are easier to tamper with | < 5 = LOW |

### Checks to Note but Not Flag

These checks are informative but rarely warrant a finding for a skill/plugin repo:

| Check | Notes |
|-------|-------|
| **CII-Best-Practices** | Nice to have, not expected for small skill repos |
| **Packaging** | Not relevant unless the skill publishes packages |
| **Fuzzing** | Not expected for markdown/config-only repos |
| **License** | Licensing issues are not security issues |
| **Contributors** | Small contributor count is normal for skills |

---

## Integration Into Findings

### When scorecard is available:

Generate findings for failed security-critical checks:

- **Score < 5 on Code-Review:** `MEDIUM` finding — "Repository does not require code review for all changes. Malicious modifications could be merged without oversight."
- **Score < 5 on Vulnerabilities:** `MEDIUM` finding — "Repository has known vulnerabilities in dependencies."
- **Score < 5 on Dangerous-Workflow:** `HIGH` finding — "Repository CI configuration runs untrusted code, creating a supply chain risk."
- **Score < 5 on Binary-Artifacts:** `HIGH` finding — "Repository contains binary artifacts that cannot be audited for malicious content."
- **Score < 5 on Maintained:** `MEDIUM` finding — "Repository appears unmaintained. Security issues will not be patched."

### When no scorecard exists (404):

Generate an `INFO` finding:
> "No OpenSSF Security Scorecard available for this repository. The repository has not been evaluated for supply chain security practices. This is common for small or new repositories but means there is no external validation of the maintainer's security practices."

### When the API errors (non-404):

Note the error but do not generate a finding — API availability should not block the audit.

---

## Report Section

Include the scorecard data in the report between the Executive Summary and Permission Summary:

```markdown
## Repository Scorecard

**Source:** [OpenSSF Security Scorecards](https://securityscorecards.dev/)
**Score:** [n]/10 — [LOW/MEDIUM/HIGH risk]
**Scanned:** [date] (commit: [short SHA])

| Check | Score | Status |
|-------|-------|--------|
| [check name] | [score]/10 | [reason summary] |
| ... | ... | ... |

[Or: "No scorecard available for this repository."]
```
