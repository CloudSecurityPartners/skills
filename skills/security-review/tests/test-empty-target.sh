#!/usr/bin/env bash
# Validates the quarantine logic on a target with NO AI-tooling files.
# The pointer manifest must be written gracefully so downstream agents know
# to expect "no files quarantined".
set -euo pipefail

PASS=0
FAIL=0
fail() { echo "  FAIL: $*"; FAIL=$((FAIL + 1)); }
pass() { echo "  PASS: $*"; PASS=$((PASS + 1)); }

WORKDIR=$(mktemp -d)
PROJECT_ROOT="$WORKDIR/clean"
QUARANTINE="$PROJECT_ROOT.ai-tooling-quarantine"
trap 'rm -rf "$WORKDIR" "$QUARANTINE" 2>/dev/null || true' EXIT

mkdir -p "$PROJECT_ROOT/src"
echo "print('hello')" > "$PROJECT_ROOT/src/main.py"
mkdir -p "$PROJECT_ROOT/security-review/raw"

mkdir -p "$QUARANTINE"
: > "$QUARANTINE/manifest.txt"

for p in CLAUDE.md AGENTS.md .claude .cursor .github/copilot-instructions.md .mcp.json .aider.conf.yml .aider.model.settings.yml .continue; do
  src="$PROJECT_ROOT/$p"
  [ -e "$src" ] || continue
  dst="$QUARANTINE/$p"
  mkdir -p "$(dirname "$dst")"
  mv "$src" "$dst"
  echo "$p" >> "$QUARANTINE/manifest.txt"
done

{
  echo "# AI-Tooling Quarantine"
  echo
  echo "**Quarantine location:** \`$QUARANTINE\`"
  echo
  echo "**Files moved (paths relative to PROJECT_ROOT):**"
  if [ -s "$QUARANTINE/manifest.txt" ]; then
    sed 's|^|- `|; s|$|`|' "$QUARANTINE/manifest.txt"
  else
    echo "- (none — no AI-tooling files found in target)"
  fi
} > "$PROJECT_ROOT/security-review/quarantine-manifest.md"

[ -f "$PROJECT_ROOT/security-review/quarantine-manifest.md" ] && pass "pointer manifest written even with empty target" || fail "pointer manifest missing"
grep -qF "no AI-tooling files found" "$PROJECT_ROOT/security-review/quarantine-manifest.md" && pass "pointer notes empty case" || fail "pointer doesn't note empty case"
[ ! -s "$QUARANTINE/manifest.txt" ] && pass "manifest.txt empty as expected" || fail "manifest.txt has content (none expected)"
[ -e "$PROJECT_ROOT/src/main.py" ] && pass "source file untouched" || fail "source file was moved"

echo
echo "Total: $PASS passed, $FAIL failed"
exit $FAIL
