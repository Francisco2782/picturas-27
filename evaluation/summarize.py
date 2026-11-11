#!/usr/bin/env python3
"""Validate and aggregate PictuRAS per-run evaluation summaries."""

from __future__ import annotations

import argparse
import json
import math
import sys
from pathlib import Path
from typing import Any

METRICS = (
    "a_duration_seconds", "b_duration_seconds", "b_wait_seconds",
    "makespan_seconds", "max_ready", "max_unacked", "peak_cpu_percent",
    "peak_memory_bytes",
)


class SummaryError(ValueError):
    """Evidence is missing, invalid, or insufficient for requested aggregation."""


def load_summaries(directory: Path) -> list[dict[str, Any]]:
    if not directory.is_dir():
        raise SummaryError(f"Evidence directory does not exist: {directory}")
    files = sorted(directory.glob("*/summary.json"))
    if not files:
        raise SummaryError(f"No per-run summary.json files found in {directory}")
    records: list[dict[str, Any]] = []
    for path in files:
        try:
            record = json.loads(path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as exc:
            raise SummaryError(f"Cannot read {path}: {exc}") from exc
        if not isinstance(record, dict):
            raise SummaryError(f"{path}: summary must be a JSON object")
        for key in ("run_id", "kind", "status"):
            if not isinstance(record.get(key), str) or not record[key]:
                raise SummaryError(f"{path}: missing or invalid {key}")
        if record["kind"] not in {"warmup", "measured"}:
            raise SummaryError(f"{path}: kind must be 'warmup' or 'measured'")
        if record["status"] not in {"valid", "invalid", "incomplete"}:
            raise SummaryError(f"{path}: status must be valid, invalid, or incomplete")
        records.append(record)
    return records


def valid_measured(records: list[dict[str, Any]]) -> list[dict[str, Any]]:
    selected = []
    for record in records:
        if record["kind"] != "measured" or record["status"] != "valid":
            continue
        metrics = record.get("metrics")
        if not isinstance(metrics, dict):
            raise SummaryError(f"Run {record['run_id']}: valid measured summary has no metrics object")
        missing = [metric for metric in METRICS if metric not in metrics]
        if missing:
            raise SummaryError(f"Run {record['run_id']}: missing metrics: {', '.join(missing)}")
        for metric in METRICS:
            value = metrics[metric]
            if isinstance(value, bool) or not isinstance(value, (int, float)) or not math.isfinite(value) or value < 0:
                raise SummaryError(f"Run {record['run_id']}: {metric} must be a finite non-negative number")
        selected.append(record)
    return selected


def aggregate(records: list[dict[str, Any]], required_runs: int | None = None) -> dict[str, Any]:
    runs = valid_measured(records)
    if required_runs is not None and len(runs) < required_runs:
        raise SummaryError(f"Insufficient valid measured runs: found {len(runs)}, required {required_runs}")
    metrics: dict[str, dict[str, int | float]] = {}
    for name in METRICS:
        values = [run["metrics"][name] for run in runs]
        metrics[name] = {
            "mean": sum(values) / len(values) if values else 0,
            "min": min(values) if values else 0,
            "max": max(values) if values else 0,
            "count": len(values),
        }
    return {"count": len(runs), "metrics": metrics, "runs": runs}


def render_table(summary: dict[str, Any]) -> str:
    lines = ["Per-run metrics (valid measured runs)", "run_id  " + "  ".join(METRICS)]
    for run in summary["runs"]:
        values = "  ".join(_format(run["metrics"][name]) for name in METRICS)
        lines.append(f"{run['run_id']}  {values}")
    lines.extend(("", f"Valid measured runs: {summary['count']}",
                  "Aggregate  metric  mean  min  max"))
    for name in METRICS:
        item = summary["metrics"][name]
        lines.append(f"Aggregate  {name}  {_format(item['mean'])}  {_format(item['min'])}  {_format(item['max'])}")
    waits = [run["metrics"]["b_wait_seconds"] for run in summary["runs"]]
    if any(value > 0 for value in waits):
        lines.append(f"B waited {sum(waits) / len(waits):.1f}s")
    else:
        lines.append("B did not wait")
    return "\n".join(lines)


def _format(value: int | float) -> str:
    return str(value) if isinstance(value, int) else f"{value:.3f}"


def summarize(directory: Path, required_runs: int | None = None) -> dict[str, Any]:
    return aggregate(load_summaries(directory), required_runs)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("evidence_dir", type=Path, nargs="?", default=Path("evaluation/evidence"))
    parser.add_argument("--runs", type=int, required=True, help="required number of valid measured runs")
    args = parser.parse_args(argv)
    if args.runs < 1:
        parser.error("--runs must be at least 1")
    try:
        print(render_table(summarize(args.evidence_dir, args.runs)))
    except SummaryError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
