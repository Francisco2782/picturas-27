import argparse
import unittest
from unittest.mock import Mock
from pathlib import Path

from evaluation.run_scenario import (
    ApiClient,
    ResourceSample,
    Sampler,
    ScenarioError,
    ScenarioRun,
    WorkloadProject,
    calculate_metrics,
    parse_memory,
    parse_stats,
    parse_video_logs,
)


class RunScenarioTests(unittest.TestCase):
    def test_api_requests_use_bearer_authorization(self):
        client = ApiClient("https://localhost", verify_tls=False, timeout=1)
        client.jwt = "jwt-value"
        response = Mock(status_code=200)
        client.session.request = Mock(return_value=response)

        client._request("GET", "/health")

        headers = client.session.request.call_args.kwargs["headers"]
        self.assertEqual(headers["Authorization"], "Bearer jwt-value")
        return
        self.assertEqual(headers["Authorization"], "Bearer jwt-value")

    def test_stopping_sampler_before_start_is_safe(self):
        args = argparse.Namespace(sample_interval=1.0)
        sampler = Sampler(args, ScenarioRun("r", "warmup"))

        sampler.stop()

    def test_upload_uses_distinct_filename_for_duplicate_content(self):
        client = ApiClient("https://localhost", verify_tls=False, timeout=1)
        client.user_id = "user"
        client.jwt = "jwt-value"
        client.session.request = Mock(
            return_value=Mock(status_code=204, headers={"X-Project-Version": "2"})
        )
        project = WorkloadProject("B", 3, project_id="project", version=1)

        client.upload_video(project, Path(__file__), "sample_10s_720p_copy2.mp4")

        request_files = client.session.request.call_args.kwargs["files"]
        self.assertEqual(request_files["video"][0], "sample_10s_720p_copy2.mp4")
        self.assertEqual(project.uploaded_files, ["sample_10s_720p_copy2.mp4"])

    def test_parse_video_logs_selects_pipeline_and_utc_timestamp(self):
        output = (
            "2026-11-10T12:00:00.123456789Z container [video] "
            "msg=request-a preview=False tools=['subtitles']\n"
            "2026-11-10T12:00:03.123456789Z container [video] "
            "msg=request-b preview=False tools=['brightness']\n"
        )
        matches = parse_video_logs(output)
        self.assertEqual([item["label"] for item in matches], ["A", "B"])
        self.assertEqual(matches[1]["timestamp"], "2026-11-10T12:00:03.123456+00:00")

    def test_b_wait_uses_first_b_log_not_queue_transition(self):
        run = ScenarioRun("r", "warmup")
        run.projects = {
            "A": WorkloadProject(
                "A", 1, submission_at="2026-11-10T12:00:00+00:00",
                finished_at="2026-11-10T12:00:20+00:00",
            ),
            "B": WorkloadProject(
                "B", 3, submission_at="2026-11-10T12:00:02+00:00",
                finished_at="2026-11-10T12:00:25+00:00",
            ),
        }
        run.log_matches = [{
            "label": "B", "timestamp": "2026-11-10T12:00:12+00:00",
            "message": "request-b", "line": "",
        }]
        samples = [ResourceSample("2026-11-10T12:00:03+00:00", 3, 1, 10.0, 100)]
        metrics = calculate_metrics(run, samples)
        self.assertEqual(metrics["b_wait_seconds"], 10.0)

    def test_missing_b_log_is_an_error(self):
        run = ScenarioRun("r", "warmup")
        run.projects = {
            "A": WorkloadProject(
                "A", 1, submission_at="2026-11-10T12:00:00+00:00",
                finished_at="2026-11-10T12:00:20+00:00",
            ),
            "B": WorkloadProject(
                "B", 3, submission_at="2026-11-10T12:00:02+00:00",
                finished_at="2026-11-10T12:00:25+00:00",
            ),
        }
        with self.assertRaises(ScenarioError):
            calculate_metrics(run, [ResourceSample("now", 1, 1, 1.0, 1)])

    def test_stats_and_memory_parsing(self):
        self.assertEqual(parse_memory("10MiB"), 10 * 1024 * 1024)
        sample = parse_stats("12.5%,10MiB / 1GiB")
        self.assertEqual(sample.cpu_percent, 12.5)
        self.assertEqual(sample.memory_bytes, 10 * 1024 * 1024)


if __name__ == "__main__":
    unittest.main()
