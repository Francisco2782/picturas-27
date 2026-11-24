#!/usr/bin/env python3
"""Run the reproducible PictuRAS video contention scenario."""

from __future__ import annotations

import argparse
import csv
import datetime as dt
import json
import os
import re
import subprocess
import sys
import threading
import time
import uuid
import warnings
from dataclasses import asdict, dataclass, field
from pathlib import Path
from typing import Any, Callable

import requests
from requests import Response

try:
    from .summarize import SummaryError, render_table, summarize
except ImportError:  # Direct execution as `python evaluation/run_scenario.py`.
    from summarize import SummaryError, render_table, summarize


LOG_RE = re.compile(
    r"^(?P<timestamp>\S+)\s+(?:\S+\s+)?\[video\]\s+msg=(?P<msg>\S+)\s+"
    r"preview=False\s+tools=\[(?P<tools>[^\]]*)\]"
)
ISO_RE = re.compile(r"^(?P<date>\d{4}-\d\d-\d\dT[^ ]+)")
METRICS = (
    "a_duration_seconds",
    "b_duration_seconds",
    "b_wait_seconds",
    "makespan_seconds",
    "max_ready",
    "max_unacked",
    "peak_cpu_percent",
    "peak_memory_bytes",
)


class ScenarioError(RuntimeError):
    """A prerequisite, request, observation, or processing failure."""


def utc_now() -> dt.datetime:
    return dt.datetime.now(dt.timezone.utc)


def iso_now() -> str:
    return utc_now().isoformat()


def parse_timestamp(value: str) -> dt.datetime:
    value = value.strip()
    if value.endswith("Z"):
        value = value[:-1] + "+00:00"
    parsed = dt.datetime.fromisoformat(value)
    if parsed.tzinfo is None:
        parsed = parsed.replace(tzinfo=dt.timezone.utc)
    return parsed.astimezone(dt.timezone.utc)


def redact(value: Any) -> Any:
    if isinstance(value, dict):
        return {
            key: ("[REDACTED]" if key.lower() in {
                "password", "jwt", "authorization", "token", "cardnumber", "cvc",
            } else redact(item))
            for key, item in value.items()
        }
    if isinstance(value, list):
        return [redact(item) for item in value]
    return value


@dataclass
class WorkloadProject:
    label: str
    expected_results: int
    project_id: str | None = None
    version: int | None = None
    submission_at: str | None = None
    processing_start_at: str | None = None
    finished_at: str | None = None
    duration_seconds: float | None = None
    wait_seconds: float | None = None
    uploaded_files: list[str] = field(default_factory=list)


@dataclass
class WorkerSample:
    container_id: str
    name: str
    cpu_percent: float | None
    memory_bytes: int | None
    errors: list[str] = field(default_factory=list)


@dataclass
class ResourceSample:
    timestamp: str
    ready: int | None
    unacked: int | None
    cpu_percent: float | None
    memory_bytes: int | None
    errors: list[str] = field(default_factory=list)
    workers: list[WorkerSample] = field(default_factory=list)


@dataclass
class ScenarioRun:
    run_id: str
    kind: str
    status: str = "running"
    started_at: str = field(default_factory=iso_now)
    ended_at: str | None = None
    error: str | None = None
    projects: dict[str, WorkloadProject] = field(default_factory=dict)
    samples: list[ResourceSample] = field(default_factory=list)
    log_matches: list[dict[str, str]] = field(default_factory=list)
    worker_lifecycle: dict[str, dict[str, Any]] = field(default_factory=dict)


@dataclass
class RunSummary:
    run_id: str
    kind: str
    status: str
    metrics: dict[str, float | int] | None = None
    error: str | None = None


@dataclass
class AggregateSummary:
    count: int
    metrics: dict[str, dict[str, float | int]]


class ApiClient:
    def __init__(self, base_url: str, verify_tls: bool, timeout: float):
        self.base_url = base_url.rstrip("/")
        self.verify_tls = verify_tls
        self.timeout = timeout
        self.session = requests.Session()
        self.jwt: str | None = None
        self.user_id: str | None = None

    def _request(
        self,
        method: str,
        path: str,
        *,
        expected: tuple[int, ...] = (200,),
        version: int | None = None,
        **kwargs: Any,
    ) -> Response:
        headers = dict(kwargs.pop("headers", {}))
        if self.jwt is not None:
            headers["Authorization"] = f"Bearer {self.jwt}"
        if version is not None:
            headers["X-Project-Version"] = str(version)
        try:
            response = self.session.request(
                method, f"{self.base_url}/{path.lstrip('/')}", headers=headers,
                timeout=self.timeout, verify=self.verify_tls, **kwargs,
            )
        except requests.RequestException as exc:
            raise ScenarioError(f"{method} {path} failed: {exc}") from exc
        if response.status_code == 409:
            raise ScenarioError(
                f"HTTP 409 project version conflict on {method} {path}: "
                f"{redact(response.text)}"
            )
        if response.status_code not in expected:
            raise ScenarioError(
                f"HTTP {response.status_code} on {method} {path}: "
                f"{redact(response.text)}"
            )
        return response

    def login(self, email: str, password: str) -> dict[str, Any]:
        response = self._request(
            "POST", f"/users/{email}/login", expected=(200, 201),
            json={"password": password},
        )
        try:
            body = response.json()
            self.jwt = body["jwt"]
            user = body["user"]
            self.user_id = str(user["_id"])
        except (ValueError, KeyError, TypeError) as exc:
            raise ScenarioError("Login response did not contain user and jwt") from exc
        if user.get("type") != "premium":
            raise ScenarioError(
                f"Account {self.user_id} is {user.get('type')!r}; premium is required"
            )
        return user

    def create_project(self, name: str) -> WorkloadProject:
        response = self._request(
            "POST", f"/projects/{self.user_id}", expected=(201,),
            json={"name": name},
        )
        try:
            body = response.json()
            return WorkloadProject("", 0, str(body["_id"]), int(body["version"]))
        except (ValueError, KeyError, TypeError) as exc:
            raise ScenarioError("Project creation response lacked _id/version") from exc

    def upload_video(
        self, project: WorkloadProject, path: Path, upload_name: str | None = None,
    ) -> None:
        filename = upload_name or path.name
        with path.open("rb") as stream:
            response = self._request(
                "POST", f"/projects/{self.user_id}/{project.project_id}/video",
                expected=(204,), version=project.version,
                files={"video": (filename, stream, "application/octet-stream")},
            )
        project.version = _response_version(response, project)
        project.uploaded_files.append(filename)

    def add_tool(self, project: WorkloadProject, procedure: str, params: dict[str, Any]) -> None:
        response = self._request(
            "POST", f"/projects/{self.user_id}/{project.project_id}/tool",
            expected=(201, 204), version=project.version,
            json={"procedure": procedure, "params": params},
        )
        project.version = _response_version(response, project)

    def process(self, project: WorkloadProject) -> Response:
        response = self._request(
            "POST", f"/projects/{self.user_id}/{project.project_id}/process",
            expected=(201,), version=project.version, json={},
        )
        project.version = _response_version(response, project)
        return response

    def result_count(self, project: WorkloadProject) -> int:
        body = self.results(project)
        return len(body["imgs"]) + len(body.get("texts", []))

    def results(self, project: WorkloadProject) -> dict[str, Any]:
        response = self._request(
            "GET", f"/projects/{self.user_id}/{project.project_id}/process/url",
            expected=(200,),
        )
        try:
            body = response.json()
            if not isinstance(body, dict) or not isinstance(body.get("imgs"), list):
                raise ValueError("Expected an imgs list")
            return body
        except ValueError as exc:
            raise ScenarioError("Process URL response was not a JSON object") from exc


def _response_version(response: Response, project: WorkloadProject) -> int:
    value = response.headers.get("X-Project-Version")
    if value is None:
        raise ScenarioError(
            f"Mutation for project {project.project_id} did not return X-Project-Version"
        )
    try:
        return int(value)
    except ValueError as exc:
        raise ScenarioError(f"Invalid X-Project-Version value: {value!r}") from exc


def parse_memory(value: str) -> int:
    match = re.fullmatch(r"\s*([\d.]+)\s*([KMGT]?i?B)\s*", value)
    if not match:
        raise ValueError(f"invalid memory value {value!r}")
    units = {"B": 1, "KB": 1000, "MB": 1000**2, "GB": 1000**3,
             "KiB": 1024, "MiB": 1024**2, "GiB": 1024**3, "TiB": 1024**4}
    return int(float(match.group(1)) * units[match.group(2)])


def parse_stats(output: str, timestamp: str | None = None) -> ResourceSample:
    line = output.strip().splitlines()[-1] if output.strip() else ""
    fields = [part.strip() for part in line.split(",", 1)]
    errors: list[str] = []
    cpu: float | None = None
    memory: int | None = None
    try:
        cpu = float(fields[0].rstrip("%"))
        memory_text = fields[1].split(" / ", 1)[0]
        memory = parse_memory(memory_text)
    except (IndexError, ValueError) as exc:
        errors.append(f"invalid docker stats: {exc}")
    return ResourceSample(timestamp or iso_now(), None, None, cpu, memory, errors)


def discover_workers(
    service: str = "video_tool", project: str = "picturas",
    runner: Callable[..., subprocess.CompletedProcess[str]] = subprocess.run,
) -> list[dict[str, str]]:
    """Discover running Compose workers by service and project labels."""
    command = [
        "docker", "ps", "--no-trunc", "--filter", f"label=com.docker.compose.service={service}",
        "--filter", f"label=com.docker.compose.project={project}",
        "--format", "{{.ID}}\t{{.Names}}",
    ]
    try:
        result = runner(command, check=True, capture_output=True, text=True)
    except (OSError, subprocess.SubprocessError) as exc:
        raise ScenarioError(f"docker worker discovery failed: {exc}") from exc
    workers: list[dict[str, str]] = []
    for line in result.stdout.splitlines():
        fields = line.strip().split("\t", 1)
        if len(fields) == 2 and fields[0] and fields[1]:
            workers.append({"container_id": fields[0], "name": fields[1]})
    return sorted(workers, key=lambda worker: (worker["name"], worker["container_id"]))


def parse_worker_stats(
    output: str, workers: list[dict[str, str]], timestamp: str,
) -> ResourceSample:
    """Parse stats by Docker ID so output row ordering cannot mix replicas."""
    lines = [line.strip() for line in output.splitlines() if line.strip()]
    errors: list[str] = []
    samples: list[WorkerSample] = []
    rows: dict[str, tuple[str, str]] = {}
    for line in lines:
        fields = [part.strip() for part in line.split(",", 3)]
        if len(fields) == 4:
            rows[fields[0]] = (fields[2], fields[3])
        else:
            errors.append(f"malformed docker stats row: {line!r}")
    for worker in workers:
        row = next((value for key, value in rows.items()
                    if worker["container_id"].startswith(key)
                    or key.startswith(worker["container_id"])), None)
        if row is None:
            samples.append(WorkerSample(worker["container_id"], worker["name"], None, None,
                                        ["missing docker stats row"]))
            errors.append(f"{worker['name']}: missing docker stats row")
            continue
        parsed = parse_stats(f"{row[0]},{row[1]}", timestamp)
        samples.append(WorkerSample(
            worker["container_id"], worker["name"], parsed.cpu_percent,
            parsed.memory_bytes, parsed.errors,
        ))
        errors.extend(f"{worker['name']}: {error}" for error in parsed.errors)
    cpu_values = [sample.cpu_percent for sample in samples if sample.cpu_percent is not None]
    memory_values = [sample.memory_bytes for sample in samples if sample.memory_bytes is not None]
    return ResourceSample(
        timestamp, None, None,
        sum(cpu_values) if len(cpu_values) == len(workers) and workers else None,
        sum(memory_values) if len(memory_values) == len(workers) and workers else None,
        errors, samples,
    )


def parse_video_logs(output: str) -> list[dict[str, str]]:
    matches: list[dict[str, str]] = []
    for line in output.splitlines():
        match = LOG_RE.match(line)
        if not match:
            continue
        tools = match.group("tools")
        if "'subtitles'" in tools:
            label = "A"
        elif "'brightness'" in tools:
            label = "B"
        else:
            continue
        matches.append({
            "label": label,
            "timestamp": parse_timestamp(match.group("timestamp")).isoformat(),
            "message": match.group("msg"),
            "line": line,
        })
    return matches


def calculate_metrics(run: ScenarioRun, samples: list[ResourceSample]) -> dict[str, float | int]:
    a = run.projects["A"]
    b = run.projects["B"]
    if not all((a.submission_at, a.finished_at, b.submission_at, b.finished_at)):
        raise ScenarioError("Both projects need submission and completion timestamps")
    b_logs = [item for item in run.log_matches if item["label"] == "B"]
    if not b_logs:
        raise ScenarioError("No B brightness processing log was found")
    b.processing_start_at = b_logs[0]["timestamp"]
    a_end = parse_timestamp(a.finished_at)
    b_end = parse_timestamp(b.finished_at)
    a_start = parse_timestamp(a.submission_at)
    b_start = parse_timestamp(b.submission_at)
    b_log_start = parse_timestamp(b.processing_start_at)
    valid_samples = [sample for sample in samples if not sample.errors]
    if not valid_samples:
        raise ScenarioError("No valid queue/resource samples were collected")

    def sample_max(attribute: str) -> float | int:
        values = [getattr(sample, attribute) for sample in valid_samples]
        present = [value for value in values if value is not None]
        if not present:
            raise ScenarioError(f"No valid {attribute} values were collected")
        return max(present)

    return {
        "a_duration_seconds": (a_end - a_start).total_seconds(),
        "b_duration_seconds": (b_end - b_start).total_seconds(),
        "b_wait_seconds": (b_log_start - b_start).total_seconds(),
        "makespan_seconds": (max(a_end, b_end) - a_start).total_seconds(),
        "max_ready": sample_max("ready"),
        "max_unacked": sample_max("unacked"),
        "peak_cpu_percent": sample_max("cpu_percent"),
        "peak_memory_bytes": sample_max("memory_bytes"),
    }


def validate_files(paths: dict[str, Path]) -> None:
    for label, path in paths.items():
        if not path.is_file():
            raise ScenarioError(f"Required sample for {label} is missing: {path}")
        if path.name in {"corrupted.mp4", "too_long_90s.mp4"}:
            raise ScenarioError(f"Excluded sample cannot be used: {path}")


class Sampler:
    def __init__(self, args: argparse.Namespace, run: ScenarioRun):
        self.args = args
        self.run = run
        self.stop_event = threading.Event()
        self.worker_count: int | None = None
        self.thread = threading.Thread(target=self._loop, name="scenario-sampler", daemon=True)

    def start(self) -> None:
        self.thread.start()

    def stop(self) -> None:
        self.stop_event.set()
        if self.thread.is_alive():
            self.thread.join(timeout=self.args.sample_interval + 2)

    def _loop(self) -> None:
        while not self.stop_event.is_set():
            sample = ResourceSample(iso_now(), None, None, None, None)
            try:
                queue = requests.get(
                    self.args.rabbit_url, auth=(self.args.rabbit_user, self.args.rabbit_password),
                    timeout=self.args.timeout,
                )
                queue.raise_for_status()
                body = queue.json()
                sample.ready = int(body["messages_ready"])
                sample.unacked = int(body["messages_unacknowledged"])
            except (requests.RequestException, ValueError, KeyError, TypeError) as exc:
                sample.errors.append(f"rabbitmq sample failed: {exc}")
            try:
                workers = discover_workers(
                    self.args.video_worker_service, self.args.compose_project,
                )
                if not workers:
                    raise ScenarioError(
                        f"No running Compose workers found for project "
                        f"{self.args.compose_project!r}, service "
                        f"{self.args.video_worker_service!r}"
                    )
                if self.worker_count is None:
                    self.worker_count = len(workers)
                elif len(workers) != self.worker_count:
                    raise ScenarioError(
                        f"Worker replica count changed during run: expected "
                        f"{self.worker_count}, found {len(workers)}"
                    )
                ids = [worker["container_id"] for worker in workers]
                result = subprocess.run(
                    ["docker", "stats", "--no-stream", "--format",
                     "{{.ID}},{{.Name}},{{.CPUPerc}},{{.MemUsage}}", *ids],
                    check=True, capture_output=True, text=True, timeout=self.args.timeout,
                )
                stats = parse_worker_stats(result.stdout, workers, sample.timestamp)
                sample.cpu_percent, sample.memory_bytes = stats.cpu_percent, stats.memory_bytes
                sample.workers = stats.workers
                sample.errors.extend(stats.errors)
            except (OSError, subprocess.SubprocessError, ScenarioError) as exc:
                sample.errors.append(f"docker worker stats failed: {exc}")
            self.run.samples.append(sample)
            self.stop_event.wait(self.args.sample_interval)


def collect_logs(
    args: argparse.Namespace, since: str,
    observed_workers: list[dict[str, str]] | None = None,
) -> list[dict[str, str]]:
    workers_by_id = {
        worker["container_id"]: worker
        for worker in (observed_workers or [])
    }
    for worker in discover_workers(args.video_worker_service, args.compose_project):
        workers_by_id[worker["container_id"]] = worker
    workers = sorted(workers_by_id.values(), key=lambda item: (item["name"], item["container_id"]))
    if not workers:
        raise ScenarioError(
            f"No running Compose workers found for project {args.compose_project!r}, "
            f"service {args.video_worker_service!r} while collecting logs"
        )
    matches: list[dict[str, str]] = []
    for worker in workers:
        try:
            result = subprocess.run(
                ["docker", "logs", "--timestamps", "--since", since, worker["container_id"]],
                check=True, capture_output=True, text=True, timeout=args.timeout,
            )
        except (OSError, subprocess.SubprocessError) as exc:
            raise ScenarioError(f"docker logs failed for {worker['name']}: {exc}") from exc
        for match in parse_video_logs(result.stdout + result.stderr):
            match["container_id"] = worker["container_id"]
            match["container_name"] = worker["name"]
            matches.append(match)
    return sorted(matches, key=lambda item: (item["timestamp"], item["container_id"]))


def prepare_project(
    api: ApiClient,
    label: str,
    run_id: str,
    files: list[tuple[Path, str | None]],
    tool: tuple[str, dict[str, Any]],
) -> WorkloadProject:
    expected = 1 if label == "A" else 3
    project = api.create_project(f"baseline-{run_id}-{label}-{uuid.uuid4().hex[:8]}")
    project.label, project.expected_results = label, expected
    for path, upload_name in files:
        api.upload_video(project, path, upload_name)
    api.add_tool(project, *tool)
    return project


def validate_results(project: WorkloadProject, results: dict[str, Any]) -> bool:
    items = results["imgs"]
    if len(items) > project.expected_results or results.get("texts"):
        raise ScenarioError(f"Unexpected results for project {project.label}")
    if len(items) < project.expected_results:
        return False
    for field_name in ("result_id", "og_img_id"):
        values = {item.get(field_name) for item in items}
        if None in values or "" in values or len(values) != project.expected_results:
            raise ScenarioError(f"Missing or duplicate {field_name} for project {project.label}")
    if any(item.get("type") != "video" or not item.get("url") for item in items):
        raise ScenarioError(f"Unexpected media output for project {project.label}")
    return True


def wait_for_results(
    api: ApiClient, projects: list[WorkloadProject], args: argparse.Namespace,
) -> None:
    deadline = time.monotonic() + args.process_timeout
    pending = projects.copy()
    while pending and time.monotonic() < deadline:
        for project in pending.copy():
            if not validate_results(project, api.results(project)):
                continue
            project.finished_at = iso_now()
            project.duration_seconds = (
                parse_timestamp(project.finished_at) - parse_timestamp(project.submission_at)
            ).total_seconds()
            pending.remove(project)
        if pending:
            time.sleep(args.poll_interval)
    if pending:
        raise ScenarioError("Timed out waiting for projects " + ", ".join(p.label for p in pending))
    for project in projects:
        if not validate_results(project, api.results(project)):
            raise ScenarioError(f"Results disappeared for project {project.label}")


def worker_lifecycle(args: argparse.Namespace) -> dict[str, Any]:
    workers = discover_workers(args.video_worker_service, args.compose_project)
    if not workers or (args.expected_workers is not None and len(workers) != args.expected_workers):
        raise ScenarioError(f"Unexpected running worker count: {len(workers)}")
    result = subprocess.run(
        ["docker", "inspect", *[worker["container_id"] for worker in workers]],
        check=True, capture_output=True, text=True, timeout=args.timeout,
    )
    return {
        item["Id"]: {
            "started_at": item["State"]["StartedAt"],
            "running": item["State"]["Running"],
            "oom": item["State"]["OOMKilled"],
            "restarts": item["RestartCount"],
        }
        for item in json.loads(result.stdout)
    }


def validate_sample_coverage(run: ScenarioRun, sample_interval: float) -> None:
    expected = set(run.worker_lifecycle["before"])
    if run.worker_lifecycle["before"] != run.worker_lifecycle["after"] or any(
        not state["running"] or state["oom"] for state in run.worker_lifecycle["after"].values()
    ):
        raise ScenarioError("Worker set or lifecycle changed during the run")
    if not run.samples or any(
        sample.errors or set(worker.container_id for worker in sample.workers) != expected or
        None in (sample.ready, sample.unacked, sample.cpu_percent, sample.memory_bytes)
        for sample in run.samples
    ):
        raise ScenarioError("Incomplete queue or worker samples")
    timestamps = [parse_timestamp(sample.timestamp) for sample in run.samples]
    submitted = parse_timestamp(run.projects["A"].submission_at)
    finished = max(parse_timestamp(project.finished_at) for project in run.projects.values())
    gaps = [abs((timestamps[0] - submitted).total_seconds()), (finished - timestamps[-1]).total_seconds()]
    gaps.extend((right - left).total_seconds() for left, right in zip(timestamps, timestamps[1:]))
    # Docker stats --no-stream takes a measurement before returning, in addition to the interval.
    if max(gaps) > sample_interval + 5:
        raise ScenarioError(f"Queue or worker sample gap too long: {max(gaps):.3f}s")


def run_once(api: ApiClient, args: argparse.Namespace, kind: str, paths: dict[str, Path]) -> ScenarioRun:
    run = ScenarioRun(uuid.uuid4().hex, kind)
    run.started_at = iso_now()
    sampler = Sampler(args, run)
    try:
        run.projects["A"] = prepare_project(
            api, "A", run.run_id, [(paths["long"], None)], ("subtitles", {}),
        )
        run.projects["B"] = prepare_project(
            api, "B", run.run_id,
            [
                (paths["short"], None),
                (paths["short"], "sample_10s_720p_copy2.mp4"),
                (paths["six"], None),
            ],
            ("brightness", {"brightness": 1.1}),
        )
        run.worker_lifecycle["before"] = worker_lifecycle(args)
        sampler.start()
        a = run.projects["A"]
        b = run.projects["B"]
        a.submission_at = iso_now()
        api.process(a)
        time.sleep(args.dispatch_delay)
        b.submission_at = iso_now()
        api.process(b)
        wait_for_results(api, [a, b], args)
        sampler.stop()
        run.worker_lifecycle["after"] = worker_lifecycle(args)
        validate_sample_coverage(run, args.sample_interval)
        observed_workers = {
            worker.container_id: {"container_id": worker.container_id, "name": worker.name}
            for sample in run.samples for worker in sample.workers
        }
        run.log_matches = collect_logs(args, run.started_at, list(observed_workers.values()))
        metrics = calculate_metrics(run, run.samples)
        run.status = "valid"
        run.ended_at = iso_now()
        write_run_outputs(args.output_dir, run, metrics)
        return run
    except Exception as exc:
        sampler.stop()
        run.status = "invalid"
        run.error = str(exc)
        run.ended_at = iso_now()
        write_run_outputs(args.output_dir, run, None)
        raise ScenarioError(f"Run {run.run_id} ({kind}) failed: {exc}") from exc
    finally:
        sampler.stop()


def write_run_outputs(output_dir: Path, run: ScenarioRun, metrics: dict[str, Any] | None) -> None:
    run_dir = output_dir / run.run_id
    run_dir.mkdir(parents=True, exist_ok=True)
    (run_dir / "run.json").write_text(
        json.dumps(redact(asdict(run)), indent=2, sort_keys=True), encoding="utf-8",
    )
    with (run_dir / "samples.csv").open("w", newline="", encoding="utf-8") as stream:
        writer = csv.DictWriter(stream, fieldnames=["timestamp", "ready", "unacked", "cpu_percent", "memory_bytes", "workers", "errors"])
        writer.writeheader()
        for sample in run.samples:
            row = asdict(sample)
            row["workers"] = json.dumps(row["workers"], sort_keys=True)
            writer.writerow(row)
    worker_metrics: dict[str, dict[str, Any]] = {}
    for sample in run.samples:
        for worker in sample.workers:
            item = worker_metrics.setdefault(worker.container_id, {
                "container_id": worker.container_id, "container_name": worker.name,
                "peak_cpu_percent": None, "peak_memory_bytes": None,
            })
            if worker.cpu_percent is not None:
                item["peak_cpu_percent"] = max(item["peak_cpu_percent"] or 0, worker.cpu_percent)
            if worker.memory_bytes is not None:
                item["peak_memory_bytes"] = max(item["peak_memory_bytes"] or 0, worker.memory_bytes)
    (run_dir / "summary.json").write_text(
        json.dumps({"run_id": run.run_id, "kind": run.kind, "status": run.status,
                    "metrics": metrics, "worker_metrics": worker_metrics, "error": run.error,
                    "uploaded_files": {
                        label: project.uploaded_files
                        for label, project in run.projects.items()
                    }}, indent=2, sort_keys=True),
        encoding="utf-8",
    )


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--runs", type=int, default=3)
    parser.add_argument("--warmup", type=int, default=1)
    parser.add_argument("--stop-after-warmup", action="store_true")
    parser.add_argument("--api-base", default=os.getenv("PICTURAS_API_BASE", "https://localhost:8080/api-gateway"))
    parser.add_argument("--email", default=os.getenv("PICTURAS_EMAIL"))
    parser.add_argument("--password-env", default="PICTURAS_PASSWORD")
    parser.add_argument("--output-dir", type=Path, default=Path("evaluation/evidence"))
    parser.add_argument("--long-video", type=Path, default=Path("samples/video/speech_mandela_177s_1080p.webm"))
    parser.add_argument("--short-video", type=Path, default=Path("samples/video/sample_10s_720p.mp4"))
    parser.add_argument("--six-video", type=Path, default=Path("samples/video/sample_6s.mov"))
    parser.add_argument("--rabbit-url", default=os.getenv("RABBITMQ_MANAGEMENT_URL", "http://localhost:15672/api/queues/%2F/video_queue"))
    parser.add_argument("--rabbit-user", default=os.getenv("RABBITMQ_MANAGEMENT_USER", "user"))
    parser.add_argument("--rabbit-password-env", default="RABBITMQ_MANAGEMENT_PASSWORD")
    parser.add_argument("--compose-project", default=os.getenv("COMPOSE_PROJECT_NAME", "picturas"))
    parser.add_argument("--video-worker-service", default=os.getenv("VIDEO_WORKER_SERVICE", "video_tool"))
    parser.add_argument("--expected-workers", type=int, choices=(1, 2))
    parser.add_argument("--sample-interval", type=float, default=1.0)
    parser.add_argument("--dispatch-delay", type=float, default=1.5)
    parser.add_argument("--poll-interval", type=float, default=2.0)
    parser.add_argument("--process-timeout", type=float, default=3600.0)
    parser.add_argument("--timeout", type=float, default=30.0)
    parser.add_argument("--verify-tls", action="store_true")
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    if args.runs < 1:
        raise SystemExit("--runs must be at least 1")
    if args.warmup < 0:
        raise SystemExit("--warmup must be zero or greater")
    if not 1 <= args.dispatch_delay <= 2:
        raise SystemExit("--dispatch-delay must be between 1 and 2 seconds")
    if not args.email:
        raise SystemExit("Set PICTURAS_EMAIL or pass --email")
    password = os.getenv(args.password_env)
    rabbit_password = os.getenv(args.rabbit_password_env)
    if not password:
        raise SystemExit(f"Set {args.password_env}; credentials are never read from files")
    if not rabbit_password:
        raise SystemExit(f"Set {args.rabbit_password_env}; credentials are never read from files")
    validate_files({"long": args.long_video, "short": args.short_video, "six": args.six_video})
    args.rabbit_password = rabbit_password
    args.output_dir.mkdir(parents=True, exist_ok=True)
    if not args.verify_tls:
        warnings.filterwarnings("ignore", message="Unverified HTTPS request")
    api = ApiClient(args.api_base, args.verify_tls, args.timeout)
    api.login(args.email, password)
    paths = {"long": args.long_video, "short": args.short_video, "six": args.six_video}
    for index in range(args.warmup):
        print(f"Starting warm-up {index + 1}/{args.warmup}", flush=True)
        run_once(api, args, "warmup", paths)
    if args.stop_after_warmup:
        print("Warm-up complete; stopping before valid runs as requested.", flush=True)
        return 0
    for index in range(args.runs):
        print(f"Starting valid run {index + 1}/{args.runs}", flush=True)
        run_once(api, args, "measured", paths)
    try:
        aggregate = summarize(args.output_dir, args.runs)
    except SummaryError as exc:
        raise ScenarioError(f"Unable to summarize requested evidence: {exc}") from exc
    print(render_table(aggregate), flush=True)
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except ScenarioError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        raise SystemExit(1)
