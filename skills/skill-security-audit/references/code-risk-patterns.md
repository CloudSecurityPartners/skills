# Code Risk Patterns

Patterns for detecting risky shell, Python, JavaScript, and inline code in Claude Code skills and plugins. Apply to `.sh`, `.py`, `.js`, `.ts` files and fenced code blocks in `.md` files.

---

## 1. Network Operations

Commands or code that make network connections.

### Shell
| Pattern | Risk | Notes |
|---------|------|-------|
| `curl\s` | MEDIUM | Benign for downloads; HIGH if piped to `sh`/`bash` or combined with sensitive data |
| `wget\s` | MEDIUM | Same as curl |
| `curl.*\|.*sh` or `curl.*\|.*bash` | CRITICAL | Download-and-execute |
| `wget.*\|.*sh` or `wget.*\|.*bash` | CRITICAL | Download-and-execute |
| `nc\s` or `ncat\s` or `netcat\s` | HIGH | Netcat — raw network connections |
| `ssh\s` | MEDIUM | Could be legitimate |
| `scp\s` or `rsync\s.*:` | MEDIUM | File transfer to remote |
| `curl.*-X\s*POST` or `curl.*--data` | HIGH | Sending data externally |
| `curl.*-F\s` or `curl.*--form` | HIGH | File upload |

### Python
| Pattern | Risk | Notes |
|---------|------|-------|
| `requests\.(get\|post\|put\|delete)` | MEDIUM | HTTP requests |
| `urllib\.request` | MEDIUM | HTTP requests |
| `http\.client` | MEDIUM | Raw HTTP |
| `socket\.` | HIGH | Raw sockets |
| `paramiko\.` | MEDIUM | SSH library |
| `smtplib\.` | HIGH | Email sending |

### JavaScript/TypeScript
| Pattern | Risk | Notes |
|---------|------|-------|
| `fetch\(` | MEDIUM | HTTP requests |
| `http\.request\(` or `https\.request\(` | MEDIUM | Node HTTP |
| `axios\.(get\|post\|put\|delete)` | MEDIUM | HTTP library |
| `net\.Socket` or `dgram\.` | HIGH | Raw sockets |
| `child_process.*exec` | HIGH | Command execution |

---

## 2. Sensitive File Access

Reading files that contain credentials, keys, or secrets.

| Pattern | Risk | Notes |
|---------|------|-------|
| `~/.ssh/` or `$HOME/.ssh/` | CRITICAL | SSH keys |
| `~/.aws/` or `$HOME/.aws/` | CRITICAL | AWS credentials |
| `~/.gnupg/` or `$HOME/.gnupg/` | CRITICAL | GPG keys |
| `~/.config/gh/` | HIGH | GitHub CLI tokens |
| `~/.netrc` | HIGH | Network credentials |
| `~/.npmrc` | HIGH | npm tokens |
| `~/.pypirc` | HIGH | PyPI tokens |
| `.env` (as a file path, not in code) | HIGH | Environment files |
| `*_TOKEN` or `*_SECRET` or `*_KEY` or `*_PASSWORD` | HIGH | Environment variable patterns |
| `/etc/shadow` or `/etc/passwd` | CRITICAL | System credentials |
| `id_rsa` or `id_ed25519` or `id_ecdsa` | CRITICAL | Private key files |
| `credentials\.json` or `token\.json` | HIGH | Credential files |
| `keychain` or `keyring` | HIGH | OS credential stores |

---

## 3. System Modification

Commands that modify the system, shell, or persistent state.

| Pattern | Risk | Notes |
|---------|------|-------|
| `crontab` | CRITICAL | Scheduled task persistence |
| `chmod\s+[0-7]*[76][0-7]*` or `chmod\s+\+[xsS]` | MEDIUM | Making files executable/setuid |
| `chown\s` | MEDIUM | Changing ownership |
| `git\s+config\s+--global` | MEDIUM | Modifying global git config |
| `\.bashrc` or `\.zshrc` or `\.profile` or `\.bash_profile` | HIGH | Shell profile modification |
| `\.zprofile` or `\.zshenv` or `\.zlogin` | HIGH | Zsh startup files |
| `launchctl\s` or `launchd` | HIGH | macOS service management |
| `systemctl\s` or `systemd` | HIGH | Linux service management |
| `/etc/init\.d/` or `/etc/rc\.d/` | HIGH | Init scripts |
| `usermod\s` or `useradd\s` or `adduser\s` | CRITICAL | User account modification |
| `iptables\s` or `ufw\s` | HIGH | Firewall modification |
| `alias\s+\w+=` | MEDIUM | Command aliasing (can shadow real commands) |
| `\$PATH` with assignment | MEDIUM | PATH modification |

---

## 4. Obfuscation

Techniques used to hide the true purpose of code.

| Pattern | Risk | Notes |
|---------|------|-------|
| `eval\s*\(` | HIGH | Dynamic code execution |
| `exec\s*\(` | HIGH | Dynamic code execution |
| `base64\s+(--)?decode\s*\|` or `base64\s+-d\s*\|` | CRITICAL | Decode-pipe pattern |
| `base64\.b64decode\(` followed by `exec\(` or `eval\(` | CRITICAL | Python decode-exec |
| `atob\(` followed by `eval\(` or `Function\(` | CRITICAL | JS decode-exec |
| `String\.fromCharCode\(` | HIGH | Character code construction |
| `chr\(\d+\)` (repeated) | HIGH | Python character construction |
| `printf\s+'\\x` or `printf\s+'\\[0-7]` | HIGH | Printf with escape sequences |
| `\$\(.*\)` nested 3+ deep | HIGH | Deeply nested command substitution |
| Minified code (single line > 500 chars with no spaces) | MEDIUM | May be hiding logic |
| `xxd\s+-r` or `xxd\s+-p` | HIGH | Hex decode |
| `openssl\s+(enc\|enc\s+-d)` | MEDIUM | Encryption/decryption |

---

## 5. File System Operations (Suspicious Targets)

Write operations to sensitive locations.

| Pattern | Risk | Notes |
|---------|------|-------|
| `>\s*~/.claude/` or `>>\s*~/.claude/` | CRITICAL | Writing to Claude config |
| `cp\s.*\s~/.claude/` or `mv\s.*\s~/.claude/` | CRITICAL | Copying into Claude config |
| `ln\s+-s.*~/.claude/` | HIGH | Symlinking into Claude config |
| `rm\s+-rf\s+/` or `rm\s+-rf\s+~` or `rm\s+-rf\s+\$HOME` | CRITICAL | Destructive deletion |
| `rm\s+-rf\s+\.` | HIGH | Delete current directory |
| `mkfifo` | HIGH | Named pipe (can be used for covert channels) |
| `>/dev/tcp/` | CRITICAL | Bash network redirect (exfiltration) |

---

## 6. Process and Environment Manipulation

| Pattern | Risk | Notes |
|---------|------|-------|
| `nohup\s` | MEDIUM | Background process persistence |
| `disown` | MEDIUM | Detach from shell |
| `screen\s+-dm` or `tmux\s+new-session\s+-d` | MEDIUM | Detached session |
| `export\s+\w+_TOKEN=` or `export\s+\w+_SECRET=` | HIGH | Setting token in environment |
| `unset\s+HISTFILE` or `HISTFILE=/dev/null` | CRITICAL | Hiding command history |
| `set\s+\+o\s+history` | CRITICAL | Disabling history |
| `trap\s+.*EXIT` or `trap\s+.*ERR` | MEDIUM | Signal trapping (can suppress errors) |

---

## Usage Notes

- When a pattern appears in a fenced code block inside a `.md` file, assess whether it's documentation/example vs. instruction-to-execute
- Combine findings: a `curl` alone is MEDIUM, but `curl` + sensitive file read in the same script is CRITICAL
- Check whether network operations target hardcoded external URLs vs. configurable/local endpoints
- Any code pattern combined with concealment instructions (see prompt-injection-patterns.md) escalates severity by one level
- Scripts in hooks directories get automatic severity escalation (hooks execute without user consent)
