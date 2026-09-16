# Changelog

All notable changes to featureline. Format: [Keep a Changelog](https://keepachangelog.com/).
Versions: extension and workflow are released together under one tag.

## [Unreleased]

## [1.0.6] - 2026-09-16

### Fixed
- Android build in `mode=setup` failed with "SDK location not found" when `ANDROID_HOME` was only set in a shell rc file the workflow shell never loads (e.g. `.zshrc` while running fish). `config.sh` now falls back to `ANDROID_SDK_ROOT`, then `~/Library/Android/sdk`.

## [1.0.5] - 2026-09-16

### Added
- `mode=setup` logs to `.maestro/setup.log`. Spec Kit's shell steps capture output and show nothing while they run, so a 15-minute build looked hung. Each setup script now runs through the new `log.sh`, which appends its output plus start time, exit code and duration to the log while keeping stdout and the exit code the workflow reads. Watch it with `tail -f .maestro/setup.log`.

## [1.0.4] - 2026-09-16

### Changed
- `mode=setup` has no gates. `setup-check.sh` and `find-app-ids.sh` fail the run instead of pausing (a `SET_ME` app id stops it; edit `featureline-config.yml` and run again, the file is kept). The constitution draft is still written but never applied; the final message tells you to run `/speckit.constitution` with it, and feature mode's preflight still refuses to start without a real `constitution.md`. The smoke flow runs last and fails the run if it fails, so flows and the draft are already in place when you re-run.

## [1.0.3] - 2026-09-16

### Changed
- `setup-check.sh` now only checks Spec Kit's `.specify/` layout indirectly (dropped - the script's own path already proves it) and the `package.json` test script; the Java/Xcode CLI tools/adb/Android emulator/AVD/Maestro CLI checks are gone. `boot-devices.sh`, `build.sh`, `smoke.sh` and `e2e.sh` still call those tools directly, so a missing one now surfaces as a plain command-not-found later in the run instead of a guided `MISSING` line at the first gate.
- `mode=setup`'s toolchain and app-id gates now only pause when `setup-check.sh` / `find-app-ids.sh` actually found something to fix (`exit_code != 0`); a clean re-run skips both. Removed `setup-gate-build`, a pure approve-to-continue gate with nothing to review - its warning about build time is now an echo ahead of the build.

## [1.0.2] - 2026-09-16

### Changed
- Release CI updates `catalog/extensions.json` and `catalog/workflows.json` to the new tag, so `specify extension update` / `specify workflow update` see it. The workflow catalog now points at the pinned release asset instead of `main`.

### Fixed
- `config.sh` no longer crashes when PyYAML is missing and `featureline-config.local.yml` doesn't exist. The fallback parser ran inside `except ImportError`, so the sibling `except FileNotFoundError` never caught the missing file; every build/smoke script then died on an unbound `BUILD_IOS`.
- `build.sh` and `boot-devices.sh` pin `ANDROID_SERIAL` to the first online device; a stale `offline` emulator made bare `adb shell` fail with "more than one device/emulator".
- `e2e.sh` runs without a tag under macOS `/bin/bash` 3.2, where an empty array under `set -u` is an unbound variable.
- `find-app-ids.sh` writes `featureline-config.yml` as YAML sections (`ios.bundle_id`, `build.ios`, ...) instead of shell `KEY="value"` lines that `config.sh` couldn't read.

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
