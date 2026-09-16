# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Two GitHub Spec Kit packages that ship together, for React Native apps with Maestro E2E:

- `featureline-ext/`: a Spec Kit **extension**. It has 9 agent commands (markdown prompts in `commands/`), bash scripts, 2 hooks and a config template. `extension.yml` is its manifest.
- `featureline-workflow/workflow.yml`: a Spec Kit **workflow**. It runs those commands, plus core `speckit.*` commands and the scripts, as one gated pipeline.
- `catalog/`: JSON install sources that teams point `specify ... catalog add` at.

There is no app code here. The "code" is the prompts, the YAML and the bash scripts, which run inside the *user's* project after install. Scripts are installed to `.specify/extensions/featureline/scripts/` and `cd` to the git root of that project.

## Commands

```bash
pip install pyyaml pytest "git+https://github.com/github/spec-kit.git"   # dev deps (pyyaml is needed by everything)
./scripts/validate.sh                        # offline checks CI runs: manifest, command files, workflow, bash -n
python -m pytest -q tests                    # test_manifest_loads_with_speckit skips without specify_cli
python -m pytest -q tests -k workflow        # single test
```

Try it in a real Spec Kit project:

```bash
specify extension add --dev <repo>/featureline-ext --force     # reinstall after every edit
specify workflow  add --dev <repo>/featureline-workflow
specify workflow run featureline -i mode=setup                 # modes: feature (default, needs -i idea=...), setup, devices
specify workflow resume <run_id>
```

Gates prompt on stdin. Run from a non-interactive shell (for example Claude Code's `!`), a workflow **pauses** at the first gate and never gets past it. Test gate behavior in a real terminal.

## Architecture

**Workflow structure.** The top-level `route` step `switch`es on `inputs.mode` into three step lists (`feature`, `setup`, `devices`). Steps have these types:

- `command`: a featureline or core `speckit.*` command.
- `shell`: runs an installed script by path `".specify/extensions/featureline/scripts/<name>.sh"`.
- `gate`: human approve/reject, usually with `show_file`.
- `do-while`: the capped fix loops, e.g. `e2e-cycle`, max 5.
- `if`
- `slot`: overlay points `post-implement` and `pre-review`.

**Shell step semantics matter.** A non-zero exit fails the run unless the step has `continue_on_error: true`. The pattern is: check with `continue_on_error`, then a gate showing the report, then a re-check *without* it, so unfixed problems stop the run. Conditions read `steps.<id>.output.exit_code`.

**State passes through files, not variables.** Commands and scripts talk via files in the user's project:

- `specs/briefs/`
- `specs/<NNN>/` (`decisions.md`, `clarify.md`, `testids.md`, `maestro-summary.txt`, `maestro-*.xml`)
- `.maestro/<NNN>/` for flows, `.maestro/_setup/`
- `.maestro/setup-report.txt`

Gates display these files. The user answers by editing them.

**Script config.** Every script that needs app ids or build commands does `source "$(dirname "$0")/config.sh"`. It merges these, lowest to highest precedence, and exports `IOS_BUNDLE_ID`, `ANDROID_PACKAGE`, `BUILD_IOS` and `BUILD_ANDROID`:

1. `featureline-config.template.yml`
2. `featureline-config.yml`
3. `featureline-config.local.yml`
4. `SPECKIT_FEATURELINE_*` env vars

`config.sh` has a no-PyYAML fallback parser, so keep the config YAML flat: two levels, `key: value`.

**Script exit codes are part of the contract.** The workflow branches on them. For example, `e2e.sh` returns 0 when everything passes, 1 when anything fails and 2 when no device is booted, and `setup-check.sh` returns 1 if any line is MISSING. Change an exit code only together with the workflow steps that read it.

## Rules the validator and tests enforce

- Command names follow `speckit.featureline.<verb>-<noun>`. Each needs a file in `commands/` with a frontmatter `description`, and every `handoffs[].agent` must be a featureline or core command.
- Command bodies must not contain literal `/speckit.x` invocations. Use `__SPECKIT_COMMAND_X__` tokens, which Spec Kit rewrites per agent integration.
- Workflow step ids are unique across all branches and contain no `:`. Every `command:` step targets a known command.
- `workflow.version` must equal `extension.version`, and `workflow.id` must equal `extension.id`. Adding a command means updating `extension.yml`, the count asserted in `tests/test_featureline.py` (`len(m.commands) == 9`), and the README table.

## Versioning and release

- Any change under `featureline-ext/` or `featureline-workflow/` needs a version bump in **both** `extension.yml` and `workflow.yml`, plus a `## [x.y.z]` section in `CHANGELOG.md`. The CI PR guard enforces this, and `specify extension update` is version-driven, so an unbumped change never reaches installed copies.
- To release, push `main` first, then a tag `vX.Y.Z` that matches the manifest version. CI zips each package with its manifest at the archive root and publishes the release with the changelog section as notes. It then commits `catalog/extensions.json`, `catalog/workflows.json` and the README install URL, pointing at the release assets, to `main`. Run `git pull` before your next push, and don't edit the catalogs or that URL by hand.
- Files matched by `featureline-ext/.extensionignore` are left out of the installed copy.

## Design invariants (from README; commands depend on them)

- A spec never names a technology. Tech choices live in the constitution and the plan.
- E2E flows are written from the spec before the code, and are never edited to make them pass. `fix-code` fixes code only, and treats `testids.md` as the source of truth for testIDs.
- The pipeline never merges or pushes. It never writes `constitution.md` from a draft without approval.
