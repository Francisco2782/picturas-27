<!--
Sync Impact Report
- Version change: scaffold (unversioned) -> 1.0.0
- Modified principles: PRINCIPLE_1_NAME -> Refactoring Only; PRINCIPLE_2_NAME ->
  Measure Before Change; PRINCIPLE_3_NAME -> Quantified NFRs; PRINCIPLE_4_NAME ->
  Reproducible Evidence; PRINCIPLE_5_NAME -> Simplicity and Existing Conventions
- Added principle: AI Use Is Documented and Human-Validated
- Added sections: Additional Constraints; Development Workflow
- Removed sections: none
- Follow-up TODOs: RATIFICATION_DATE remains TODO because the original adoption date
  is not available in the repository context.
-->

# PictuRAS Phase 2 Constitution

## Core Principles

### I. Refactoring Only
PictuRAS Phase 2 MUST deliver non-functional refactoring only. Observable image and
video processing behavior MUST be preserved, and regression tests MUST provide
evidence of preservation. New user-facing features, processing capabilities, or
behavior changes are outside this constitution.

### II. Measure Before Change
Every non-functional requirement (NFR) MUST be measured on the unmodified baseline
at commit `052310226c51fa57a17101c7bd1ad795674aac95` before implementation begins.
The same method, scenario, and environment MUST be used for the final measurement.
The comparison MUST be recorded so that claims of improvement or preservation are
verifiable.

### III. Quantified NFRs
Every NFR MUST state its ISO/IEC 25010:2011 classification, scale and unit,
measurement method, baseline value, target value, minimum acceptable value, and the
origin of each value. An NFR without all of these fields MUST NOT be treated as
accepted project scope.

### IV. Reproducible Evidence
Scripts, input data, measurement configurations, and environment documentation
required to reproduce NFR evidence MUST be versioned under `evaluation/`. A person
other than the author MUST be able to repeat the baseline and final measurements
using those artifacts and obtain comparable results.

### V. Simplicity and Existing Conventions
Changes MUST follow `AGENTS.md`, the existing architecture, and repository
conventions. The project MUST prefer the simplest design that satisfies an accepted
NFR, MUST avoid unrelated rewrites, MUST keep code and user-facing messages in
English, MUST use small commits, MUST preserve existing line endings, and MUST NOT
commit secrets or generated artifacts.

### VI. Documented and Human-Validated AI Use
Use of AI to produce project content MUST be documented, and a human team member
MUST validate the delivered content. The team retains ownership and accountability
for all code, tests, documentation, measurements, and decisions committed to the
project.

## Additional Constraints

The existing Docker Compose microservices architecture and processing contracts
remain authoritative. Refactoring work MUST preserve supported image and video
processing behavior, inter-service contracts, media handling, and deployment
configuration unless a separately approved governance amendment explicitly changes
this rule. Evaluation artifacts MUST contain no credentials, personal data, or
unlicensed generated media.

NFRs MUST be classified using ISO/IEC 25010:2011 characteristics applicable to the
claim, including performance efficiency, reliability, maintainability, compatibility,
usability, security, or portability. A classification MUST explain why the selected
characteristic applies.

## Development Workflow

Before changing implementation, the team MUST capture the baseline measurements and
confirm the regression scenarios. During implementation, each change MUST remain
traceable to an accepted NFR and MUST preserve the existing behavior covered by
regression tests. Before completion, the team MUST repeat the measurements in the
same environment, compare baseline, target, minimum acceptable, and final values,
run the relevant regression and validation checks, and retain the evidence under
`evaluation/`.

Reviews MUST verify that the change is refactoring-only, that NFR fields and ISO
classification are complete, that evidence is reproducible, and that human
validation of AI-assisted content is recorded. Any unmet minimum acceptable value
MUST be reported explicitly and MUST block a claim of successful completion.

## Governance

This constitution governs Phase 2 engineering and evaluation decisions. Amendments
require agreement from the project team and MUST be documented in the constitution
with a rationale, impact report, and semantic version change. A MAJOR version is
required for removing or redefining a principle; a MINOR version is required for
adding a principle or materially expanding governance; a PATCH version is required
for clarifications and non-semantic corrections.

Every pull request and release review MUST check compliance with this constitution.
The review MUST confirm regression evidence, baseline/final measurement parity,
reproducibility artifacts, and human validation of AI-assisted work. `AGENTS.md`
provides operational development guidance and MUST remain consistent with this
constitution; where they conflict, this constitution takes precedence.

**Version**: 1.0.0 | **Ratified**: TODO(RATIFICATION_DATE): original adoption date is
unknown | **Last Amended**: 2026-11-10
