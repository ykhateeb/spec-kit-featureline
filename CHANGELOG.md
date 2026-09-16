# Changelog

All notable changes to featureline. Format: [Keep a Changelog](https://keepachangelog.com/).
Versions: extension and workflow are released together under one tag.

## [Unreleased]

## [1.0.1] - 2026-09-16

### Changed
- Setup adds a `test` script to `package.json` when there isn't one (`jest` if installed, otherwise a no-op placeholder) instead of stopping with MISSING.

### Fixed
- `extension.yml` repository URL now points at `ykhateeb/spec-kit-featureline`.

## [1.0.0] - 2026-09-16

### Added
- Extension: 9 commands (`write-brief`, `critique-brief`, `decide-tech`, `critique-plan`, `write-flows`, `critique-flows`, `review-spec`, `fix-code`, `draft-constitution`), 7 Maestro scripts, 2 hooks (`after_plan`, `after_implement`), handoffs on every command.
- Workflow: one file, three modes (`feature`, `setup`, `devices`), five human gates, three critics, two capped fix loops, two overlay slots.

- Config: `featureline-config.yml` (+ template, local overrides, `SPECKIT_FEATURELINE_*` env), per the extension guide; replaces `.maestro/devices.env`.
- Tests: `tests/test_featureline.py` using `specify_cli.extensions.ExtensionManifest`.

### Fixed
- Setup re-check no longer fails on a fresh project: the constitution line is informational, since setup mode drafts it in its last step.
- Repo URLs in README and catalogs now point at `ykhateeb/spec-kit-featureline`.
- README: `specify workflow validate` does not exist; use `specify workflow info`. Verified install, tests and validator against Spec Kit v1.0.7.
