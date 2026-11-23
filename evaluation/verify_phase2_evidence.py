#!/usr/bin/env python3
"""Recount the Phase 2 headline measurements from archived observations."""

import json
from datetime import datetime
from pathlib import Path
from statistics import mean


EVIDENCE = Path(__file__).resolve().parent / "evidence"
FINAL = EVIDENCE / "phase2-final-2026-11-22"
BASELINE = EVIDENCE / "official-baseline-usability-2026-11-17"


def read_json(path):
    return json.loads(path.read_text(encoding="utf-8"))


def require(condition, message):
    if not condition:
        raise SystemExit(message)


def capacity(directory):
    waits = []
    for path in sorted(directory.glob("*/run.json")):
        run = read_json(path)
        if run["kind"] != "measured" or run["status"] != "valid":
            continue
        submitted = datetime.fromisoformat(run["projects"]["B"]["submission_at"])
        starts = [datetime.fromisoformat(event["timestamp"]) for event in run["log_matches"]
                  if event["label"] == "B"]
        require(len(starts) == 3, f"{path}: expected three B start records")
        wait = (min(starts) - submitted).total_seconds()
        require(wait >= 0, f"{path}: negative wait")
        waits.append(wait)
    require(len(waits) == 3, f"{directory}: expected three valid measured runs")
    print(f"{directory.name}: {', '.join(f'{wait:.6f}' for wait in waits)} s, mean {mean(waits):.6f} s")


def usability():
    paths = read_json(BASELINE / "manifest.json")["valid_trial_records"]
    baseline = [read_json(BASELINE / path) for path in paths]
    require(len(baseline) == 3 and all(trial["valid_trial"] for trial in baseline),
            "Expected three valid baseline browser trials")
    require(all(len(trial["actions"]) == 4 for trial in baseline),
            "Expected four baseline actions per browser trial")
    baseline_score = sum(action["passed"] for trial in baseline for action in trial["actions"].values())
    navigation = sum(trial["navigation_recovery"]["passed"] for trial in baseline)
    refresh = sum(trial["refresh_recovery"]["passed"] for trial in baseline)
    print(f"Browser baseline: {baseline_score}/12 actions, navigation {navigation}/3, reload {refresh}/3")

    action_names = ("1_open_B", "2_use_B_toolbar", "3_return_A", "4_confirm_A")
    scores, routes, reloads, reconnects, premature = [], [], [], [], []
    for number in range(1, 4):
        trial = read_json(FINAL / "usability" / f"trial-{number}.json")
        actions = {name: observation for _, name, observation in trial["actions"]}

        def live(name):
            observed = actions.get(name, {})
            return observed.get("api") == "running" and observed.get("agreement") in {
                "direct", "event", "snapshot",
            }

        scores.append(sum(map(live, action_names)))
        routes.append(live("3_return_A") and live("4_confirm_A"))
        reloads.append(live("refresh"))
        reconnects.append(live("reconnect") and actions.get("socket_restored", {}).get("server_state") == "running")
        premature.append(trial["false_completions"])
        require(actions.get("completed", {}).get("download_http") == 200,
                f"Final trial {number}: missing successful result download")
    print(f"Browser final: {sum(scores)}/12 actions, navigation {sum(routes)}/3, "
          f"reload {sum(reloads)}/3, reconnect {sum(reconnects)}/3, premature completions {sum(premature)}")


if __name__ == "__main__":
    capacity(EVIDENCE / "official-baseline-performance-2026-11-17")
    capacity(FINAL / "comparison-baseline")
    capacity(FINAL / "performance-retry")
    usability()
