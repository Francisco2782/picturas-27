#!/usr/bin/env python3
"""Scale the local PictuRAS Compose video service from RabbitMQ queue depth."""

import argparse
import base64
import fcntl
import json
import math
import os
import subprocess
import sys
import tempfile
import time
from datetime import datetime, timezone
from pathlib import Path
from urllib.request import Request, urlopen


SERVICE = "video_tool"
DRAIN_LABEL = "org.picturas.video-drain"


def docker(*args):
    result = subprocess.run(["docker", *args], capture_output=True, text=True, timeout=60)
    if result.returncode:
        raise RuntimeError(result.stderr.strip() or f"docker {args[0]} failed")
    return result.stdout


def log(message):
    print(f"{datetime.now(timezone.utc).isoformat()} {message}", flush=True)


class Autoscaler:
    def __init__(self, args):
        self.args = args
        self.compose = ("compose", "-p", args.project)
        credentials = f"{args.rabbit_user}:{args.rabbit_password}".encode()
        header = "Basic " + base64.b64encode(credentials).decode()
        self.request = Request(args.rabbit_url, headers={"Authorization": header})
        self.resume_at = 0
        self.empty_since = None
        self.draining = None

    def workers(self):
        ids = docker(*self.compose, "ps", "--all", "-q", SERVICE).split()
        if not ids:
            return []
        workers = json.loads(docker("inspect", *ids))
        workers = [w for w in workers if w["Config"]["Labels"].get(
            "com.docker.compose.oneoff", "false").lower() == "false"]
        if any(w["Config"]["Labels"].get(DRAIN_LABEL) != "signal-v1" for w in workers):
            raise RuntimeError("Rebuild existing video_tool containers before enabling autoscaling")
        return sorted(workers, key=lambda w: int(w["Config"]["Labels"][
            "com.docker.compose.container-number"]))

    def step(self):
        with urlopen(self.request, timeout=5) as response:
            queue = json.load(response)
        ready = queue["messages_ready"]
        unacked = queue["messages_unacknowledged"]
        consumers = queue["consumers"]
        if any(type(value) is not int or value < 0 for value in (ready, unacked, consumers)):
            raise ValueError("RabbitMQ returned invalid queue counters")
        workers = self.workers()
        active = [w for w in workers if w["State"]["Running"] or w["State"]["Restarting"]]
        count = len(active)
        now = time.monotonic()
        if ready or unacked or consumers != count:
            self.empty_since = None
        elif self.empty_since is None:
            self.empty_since = now

        if self.draining:
            if any(w["Id"] == self.draining for w in active):
                return
            log(f"drain complete, running={count}")
            self.draining = None
            self.resume_at = now + self.args.cooldown

        if now < self.resume_at:
            return
        if count < self.args.minimum or (
            count < self.args.maximum and ready > 0 and consumers == count
        ):
            log(f"scale up {count}->{count + 1}, ready={ready}, unacked={unacked}")
            stopped = [w for w in workers if w["State"]["Status"] in ("created", "exited")]
            if stopped:
                docker("start", stopped[0]["Id"])
            else:
                docker(*self.compose, "up", "-d", "--no-deps", "--no-build", "--no-recreate",
                       "--scale", f"{SERVICE}={count + 1}", SERVICE)
            self.resume_at = time.monotonic() + self.args.cooldown
        elif (count > self.args.minimum and self.empty_since is not None
              and now - self.empty_since >= self.args.idle_seconds):
            worker = active[-1]
            log(f"request drain {worker['Name'].lstrip('/')}, running={count}, ready=0, unacked=0")
            docker("kill", "--signal=USR1", worker["Id"])
            self.draining = worker["Id"]

    def run(self):
        log(f"autoscaling {self.args.project}/{SERVICE}, minimum={self.args.minimum}, "
            f"maximum={self.args.maximum}, interval={self.args.interval}s, "
            f"cooldown={self.args.cooldown}s, idle={self.args.idle_seconds}s")
        while True:
            started = time.monotonic()
            try:
                self.step()
            except (OSError, RuntimeError, ValueError, KeyError, subprocess.TimeoutExpired) as error:
                self.empty_since = None
                self.resume_at = time.monotonic() + self.args.cooldown
                log(f"Reconciliation failed: {error}")
            time.sleep(max(0, self.args.interval - (time.monotonic() - started)))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project", default=os.getenv("COMPOSE_PROJECT_NAME", "picturas"))
    parser.add_argument("--rabbit-url", default=os.getenv("RABBITMQ_MANAGEMENT_URL",
                        "http://localhost:15672/api/queues/%2F/video_queue"))
    parser.add_argument("--rabbit-user", default=os.getenv("RABBITMQ_MANAGEMENT_USER", "user"))
    parser.add_argument("--minimum", type=int, default=os.getenv("VIDEO_WORKERS_MIN", "1"))
    parser.add_argument("--maximum", type=int, default=os.getenv("VIDEO_WORKERS_MAX", "3"))
    parser.add_argument("--interval", type=float, default=os.getenv("VIDEO_WORKERS_INTERVAL", "1"))
    parser.add_argument("--cooldown", type=float, default=os.getenv("VIDEO_WORKERS_COOLDOWN", "5"))
    parser.add_argument("--idle-seconds", type=float, default=os.getenv("VIDEO_WORKERS_IDLE_SECONDS", "10"))
    args = parser.parse_args()
    args.rabbit_password = os.getenv("RABBITMQ_MANAGEMENT_PASSWORD")
    if not args.rabbit_password:
        parser.error("Set RABBITMQ_MANAGEMENT_PASSWORD")
    if not 1 <= args.minimum <= args.maximum:
        parser.error("Require 1 <= minimum <= maximum")
    if any(not math.isfinite(value) or value <= 0
           for value in (args.interval, args.cooldown, args.idle_seconds)):
        parser.error("Interval, cooldown and idle duration must be positive and finite")
    if not args.project or not all(c.isascii() and (c.isalnum() or c in "-_") for c in args.project):
        parser.error("Invalid Compose project name")

    lock_path = Path(tempfile.gettempdir()) / f"picturas-video-{os.getuid()}-{args.project}.lock"
    with lock_path.open("a") as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            parser.error(f"An autoscaler is already running for {args.project}")
        try:
            Autoscaler(args).run()
        except KeyboardInterrupt:
            return 0
    return 0


if __name__ == "__main__":
    sys.exit(main())
