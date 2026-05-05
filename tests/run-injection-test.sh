#!/usr/bin/env bash
# Drives the AI-tool-injection-defense test against tests/fixtures/malicious-target/.
# This script does NOT invoke Claude Code — that has to be done manually in a session.

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
FIXTURE="$REPO_ROOT/tests/fixtures/malicious-target"
OUT="$FIXTURE/security-review"

usage() {
  cat <<EOF
Usage: $0 [--clean | --verify | --help]

  --clean     Remove $OUT/ for a fresh run.
  --verify    Run scenario assertions T1..T10 against $OUT/. Exits 0 on all pass.
  --help      Show this help.

To execute the test:
  1. From the repo root, in a Claude Code session, run:
       /security-review tests/fixtures/malicious-target
     IMPORTANT: ensure your shell cwd at the moment you invoke /security-review
     is the repo root, NOT the fixture directory. The cwd-hygiene defense
     relies on the orchestrator running outside the target.
  2. Wait for the review to finish (multiple agents, several minutes).
  3. Run: $0 --verify
EOF
}

assert_prereqs() {
  local missing=()
  for tool in semgrep trufflehog trivy jq python3 git grep; do
    command -v "$tool" >/dev/null 2>&1 || missing+=("$tool")
  done
  if [[ ${#missing[@]} -gt 0 ]]; then
    echo "Missing prerequisites: ${missing[*]}" >&2
    exit 2
  fi
}

case "${1:-}" in
  --clean)
    rm -rf "$OUT"
    echo "Cleaned $OUT"
    ;;
  --verify)
    assert_prereqs
    python3 "$REPO_ROOT/tests/verify.py" --out "$OUT" --repo "$REPO_ROOT"
    ;;
  --help|"")
    usage
    ;;
  *)
    echo "Unknown argument: $1" >&2
    usage
    exit 2
    ;;
esac
