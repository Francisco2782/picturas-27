# Phase 2 evidence and reproduction

## Final validation on `3cb1b74`

Obtain `picturas-phase2-final-3cb1b74.tar.gz` and its companion `.sha256` file from the evidence handoff. The package lives under the Git-ignored `evaluation/evidence/` directory. It includes the final raw observations, the environment and source manifest, the summary CSVs and the original D-01 archive.

```sh
sha256sum -c picturas-phase2-final-3cb1b74.tar.gz.sha256
tar -xzf picturas-phase2-final-3cb1b74.tar.gz
cd phase2-final-3cb1b74
sha256sum -c SHA256SUMS
python3 verify_final.py
python3 instruments/summarize.py capacity --runs 3
```

The mean B wait was 0.123429 s across three valid capacity runs. Chromium scored 12/12 actions, recovered navigation, reload and reconnect in 3/3 trials each, and recorded zero premature completions. The [final validation log](../docs/sessoes/2026-11-24-validacao-final-3cb1b74.md) records the configuration, individual results and verification after clean extraction.

## Complementary video elasticity evidence

Obtain `video-elasticity-2026-11-27.tar.gz` and its `.sha256` file from the evidence
handoff. The archive contains the dynamic trials, same-stack fixed controls,
controller logs, environment metadata and the instrument snapshots.

```sh
sha256sum -c video-elasticity-2026-11-27.tar.gz.sha256
tar -xzf video-elasticity-2026-11-27.tar.gz
cd video-elasticity-2026-11-27
sha256sum -c SHA256SUMS
python3 instruments/summarize.py dynamic --runs 3
```

The expected mean B wait is 7.902 s (range 7.704–8.031 s), including the start of
the added replica. Use the [elasticity procedure](README.md#video-worker-elasticity)
for a live rerun and the [session log](../docs/sessoes/2026-11-27-video-autoscaling.md)
for the measurements and limits. The fixed-replica protocols below reproduce
the official capacity results.

## Original D-01 archive

Extract `picturas-phase2-d01.tar.gz` into an empty directory and run the commands from its `picturas-phase2-d01/` root. Python 3.11+ and a SHA-256 utility are sufficient for this check.

```sh
sha256sum -c SHA256SUMS
python3 evaluation/verify_phase2_evidence.py
python3 evaluation/summarize.py evaluation/evidence/official-baseline-performance-2026-11-17 --runs 3
python3 evaluation/summarize.py evaluation/evidence/phase2-final-2026-11-22/comparison-baseline --runs 3
python3 evaluation/summarize.py evaluation/evidence/phase2-final-2026-11-22/performance-retry --runs 3
```

The verifier recalculates B wait from submission timestamps and the first matching worker start and counts the browser actions and recoveries in the trial records. The expected capacity means are 61.727085 s for the official baseline, 82.242372 s for the repeated one-worker comparison and 0.113221 s for the final two-worker campaign. The official browser baseline scored 6/12 actions with 0/3 navigation and reload recoveries. The final browser campaign scored 12/12 with 3/3 recovery on each of navigation, reload and reconnect and zero premature completions.

## Contents

| Path under `evaluation/evidence/` | Contents |
|---|---|
| `official-baseline-performance-2026-11-17/` | Official capacity manifest, warm-up and three measured runs. |
| `official-baseline-usability-2026-11-17/` | Selected browser trials 6–8, earlier attempts, notes, logs, screenshots and exact 10 s input. |
| `phase2-final-2026-11-22/` | Frozen source diff and manifest, configuration overrides, results per run, logs embedded in `run.json`, resource CSVs and final browser records and MP4s. `performance/` preserves the earlier campaign including the storage failure. `performance-retry/` is the selected final campaign. `comparison-baseline/` is the repeated one-worker campaign with the final harness. |
| `u04-chromium-2026-11-22/` | Exact final browser driver and the source/result caption comparison. |
| `phase2-f5-regression/`, `phase2-f5-verified-retry/` | Integrated regression records and F5 browser observations. |

The archive also includes the capacity runner, three capacity samples and their attribution in `samples/video/README.md`. The 10-second speech sample and captioned results derive from the credited CC BY 3.0 clip. The historical manifests have masked account hints removed. The archive contains the Git-tracked source diff and Compose overrides. Obtain the rest of the application source from its Git history.

## Fresh measurement

Use a dedicated Compose stack with empty test queues, a warmed Whisper cache and capacity for at least 16 SeaweedFS volumes for the final capacity campaign. Keep account and broker credentials in the environment. Build from the recorded source parent plus `application-and-harness.patch` in a clean checkout, or use the application and harness changes in `24c1266` and `7167136`. Compare image versions, configuration and sample hashes against the manifest. Archived image IDs are environment records. The original baseline worker image and exact historical browser driver are unavailable in the evidence. Fresh reruns can vary with the host, image builds and observation timing.

For capacity, use the commands and prerequisites in [the evaluation guide](README.md), with one worker on the baseline (`phase2-base`, with harness from `afb84e5` for the official measurement or the final harness for a fresh comparison) and two on the final revision. Run one warm-up and three measured trials per configuration. Use a fresh output directory per run series. The `storage.compose.yml` override documents the final and repeated baseline storage settings. `comparison.compose.yml` records the historical loopback gateway, runtime overlays and shared model cache. Its local paths and image tags need to be adapted to the replay host.

For the final browser run, copy the extracted `evaluation/evidence/` inputs into the checkout and install `requests` and Playwright 1.65.2 in a virtual environment. Provide Google Chrome at `/usr/bin/google-chrome`. The recorded version was 157.0.8103.50. Start the final stack at `https://localhost:8080` and run from the checkout root:

```sh
PYTHONPATH=. PYTHONDONTWRITEBYTECODE=1 PICTURAS_U04_EVIDENCE=evaluation/evidence/d01-browser-replay \
  python evaluation/evidence/u04-chromium-2026-11-22/browser_u04.py warmup trial-1 trial-2 trial-3
```

For the official browser baseline, follow the archived `observation-notes.md` against the baseline revision, using the same sample and viewport. Review the new records and downloads against the recorded scoring protocol. Capture the revision, environment, run IDs and any differences in the independent review.
