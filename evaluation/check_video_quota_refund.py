#!/usr/bin/env python3
"""Check video cancel refunds through the API on the validation stack."""

import argparse
import json
import secrets
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

import requests

from run_scenario import ApiClient
from run_video_recovery import API, status_response, wait_until


SAMPLE = Path("samples/video/sample_10s_720p.mp4")


def remaining(api):
    return api._request("GET", f"/users/{api.user_id}").json()["remaining_operations"]


def mutate_run(api, project, method, version, *, owner_id=None, share=None):
    owner = owner_id or api.user_id
    return requests.request(method, f"{API}/projects/{owner}/{project.project_id}/process", headers={
        "Authorization": f"Bearer {api.jwt}", "X-Project-Version": str(version),
    }, params={"share": share}, json={}, verify=False, timeout=20)


def prepare(api, name):
    project = api.create_project(name)
    api.upload_video(project, SAMPLE)
    api.add_tool(project, "brightness", {"brightness": 1.1})
    return project


def free_client():
    api = ApiClient(API, False, 20)
    created = api._request("POST", "/users", expected=(201,), json={
        "name": "F8 validation", "email": f"f8-{secrets.token_hex(8)}@example.test",
        "password": secrets.token_urlsafe(24), "type": "free",
    }).json()
    api.user_id = str(created["user"]["_id"])
    api.jwt = created["jwt"]
    assert remaining(api) == 5
    return api


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--baseline", action="store_true", help="Observe the old missing refund")
    args = parser.parse_args()
    requests.packages.urllib3.disable_warnings()
    api = free_client()

    if args.baseline:
        project = prepare(api, "F8 baseline")
        api.process(project)
        assert status_response(api, project).json()["state"] == "running"
        assert remaining(api) == 4
        assert mutate_run(api, project, "DELETE", project.version).status_code == 204
        balance = remaining(api)
        print(json.dumps({"before": 5, "charged": 4, "after_cancel": balance}))
        assert balance == 4, "The baseline unexpectedly already refunded the video operation"
        return

    completed = prepare(api, "F8 completed run")
    api.process(completed)
    wait_until(lambda: status_response(api, completed).json()["state"] == "completed",
               90, "completed video run")
    assert mutate_run(api, completed, "DELETE", completed.version).status_code == 204
    assert remaining(api) == 4 and len(api.results(completed)["imgs"]) == 1

    active = prepare(api, "F8 cancelled run")
    with ThreadPoolExecutor(max_workers=2) as executor:
        attempts = list(executor.map(lambda _: mutate_run(api, active, "POST", active.version), range(2)))
    assert sorted(response.status_code for response in attempts) == [201, 409]
    active.version = next(response.headers["X-Project-Version"] for response in attempts if response.ok)
    assert status_response(api, active).json()["state"] == "running"
    assert mutate_run(api, active, "POST", active.version).status_code == 409
    assert remaining(api) == 3
    with ThreadPoolExecutor(max_workers=2) as executor:
        responses = list(executor.map(lambda _: mutate_run(api, active, "DELETE", active.version), range(2)))
    assert sorted(response.status_code for response in responses) == [204, 409]
    assert status_response(api, active).json()["state"] == "cancelled"
    assert remaining(api) == 4
    current_version = next(response.headers["X-Project-Version"] for response in responses if response.ok)
    assert mutate_run(api, active, "DELETE", current_version).status_code == 204
    assert remaining(api) == 4 and not api.results(active)["imgs"]

    editor = free_client()
    shared = prepare(api, "F8 shared run")
    link = api._request("POST", f"/projects/{api.user_id}/{shared.project_id}/share", expected=(201,),
                        version=shared.version, json={"permission": "edit"})
    started = mutate_run(editor, shared, "POST", link.headers["X-Project-Version"],
                         owner_id=api.user_id, share=link.json()["id"])
    assert started.status_code == 201, started.status_code
    assert remaining(editor) == 4 and remaining(api) == 4
    assert status_response(api, shared).json()["state"] == "running"
    assert mutate_run(api, shared, "DELETE", started.headers["X-Project-Version"]).status_code == 204
    assert remaining(editor) == 5 and remaining(api) == 4
    print(json.dumps({"before": 5, "after_completed_run": 4, "after_active_charge": 3,
                      "concurrent_apply_statuses": [201, 409],
                      "concurrent_cancel_statuses": [204, 409], "after_cancel": 4,
                      "after_repeated_cancel": 4, "shared_payer_refunded": True}))


if __name__ == "__main__":
    main()
