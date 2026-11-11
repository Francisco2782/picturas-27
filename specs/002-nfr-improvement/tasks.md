# Phase 2 NFR Improvement Tasks

## Video processing performance efficiency — capacity

- [ ] Capture and archive the baseline using `evaluation/` before application changes.
- [ ] Implement the selected worker/queue refactoring with bounded resource use.
- [ ] Capture final measurements with the identical harness, workload and environment.
- [ ] Run image and video regression tests; verify pipeline order and result behavior.
- [ ] Document the comparison, target/minimum result, side effects and limitations in the report.

## Usability — operability during processing

- [ ] Record the four-interaction baseline and reload behavior in the baseline checkout.
- [ ] Refactor processing status to remain accessible during navigation and recover after reload.
- [ ] Repeat the four-interaction measurement under the same browser and workload conditions.
- [ ] Run regression tests for image/video progress, completion, errors and result refresh.
- [ ] Document measurements, target/minimum result, side effects and limitations in the report.
