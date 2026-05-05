#!/usr/bin/env python3
"""Verifier for the security-review AI-tool-injection-defense fixture.

Runs scenario assertions T1..T10 against the security-review/ output produced
by /security-review on tests/fixtures/malicious-target/.

Usage:
    python3 tests/verify.py [--out PATH] [--repo PATH]

--out   Path to the security-review/ output directory.
        Default: tests/fixtures/malicious-target/security-review
--repo  Path to the repo root (used by static-check scenarios).
        Default: parent of tests/

Exits 0 when every scenario passes, 1 otherwise.
"""

from __future__ import annotations

import argparse
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Callable, List


@dataclass
class Result:
    name: str
    passed: bool
    detail: str


SCENARIOS: List[Callable[["Context"], Result]] = []


def scenario(fn: Callable[["Context"], Result]) -> Callable[["Context"], Result]:
    SCENARIOS.append(fn)
    return fn


@dataclass
class Context:
    out: Path
    repo: Path

    def report(self) -> Path:
        return self.out / "report-final.md"

    def catalog(self) -> Path:
        return self.out / "raw" / "ai-tool-files.md"

    def agent_output_files(self) -> List[Path]:
        """All agent-written markdown under out/, EXCLUDING the catalog itself."""
        if not self.out.is_dir():
            return []
        files = []
        for p in self.out.rglob("*.md"):
            if p == self.catalog():
                continue
            files.append(p)
        return files


def _read(p: Path) -> str:
    try:
        return p.read_text(encoding="utf-8", errors="replace")
    except FileNotFoundError:
        return ""


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--out", type=Path, default=None)
    parser.add_argument("--repo", type=Path, default=None)
    args = parser.parse_args()

    repo = (args.repo or Path(__file__).resolve().parent.parent).resolve()
    out = (args.out or repo / "tests" / "fixtures" / "malicious-target" / "security-review").resolve()

    ctx = Context(out=out, repo=repo)

    failed = 0
    for fn in SCENARIOS:
        result = fn(ctx)
        marker = "PASS" if result.passed else "FAIL"
        print(f"{marker}  {result.name}: {result.detail}")
        if not result.passed:
            failed += 1

    print()
    print(f"=== {len(SCENARIOS) - failed} passed, {failed} failed ===")
    return 0 if failed == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
