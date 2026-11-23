#!/usr/bin/env python3
"""Exercise an in-flight video job on the dedicated Phase 2 validation stack."""

import argparse
import hashlib
import json
import re
import secrets
import subprocess
import tempfile
import time
from pathlib import Path

import requests

from run_scenario import ApiClient, discover_workers, iso_now, redact, validate_results


STACK = "picturas-validation"
API = "https://localhost:8080/api-gateway"
BROKER = f"{STACK}-rabbitmq-1"
SAMPLE = Path("samples/video/speech_mandela_177s_1080p.webm")
START = re.compile(r"\[video\] msg=(\S+) preview=False tools=\['subtitles'\]")


def docker(*args):
    return subprocess.run(["docker", *args], check=True, capture_output=True,
                          text=True, timeout=30).stdout.strip()


def wait_until(check, timeout, description):
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        value = check()
        if value:
            return value
        time.sleep(0.25)
    raise RuntimeError(f"Timed out waiting for {description}")


def new_client():
    api = ApiClient(API, False, 20)
    response = api._request("POST", "/users", expected=(201,), json={
        "name": "Phase 2 validation", "type": "premium",
        "email": f"phase2-{secrets.token_hex(8)}@example.test",
        "password": secrets.token_urlsafe(24),
    }).json()
    api.jwt = response["jwt"]
    api.user_id = str(response["user"]["_id"])
    return api


def create_caption_job(api, sample, label):
    project = api.create_project(f"{label}-{secrets.token_hex(4)}")
    project.label = label
    project.expected_results = 1
    api.upload_video(project, sample)
    api.add_tool(project, "subtitles", {})
    return project


def status_response(api, project):
    return api._request("GET", f"/projects/{api.user_id}/{project.project_id}/processing-status")


def queue_state(name):
    output = docker("exec", BROKER, "rabbitmqctl", "-q", "list_queues", "name",
                    "messages_ready", "messages_unacknowledged", "consumers")
    for line in output.splitlines():
        fields = line.split()
        if fields and fields[0] == name:
            return dict(zip(("ready", "unacked", "consumers"), map(int, fields[1:])))
    raise RuntimeError(f"{name} was not listed")


def temporary_artifacts(container):
    return set(docker("exec", container, "find", "/app/images", "-mindepth", "1",
                      "(", "-name", "*.part*", "-o", "-name", "*.video-work", "-o",
                      "-name", "captions-*", "-o", "-name", "frame-source-*", ")", "-print").splitlines())


def observed_starts(workers, since):
    observations = []
    for worker in workers:
        for line in docker("logs", "--timestamps", "--since", since, worker).splitlines():
            match = START.search(line)
            if match:
                observations.append({"worker": worker, "message_id": match[1],
                                     "timestamp": line.split()[0]})
    return sorted(observations, key=lambda observation: observation["timestamp"])


def run(recovery, evidence):
    workers = [worker["name"] for worker in discover_workers(project=STACK)]
    expected = {f"{STACK}-video_tool-{replica}" for replica in (1, 2)}
    if set(workers) != expected or queue_state("video_queue") != {"ready": 0, "unacked": 0, "consumers": 2}:
        raise RuntimeError("Expected two idle workers on the dedicated validation stack")
    if queue_state("project_queue")["consumers"] != 1:
        raise RuntimeError("Expected one project_queue consumer before interruption")
    containers = docker("ps", "--filter", "publish=8080", "--format", "{{.Names}}").splitlines()
    if containers != [f"{STACK}-nginx-1"]:
        raise RuntimeError("Expected only the dedicated validation nginx on port 8080")
    api = new_client()
    project = create_caption_job(api, SAMPLE, "qs03")
    before = temporary_artifacts(workers[0])
    since = iso_now()
    evidence.update({"before": sorted(before), "project_id": project.project_id,
                     "submitted_at": since, "fault": recovery})
    api.process(project)
    started = wait_until(lambda: observed_starts(workers, since), 30, "worker start")[0]
    active = status_response(api, project).json()
    during = wait_until(lambda: temporary_artifacts(started["worker"]) - before,
                        15, "temporary output during processing")
    if active["state"] != "running" or queue_state("video_queue")["unacked"] != 1:
        raise RuntimeError("Expected one active, unacknowledged video before interruption")
    evidence.update({"start": started, "run_token": active["runToken"],
                     "during": sorted(during), "interrupted_at": iso_now()})
    target = started["worker"] if recovery == "worker" else BROKER
    docker("restart", "--time", "0", target)
    print(f"Interrupted {target} after the worker created temporary output", flush=True)

    def terminal():
        status = status_response(api, project).json()
        return status if status["state"] != "running" else None

    try:
        result = wait_until(terminal, 180, "terminal processing status")
        evidence["status"] = result["state"]
        evidence["terminal_run_token"] = result["runToken"]
        if result["state"] == "completed" and result["runToken"] == active["runToken"]:
            outputs = api.results(project)
            if not validate_results(project, outputs):
                raise RuntimeError("Expected exactly one downloadable video result")
            download = requests.get(outputs["imgs"][0]["url"], verify=False, timeout=20)
            download.raise_for_status()
            with tempfile.TemporaryDirectory(prefix="qs03-") as temp:
                path = Path(temp) / "result.mp4"
                path.write_bytes(download.content)
                probe = subprocess.run(["ffprobe", "-v", "error", "-show_streams", "-of",
                                        "json", str(path)], check=True, capture_output=True, text=True)
            evidence["download"] = {"http": download.status_code, "bytes": len(download.content),
                                    "sha256": hashlib.sha256(download.content).hexdigest(),
                                    "streams": [stream["codec_type"] for stream in json.loads(probe.stdout)["streams"]]}
    finally:
        evidence["starts"] = observed_starts(workers, since)
        evidence["orphaned_artifacts"] = sorted(temporary_artifacts(workers[0]) - before)
        evidence["queue"] = queue_state("video_queue")
        evidence["project_queue"] = queue_state("project_queue")
    redeliveries = [start for start in evidence["starts"] if start["message_id"] == started["message_id"]]
    if (len(evidence["starts"]) != 2 or len(redeliveries) != 2 or evidence["orphaned_artifacts"]
            or evidence.get("download", {}).get("streams") != ["video", "audio"]
            or evidence["queue"] != {"ready": 0, "unacked": 0, "consumers": 2}
            or evidence["project_queue"]["consumers"] != 1):
        raise RuntimeError("Recovery criteria were not met; see the evidence")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--fault", choices=("worker", "broker"), required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    evidence = {}
    requests.packages.urllib3.disable_warnings()
    try:
        run(args.fault, evidence)
        evidence["passed"] = True
    except Exception as error:
        evidence["passed"] = False
        evidence["error"] = str(error)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(redact(evidence), indent=2) + "\n")
    print(f"{'PASS' if evidence['passed'] else 'FAIL'}: {args.output}")
    return 0 if evidence["passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
