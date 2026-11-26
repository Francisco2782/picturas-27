#!/usr/bin/env python3
"""Check inline file:line citations in exercise Markdown against a Git revision."""

import argparse
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DEFAULT_REVISION = "052310226c51fa57a17101c7bd1ad795674aac95"
CITATION = re.compile(
    r"(?P<path>[A-Za-z0-9_./-]+\.[A-Za-z0-9_-]+):"
    r"(?P<ranges>\d+(?:-\d+)?(?:,\s*\d+(?:-\d+)?)*)"
)


def git_lines(revision: str, path: str) -> int | None:
    result = subprocess.run(
        ["git", "show", f"{revision}:{path}"],
        cwd=ROOT,
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        check=False,
    )
    if result.returncode:
        return None
    return len(result.stdout.splitlines())


def range_errors(ranges: str, line_count: int) -> list[str]:
    errors = []
    for item in ranges.split(","):
        bounds = [int(value) for value in item.strip().split("-")]
        start, end = bounds[0], bounds[-1]
        if start < 1 or end < start or end > line_count:
            errors.append(f"range {item.strip()} outside 1-{line_count}")
    return errors


def check(revision: str) -> list[str]:
    problems = []
    for document in sorted((ROOT / "docs/exercicios").glob("*.md")):
        content = document.read_text(encoding="utf-8")
        for match in CITATION.finditer(content):
            path = match.group("path")
            line_count = git_lines(revision, path)
            location = f"{document.relative_to(ROOT)}:{content.count(chr(10), 0, match.start()) + 1}"
            if line_count is None:
                problems.append(f"{location}: {path} does not exist at {revision}")
                continue
            for error in range_errors(match.group("ranges"), line_count):
                problems.append(f"{location}: {path}:{error} at {revision}")
    return problems


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--commit", default=DEFAULT_REVISION)
    args = parser.parse_args()
    problems = check(args.commit)
    if problems:
        print("\n".join(problems))
        return 1
    print(f"All exercise citations resolve at {args.commit}.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
