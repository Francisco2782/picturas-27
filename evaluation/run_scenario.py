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
class ResourceSample:
    timestamp: str
    ready: int | None
    unacked: int | None
    cpu_percent: float | None
    memory_bytes: int | None
    errors: list[str] = field(default_factory=list)


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
            headers["Authorization"] = "Bearer " + self.jwt
            headers["Authorization"] = f"Bearer {self.jwt}"
        if version is not None:
            headers["X-Project-Version"] = str(version)
        if self.jwt is not None:
            headers["Authorization"] = "Bearer " + self.jwt
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
        response = self._request(
            "GET", f"/projects/{self.user_id}/{project.project_id}/process/url",
            expected=(200,),
        )
        try:
            body = response.json()
            return len(body.get("imgs", [])) + len(body.get("texts", []))
        except (ValueError, AttributeError) as exc:
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
                result = subprocess.run(
                    ["docker", "stats", "--no-stream", "--format",
                     "{{.CPUPerc}},{{.MemUsage}}", self.args.video_worker_container],
                    check=True, capture_output=True, text=True, timeout=self.args.timeout,
                )
                stats = parse_stats(result.stdout, sample.timestamp)
                sample.cpu_percent, sample.memory_bytes = stats.cpu_percent, stats.memory_bytes
                sample.errors.extend(stats.errors)
            except (OSError, subprocess.SubprocessError) as exc:
                sample.errors.append(f"docker stats failed: {exc}")
            self.run.samples.append(sample)
            self.stop_event.wait(self.args.sample_interval)


def collect_logs(args: argparse.Namespace, since: str) -> list[dict[str, str]]:
    try:
        result = subprocess.run(
            ["docker", "logs", "--timestamps", "--since", since, args.video_worker_container],
            check=True, capture_output=True, text=True, timeout=args.timeout,
        )
    except (OSError, subprocess.SubprocessError) as exc:
        raise ScenarioError(f"docker logs failed: {exc}") from exc
    output = result.stdout + result.stderr
    return parse_video_logs(output)


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


def wait_for_result(api: ApiClient, project: WorkloadProject, args: argparse.Namespace) -> None:
    deadline = time.monotonic() + args.process_timeout
    while time.monotonic() < deadline:
        count = api.result_count(project)
        if count >= project.expected_results:
            project.finished_at = iso_now()
            project.duration_seconds = (
                parse_timestamp(project.finished_at) - parse_timestamp(project.submission_at)
            ).total_seconds()
            return
        time.sleep(args.poll_interval)
    raise ScenarioError(
        f"Timed out waiting for project {project.label} ({project.project_id}) "
        f"to reach {project.expected_results} results"
    )


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
        sampler.start()
        a = run.projects["A"]
        b = run.projects["B"]
        a.submission_at = iso_now()
        api.process(a)
        time.sleep(args.dispatch_delay)
        b.submission_at = iso_now()
        api.process(b)
        wait_for_result(api, a, args)
        wait_for_result(api, b, args)
        sampler.stop()
        run.log_matches = collect_logs(args, run.started_at)
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
        writer = csv.DictWriter(stream, fieldnames=["timestamp", "ready", "unacked", "cpu_percent", "memory_bytes", "errors"])
        writer.writeheader()
        for sample in run.samples:
            writer.writerow(asdict(sample))
    (run_dir / "summary.json").write_text(
        json.dumps({"run_id": run.run_id, "kind": run.kind, "status": run.status,
                    "metrics": metrics, "error": run.error,
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
    parser.add_argument("--video-worker-container", default=os.getenv("VIDEO_WORKER_CONTAINER", "picturas-video_tool-1"))
    parser.add_argument("--sample-interval", type=float, default=1.0)
    parser.add_argument("--dispatch-delay", type=float, default=1.5)
    parser.add_argument("--poll-interval", type=float, default=2.0)
    parser.add_argument("--process-timeout", type=float, default=3600.0)
    parser.add_argument("--timeout", type=float, default=30.0)
    parser.add_argument("--verify-tls", action="store_true")
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
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
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except ScenarioError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        raise SystemExit(1)
