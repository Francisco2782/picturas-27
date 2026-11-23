#!/usr/bin/env python3
"""Measure incremental processing-status traffic under one polling observer."""

import argparse
import json
import time
from pathlib import Path
from statistics import mean, median

import requests

from run_video_recovery import create_caption_job, new_client, status_response, wait_until


SAMPLE = Path("evaluation/evidence/official-baseline-usability-2026-11-17/speech_mandela_10s.mp4")
WINDOW_SECONDS = 4


def trial(api, polling):
    project = create_caption_job(api, SAMPLE, "polling-on" if polling else "polling-off")
    api.process(project)
    started = time.monotonic()
    initial = status_response(api, project).json()
    if initial["state"] != "running":
        raise RuntimeError("Expected the caption job to be active at the start")
    start_window = time.monotonic()
    samples = []
    for second in range(1, WINDOW_SECONDS + 1):
        if polling:
            time.sleep(max(0, start_window + second - time.monotonic()))
            request_start = time.monotonic()
            response = status_response(api, project)
            elapsed = time.monotonic() - request_start
            snapshot = response.json()
            if snapshot["state"] != "running" or snapshot["runToken"] != initial["runToken"]:
                raise RuntimeError("Expected the same run to remain active throughout the window")
            samples.append({"offset_s": request_start - start_window, "elapsed_ms": elapsed * 1000,
                            "body_bytes": len(response.content)})
    time.sleep(max(0, start_window + WINDOW_SECONDS + 0.25 - time.monotonic()))
    end = status_response(api, project).json()
    if end["state"] != "running" or end["runToken"] != initial["runToken"]:
        raise RuntimeError("The caption job ended before the common observation window closed")

    def terminal():
        snapshot = status_response(api, project).json()
        return snapshot if snapshot["state"] != "running" else None

    final = wait_until(terminal, 120, "caption result")
    if final["state"] != "completed" or final["runToken"] != initial["runToken"]:
        raise RuntimeError("Expected the same caption run to complete")
    return {"polling": polling, "observed_completion_seconds": time.monotonic() - started,
            "incremental_requests": len(samples), "incremental_body_bytes": sum(s["body_bytes"] for s in samples),
            "samples": samples}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    requests.packages.urllib3.disable_warnings()
    api = new_client()
    output = {"sample": str(SAMPLE), "poll_interval_seconds": 1, "window_seconds": WINDOW_SECONDS,
              "warmup": [], "trials": []}
    try:
        for _ in range(2):
            output["warmup"].append(trial(api, True))
        for pair in range(1, 5):
            for polling in (True, False) if pair % 2 else (False, True):
                output["trials"].append({"pair": pair, **trial(api, polling)})
            print(f"Polling pair {pair}/4 complete", flush=True)
        active = [trial for trial in output["trials"] if trial["polling"]]
        control = [trial for trial in output["trials"] if not trial["polling"]]
        samples = [sample for trial in active for sample in trial["samples"]]
        output["summary"] = {
            "requests_per_window": mean(trial["incremental_requests"] for trial in active),
            "mean_body_bytes_per_window": mean(trial["incremental_body_bytes"] for trial in active),
            "median_http_ms": median(sample["elapsed_ms"] for sample in samples),
            "min_http_ms": min(sample["elapsed_ms"] for sample in samples),
            "max_http_ms": max(sample["elapsed_ms"] for sample in samples),
            "on_mean_completion_s": mean(trial["observed_completion_seconds"] for trial in active),
            "off_mean_completion_s": mean(trial["observed_completion_seconds"] for trial in control),
        }
    finally:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(json.dumps(output, indent=2) + "\n")


if __name__ == "__main__":
    main()
