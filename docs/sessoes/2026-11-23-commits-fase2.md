# Phase 2 scope and commit preparation

## Scope

- Recorded QS-03 in the report's functional preservation section and in the recovery session. It is a supplementary regression of DA-1 (QS-01), covering redelivery, output availability and cleanup with two consumers on one queue. QS-01 and QS-02 remain the two selected requirements.
- Recorded F8 as a separate correction for an inherited quota bug. The earlier closed campaign used premium accounts. The free-account integration evidence is in `evaluation/evidence/phase2-followup-2026-11-23/quota-{before,after,retry}.json`.

## Verification

- Read the working tree and index with `git status --short --branch`, `git diff --cached --stat`, and `git diff --stat`. The session started with an empty index and pending changes from the measurement, recovery, quota and report work.
- Compiled `docs/src-doc-fase2-template/main.typ` with the local Typst 0.14.9 installation and repository fonts, extracted the text, and rendered the revised functional preservation page with `pdftoppm`. The QS-03 and F8 discussion appeared together on physical page 29 of 33.
- Rechecked the observed F8 integration records. The original cancellation left the free account at 4 operations. The corrected version debited once despite competing Apply requests, preserved the debit for a completed run, and refunded a shared execution to its editor. After a temporary quota service outage, a repeat restored the balance from 4 to 5 and a second repeat kept it at 5.
- Reran the video worker pytest suite (77 passed, existing Pillow deprecation warning), evaluation pytest suite (14 passed), and `node --test projects/tests/*.test.js frontend/tests/processing-status.test.mjs` (38 passed). `git diff --check` and the staged whitespace checks passed.
- Reran `python3 evaluation/verify_phase2_evidence.py` and verified the SHA-256 of the D-01 archive. The recount matched the frozen campaign and the archive retained its previous digest. Saved the revised PDF alongside the evidence. `git check-ignore` confirmed that both generated artifacts are ignored.

## Handoff

The commits preceding the report update are `f566b0b` (recovery), `0028690` (polling instrumentation), `cba9b3a` (quota correction), and `a06e0ad` (reproduction tooling). The official campaign remains the frozen comparison for the selected requirements. A new campaign on the combined version and independent review by the team remain pending.
