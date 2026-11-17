import unittest

from evaluation.summarize import aggregate, render_table


def record(run_id, kind="measured", status="valid", offset=0):
    names = (
        "a_duration_seconds", "b_duration_seconds", "b_wait_seconds",
        "makespan_seconds", "max_ready", "max_unacked", "peak_cpu_percent",
        "peak_memory_bytes",
    )
    return {
        "run_id": run_id, "kind": kind, "status": status,
        "metrics": {name: offset + index + 1 for index, name in enumerate(names)},
        "worker_metrics": {
            f"{run_id}-worker-1": {
                "container_id": f"{run_id}-worker-1", "container_name": "video_tool-1",
                "peak_cpu_percent": 11.0 + offset, "peak_memory_bytes": 1000 + offset,
            },
            f"{run_id}-worker-2": {
                "container_id": f"{run_id}-worker-2", "container_name": "video_tool-2",
                "peak_cpu_percent": 9.0 + offset, "peak_memory_bytes": 2000 + offset,
            },
        },
    }


class SummarizeTests(unittest.TestCase):
    def test_keeps_group_and_per_worker_peaks_for_valid_measured_runs(self):
        summary = aggregate([
            record("warm", kind="warmup"),
            record("valid-1"),
            record("invalid", status="invalid"),
            record("valid-2", offset=2),
        ], required_runs=2)

        self.assertEqual(summary["count"], 2)
        self.assertEqual(summary["metrics"]["peak_cpu_percent"]["mean"], 8.0)
        self.assertEqual(len(summary["worker_peaks"]), 4)
        table = render_table(summary)
        self.assertIn("Per-worker peak resources", table)
        self.assertIn("valid-1-worker-1", table)
        self.assertIn("valid-2-worker-2", table)


if __name__ == "__main__":
    unittest.main()
