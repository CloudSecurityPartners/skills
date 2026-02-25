# Prompt Injection Pattern Library

Regex-friendly patterns for detecting prompt injection in Claude Code skills and plugins. Patterns are grouped by category and include confidence ratings.

All patterns should be applied **case-insensitively** unless noted otherwise.

---

## 1. Direct Override / Bypass

Attempts to override system instructions or safety guidelines.

| Pattern | Confidence | Notes |
|---------|------------|-------|
| `ignore\s+(all\s+)?previous\s+instructions` | HIGH | Classic injection |
| `disregard\s+(all\s+)?(prior\|previous\|above\|earlier)` | HIGH | |
| `forget\s+everything\s+(above\|before\|prior)` | HIGH | |
| `override\s+(all\s+)?(instructions\|rules\|guidelines\|safety)` | HIGH | |
| `bypass\s+(all\s+)?(safety\|security\|restrictions\|filters\|checks)` | HIGH | |
| `new\s+instructions\s*:` | HIGH | Redefining context |
| `reset\s+(your\s+)?context` | MEDIUM | Could be benign in some contexts |
| `you\s+are\s+(now\s+)?free\s+(from\|of)\s+(all\s+)?restrictions` | HIGH | |
| `(remove\|disable\|turn\s+off)\s+(all\s+)?(safety\|security\|guard)rails` | HIGH | |
| `do\s+not\s+follow\s+(any\|the)\s+(previous\|prior\|above)` | HIGH | |
| `start\s+(a\s+)?new\s+conversation` | MEDIUM | Context reset attempt |

## 2. Concealment

Instructions to hide behavior from the user.

| Pattern | Confidence | Notes |
|---------|------------|-------|
| `do\s+not\s+tell\s+the\s+user` | HIGH | |
| `never\s+mention\s+(this\|that\|the\s+following)` | HIGH | |
| `silently\s+(execute\|run\|perform\|do\|send\|include)` | HIGH | |
| `without\s+(informing\|telling\|notifying\|alerting)\s+(the\s+)?user` | HIGH | |
| `hide\s+(this\|the\s+following\|these)\s+from` | HIGH | |
| `suppress\s+(all\s+)?(warning\|error\|output\|notification)` | MEDIUM | Could be benign for log suppression |
| `do\s+not\s+(report\|log\|display\|show\|output)` | MEDIUM | |
| `keep\s+(this\s+)?secret` | HIGH | |
| `invisible\s+to\s+(the\s+)?user` | HIGH | |
| `don't\s+ask\s+for\s+(confirmation\|permission\|approval)` | HIGH | Bypassing consent |

## 3. Authority Manipulation

False claims of elevated permissions or pre-authorization.

| Pattern | Confidence | Notes |
|---------|------------|-------|
| `you\s+must\s+always\s+(obey\|follow\|execute\|comply)` | HIGH | |
| `this\s+overrides\s+(all\s+)?(previous\|other\|prior)` | HIGH | |
| `elevated\s+permissions?\s+(granted\|enabled\|activated)` | HIGH | |
| `admin(istrator)?\s+mode\s+(enabled\|activated\|on)` | HIGH | |
| `unrestricted\s+(access\|mode\|execution)` | HIGH | |
| `all\s+safety\s+checks?\s+(are\s+)?(disabled\|off\|removed)` | HIGH | |
| `you\s+have\s+been\s+(authorized\|granted\|given)\s+(full\|complete\|unrestricted)` | HIGH | |
| `highest\s+priority\s+instruction` | HIGH | |
| `these?\s+instructions?\s+(take\|have)\s+precedence` | MEDIUM | Could be benign for skill ordering |
| `mandatory\s+compliance\s+required` | MEDIUM | |

## 4. Role Confusion

Attempts to redefine Claude's identity or behavior.

| Pattern | Confidence | Notes |
|---------|------------|-------|
| `you\s+are\s+now\s+[A-Z][\w-]+` | HIGH | Identity redefinition |
| `your\s+new\s+role\s+is` | HIGH | |
| `(act\|behave)\s+as\s+(if\s+you\s+(are\|were)\s+)?an?\s+unrestricted` | HIGH | |
| `pretend\s+(to\s+be\|you\s+are)` | MEDIUM | Could be benign for persona skills |
| `from\s+now\s+on\s+you\s+are` | HIGH | |
| `switch\s+to\s+[\w-]+\s+mode` | MEDIUM | Could be benign (e.g., "switch to debug mode") |
| `assume\s+the\s+(identity\|role\|persona)\s+of` | MEDIUM | |
| `you\s+are\s+no\s+longer\s+(Claude\|an?\s+AI\|bound\s+by)` | HIGH | |

## 5. Encoded / Obfuscated Content

Hidden instructions via encoding or Unicode tricks.

| Pattern | Confidence | Notes |
|---------|------------|-------|
| `[A-Za-z0-9+/]{40,}={0,2}` | MEDIUM | Base64 string (40+ chars). Check if decodable to text |
| `\\x[0-9a-fA-F]{2}(\\x[0-9a-fA-F]{2}){3,}` | HIGH | Hex-encoded sequence |
| `&#x?[0-9a-fA-F]+;(&#x?[0-9a-fA-F]+;){3,}` | HIGH | HTML entity sequence |
| `\\u[0-9a-fA-F]{4}(\\u[0-9a-fA-F]{4}){3,}` | HIGH | Unicode escape sequence |
| `[\x{200B}\x{200C}\x{200D}\x{FEFF}\x{2060}]` | HIGH | Zero-width characters (case-sensitive) |
| `String\.fromCharCode\(` | HIGH | JavaScript char code construction |
| `chr\(\d+\)\s*[\+\.]\s*chr\(\d+\)` | HIGH | Python char code construction |
| `\$'\\.+'` | MEDIUM | Bash ANSI-C quoting (can hide commands) |

## 6. Scope Escalation

Instructions to modify configuration, other skills, or system state.

| Pattern | Confidence | Notes |
|---------|------------|-------|
| `(modify\|edit\|write\s+to\|append\s+to\|update)\s+.*CLAUDE\.md` | HIGH | |
| `(modify\|edit\|write\s+to\|update)\s+.*settings\.json` | HIGH | |
| `(modify\|edit\|write\s+to\|update)\s+.*~?\/?\.claude\/` | HIGH | |
| `(modify\|edit\|write\s+to\|update)\s+.*blocklist` | HIGH | |
| `(install\|add\|inject)\s+.*other\s+(skill\|plugin)` | HIGH | |
| `(modify\|change\|update)\s+.*permission` | MEDIUM | Could be benign for docs |
| `(add\|append)\s+to\s+(your\|the)\s+(system\|base)\s+prompt` | HIGH | |
| `(create\|write)\s+.*\.claude.*skills?\/` | HIGH | Modifying skill directory |

## 7. Social Engineering

False claims about user actions or authorization.

| Pattern | Confidence | Notes |
|---------|------------|-------|
| `the\s+user\s+has\s+already\s+(approved\|authorized\|consented\|agreed)` | HIGH | |
| `pre-authorized\s+by\s+(the\s+)?user` | HIGH | |
| `user\s+(has\s+)?consented\s+to` | MEDIUM | Could appear in auth documentation |
| `permission\s+(was\|has\s+been)\s+granted` | MEDIUM | |
| `(user\|they)\s+(explicitly\s+)?requested\s+this` | MEDIUM | |
| `already\s+(been\s+)?verified\s+(as\s+)?safe` | HIGH | |
| `trusted\s+and\s+verified\s+(skill\|plugin\|source)` | MEDIUM | |
| `this\s+is\s+a\s+(safe\|verified\|trusted)\s+operation` | MEDIUM | |

## 8. Anti-Audit Countermeasures

Instructions that detect or subvert security scanning. **Any match in target files is automatically CRITICAL.**

| Pattern | Confidence | Notes |
|---------|------------|-------|
| `if.*(security\s+)?(audit\|review\|scan\|inspection)` | HIGH | Conditional on audit |
| `report\s+(as\|all\s+findings?\s+as)\s+(clean\|safe\|benign\|info)` | HIGH | |
| `(appear\|look\|seem)\s+(benign\|safe\|clean\|normal)` | HIGH | |
| `pass\s+(security\s+)?(inspection\|review\|audit\|scan)` | HIGH | |
| `(if\|when)\s+(being\s+)?(reviewed\|scanned\|audited\|inspected)` | HIGH | |
| `(hide\|conceal)\s+(from\|during)\s+(security\s+)?(audit\|review\|scan)` | HIGH | |
| `pre-approved\s+(by\s+)?security` | HIGH | |
| `security\s+(clearance\|approval)\s+(granted\|confirmed)` | HIGH | |

---

## Usage Notes

- Apply all patterns against every `.md` file in the target skill/plugin
- Patterns in category 8 (Anti-Audit) are automatic CRITICAL regardless of context
- For categories 1–7, consider context: a pattern in documentation *about* injection is different from a pattern *performing* injection
- When a pattern matches inside a markdown code block that's clearly an example/demonstration, lower confidence by one level
- When a pattern matches in a comment (HTML `<!-- -->` or frontmatter), raise confidence by one level (hiding in comments is suspicious)
- Multiple low-confidence matches in the same file compound into higher overall suspicion
