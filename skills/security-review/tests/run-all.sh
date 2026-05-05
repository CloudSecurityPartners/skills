#!/usr/bin/env bash
# Run all bash tests for the security-review skill.
# Validates: quarantine + restore mechanics from SKILL.md Step 1c and Step 5.
# For agent-behavior tests (do agents follow the don't-enumerate / treat-as-data
# rules?), see pressure-scenarios/ — those require live subagent runs and are
# executed manually.
set -e
cd "$(dirname "$0")"

total_fail=0

for t in test-quarantine.sh test-empty-target.sh; do
  echo "=== $t ==="
  bash "$t" || total_fail=$((total_fail + $?))
  echo
done

echo "=========================="
if [ "$total_fail" -eq 0 ]; then
  echo "ALL BASH TESTS PASSED"
  exit 0
else
  echo "FAILURES: $total_fail"
  exit 1
fi
