# Changelog

All notable changes to featureline. Format: [Keep a Changelog](https://keepachangelog.com/).
Versions: extension and workflow are released together under one tag.

## [Unreleased]

## [1.0.0] - 2026-09-16

### Added
- Extension: 9 commands (`write-brief`, `critique-brief`, `decide-tech`, `critique-plan`, `write-flows`, `critique-flows`, `review-spec`, `fix-code`, `draft-constitution`), 7 Maestro scripts, 2 hooks (`after_plan`, `after_implement`), handoffs on every command.
- Workflow: one file, three modes (`feature`, `setup`, `devices`), five human gates, three critics, two capped fix loops, two overlay slots.

- Config: `featureline-config.yml` (+ template, local overrides, `SPECKIT_FEATURELINE_*` env), per the extension guide; replaces `.maestro/devices.env`.
- Tests: `tests/test_featureline.py` using `specify_cli.extensions.ExtensionManifest`.

### Fixed
- Setup re-check no longer fails on a fresh project: the constitution line is informational, since setup mode drafts it in its last step.
