# Publish the video elasticity and editor changes

`git fetch origin main` found seven upstream commits. The local report draft
was saved in a local stash pending authorization to revise the report.
`git merge --ff-only origin/main` integrated all seven upstream commits without
conflicts. The first `git push origin HEAD:main` published `c4ddc6c` (video
autoscaling), `bb1d671` (A/B harness and tests) and `d611533` (editor controls and
downloads).

The documentation review found that the evaluation guide's fixed-replica
validation rules read as global rules. The guide now scopes them to capacity
measurements and separates the evidence archive for the elasticity experiment.
The README describes the current grid, carousel and download controls. The
sample guide provides commands to recreate the browser demo from tracked
fixtures. The generated copies and excerpt stay in the local, ignored `demo/`
directory.

## Verification

- `node --test frontend/tests/*.test.mjs projects/tests/*.test.js` passed 38
  tests. `python3 -m pytest -p no:cacheprovider evaluation/tests -q` passed 15.
- `docker compose config -q` passed and `docker compose build frontend`
  completed using the cached production build for the current source.
- `python3 docs/exercicios/check_citations.py` resolved all exercise citations
  at the baseline. `python3 -m pytest -p no:cacheprovider docs/exercicios/tests
  -q` passed three tests. `git diff --check` passed.
- In a fresh directory, the demo recipe reproduced the four source copies
  byte-for-byte. `ffprobe` identified the new excerpt as 45.014 seconds with
  VP9 video and Opus audio. A clean extraction of the elasticity archive passed
  both checksum checks and reproduced the 7.902-second mean across three valid
  runs. These checks replayed the documentation and archived measurements.

The report draft remains local for the later authorized revision. The browser
demo's remaining manual checks are listed in its session log.
