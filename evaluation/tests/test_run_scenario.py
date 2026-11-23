import argparse
import unittest
from unittest.mock import Mock, patch
from pathlib import Path

from evaluation.run_scenario import (
    ApiClient,
    ResourceSample,
    Sampler,
    ScenarioError,
    ScenarioRun,
    WorkloadProject,
    calculate_metrics,
    collect_logs,
    discover_workers,
    parse_memory,
    parse_stats,
    parse_worker_stats,
    parse_video_logs,
    validate_results,
    wait_for_results,
)


class RunScenarioTests(unittest.TestCase):
    def test_a_and_b_completion_are_observed_independently(self):
        submission = "2026-11-10T12:00:00+00:00"
        a = WorkloadProject("A", 1, submission_at=submission)
        b = WorkloadProject("B", 1, submission_at=submission)
        video = {"imgs": [{"result_id": "result", "og_img_id": "source",
                           "type": "video", "url": "https://example.test/result"}]}
        api = Mock()
        api.results.side_effect = [{"imgs": []}, video, video, video, video]
        args = argparse.Namespace(process_timeout=5, poll_interval=0)

        with patch("evaluation.run_scenario.iso_now", side_effect=[
            "2026-11-10T12:00:02+00:00", "2026-11-10T12:00:08+00:00",
        ]):
            wait_for_results(api, [a, b], args)

        self.assertEqual(b.duration_seconds, 2)
        self.assertEqual(a.duration_seconds, 8)

    def test_overcount_and_duplicate_sources_invalidate_results(self):
        item = {"result_id": "unique", "og_img_id": "same", "type": "video", "url": "url"}
        with self.assertRaisesRegex(ScenarioError, "Unexpected results"):
            validate_results(WorkloadProject("A", 1), {"imgs": [item, item]})
        with self.assertRaisesRegex(ScenarioError, "duplicate og_img_id"):
            validate_results(WorkloadProject("B", 2), {"imgs": [
                item, {**item, "result_id": "other"},
            ]})

    def test_worker_discovery_handles_zero_one_two_and_changing_ids(self):
        outputs = ["", "abc123\tpicturas-video_tool-1\n",
                   "def456\tpicturas-video_tool-2\nabc123\tpicturas-video_tool-1\n",
                   "ghi789\tpicturas-video_tool-1\n"]
        def runner(*args, **kwargs):
            return Mock(stdout=outputs.pop(0))

        self.assertEqual(discover_workers(runner=runner), [])
        self.assertEqual(len(discover_workers(runner=runner)), 1)
        two = discover_workers(runner=runner)
        self.assertEqual(len(two), 2)
        self.assertEqual([worker["container_id"] for worker in two], ["abc123", "def456"])
        changed = discover_workers(runner=runner)
        self.assertEqual(changed[0]["container_id"], "ghi789")

    def test_worker_stats_keep_individual_values_and_sum_group_resources(self):
        workers = [
            {"container_id": "a1", "name": "video_tool-1"},
            {"container_id": "b2", "name": "video_tool-2"},
        ]
        sample = parse_worker_stats(
            "a1,video_tool-1,12.5%,10MiB / 1GiB\n"
            "b2,video_tool-2,7%,20MiB / 1GiB\n", workers,
            "2026-11-10T12:00:00+00:00",
        )
        self.assertEqual(sample.cpu_percent, 19.5)
        self.assertEqual(sample.memory_bytes, 30 * 1024 * 1024)
        self.assertEqual([worker.cpu_percent for worker in sample.workers], [12.5, 7.0])
        self.assertEqual([worker.memory_bytes for worker in sample.workers],
                         [10 * 1024 * 1024, 20 * 1024 * 1024])

    def test_worker_stats_missing_or_malformed_rows_are_errors(self):
        workers = [
            {"container_id": "a1", "name": "video_tool-1"},
            {"container_id": "b2", "name": "video_tool-2"},
        ]
        missing = parse_worker_stats(
            "a1,video_tool-1,12%,10MiB / 1GiB\n", workers, "now",
        )
        self.assertTrue(missing.errors)
        self.assertIsNone(missing.cpu_percent)
        malformed = parse_worker_stats(
            "a1,video_tool-1,bad\n"
            "b2,video_tool-2,7%,20MiB / 1GiB\n", workers, "now",
        )
        self.assertTrue(malformed.errors)
        self.assertIsNone(malformed.cpu_percent)

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

    @patch("evaluation.run_scenario.subprocess.run")
    @patch("evaluation.run_scenario.discover_workers")
    def test_logs_are_collected_and_attributed_across_replicas(self, discover, run_command):
        discover.return_value = [
            {"container_id": "a1", "name": "video_tool-1"},
            {"container_id": "b2", "name": "video_tool-2"},
        ]
        run_command.side_effect = [
            Mock(stdout="2026-11-10T12:00:01Z [video] msg=a preview=False tools=['subtitles']\n", stderr=""),
            Mock(stdout="2026-11-10T12:00:03Z [video] msg=b preview=False tools=['brightness']\n", stderr=""),
        ]
        args = argparse.Namespace(video_worker_service="video_tool", compose_project="picturas", timeout=1)

        matches = collect_logs(args, "2026-11-10T12:00:00Z")

        self.assertEqual([match["label"] for match in matches], ["A", "B"])
        self.assertEqual([match["container_id"] for match in matches], ["a1", "b2"])
        self.assertEqual(run_command.call_count, 2)

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
