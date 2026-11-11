# Quickstart: Baseline Video Measurement

## Prerequisites

1. Use the baseline checkout first, then repeat from the refactored checkout
   without changing the scenario parameters.
2. Start the stack and confirm HTTPS is reachable at `https://localhost:8080`.
3. Use a premium test account. Keep the password in an environment variable and
   never place it in a command file or evidence output.
4. Confirm these files exist and do not substitute the excluded
   `corrupted.mp4` or `too_long_90s.mp4`:

   ```text
   samples/video/speech_mandela_177s_1080p.webm
   samples/video/sample_10s_720p.mp4
   samples/video/sample_6s.mov
   ```

5. Confirm RabbitMQ management is reachable at `http://localhost:15672` and
   identify the active video-worker container.
6. Install Python 3 and `requests`. No additional client framework is required;
   B's processing-start estimate comes from the RabbitMQ queue transition.

## Run

From the repository root:

```bash
export PICTURAS_EMAIL='premium-test@example.invalid'
export PICTURAS_PASSWORD='set-locally'
export RABBITMQ_MANAGEMENT_USER='user'
export RABBITMQ_MANAGEMENT_PASSWORD='password'
python3 evaluation/run_scenario.py --runs 3 --warmup 1
```

The command must create new projects for every run, perform one warm-up, wait
between A and B submissions by the configured 1–2 seconds, and print the
per-run and aggregate tables.

## Validate evidence

Inspect the generated run directories under the selected output directory:

- raw HTTP request metadata without secrets;
- project IDs and version transitions;
- B queue-transition start marker and its sampling uncertainty;
- timestamped queue and resource samples;
- per-run summaries and the aggregate mean/min/max.

Then run the summary independently:

```bash
python3 evaluation/summarize.py path/to/evidence
```

The command must refuse to report success if fewer than three measured runs are
valid. Compare the baseline and refactored outputs using the same parameters and
environment record. The key conclusion is whether B's measured wait is positive
and how many seconds it was.

## Failure handling

Stop and fix prerequisites when login, premium verification, sample-file
validation, RabbitMQ sampling, worker sampling, or result polling fails. A 409
project version conflict invalidates only the affected run but still causes the
requested evidence count to fail unless another valid run replaces it.
