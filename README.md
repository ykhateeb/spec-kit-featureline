# featureline

A production line for features: idea in, tested feature out.

A [GitHub Spec Kit](https://github.com/github/spec-kit) **extension** (nine
roles as commands, Maestro scripts, hooks) plus a Spec Kit **workflow** (the
gated sequence). For React Native, with Maestro E2E on iOS and Android.
Works with Claude Code, Copilot, Gemini CLI - any Spec Kit integration.

```
featureline-ext/          the roles:   /speckit.featureline.write-brief … .review
featureline-workflow/     the line:    specify workflow run featureline
catalog/                  install source for your team
```

## Install

From a GitHub release (recommended once published):

```bash
cd your-app
specify extension add featureline --from https://github.com/ykhateeb/spec-kit-featureline/releases/download/v1.0.4/featureline-ext-v1.0.4.zip
specify workflow  add featureline --from https://raw.githubusercontent.com/ykhateeb/spec-kit-featureline/main/featureline-workflow/workflow.yml
```

From a clone, for development:

```bash
git clone https://github.com/ykhateeb/spec-kit-featureline ~/tools/spec-kit-featureline
cd your-app
specify extension add --dev ~/tools/spec-kit-featureline/featureline-ext
specify workflow  add --dev ~/tools/spec-kit-featureline/featureline-workflow
```

As a team install source:

```bash
specify extension catalog add https://raw.githubusercontent.com/ykhateeb/spec-kit-featureline/main/catalog/extensions.json --name featureline --install-allowed
specify workflow  catalog add https://raw.githubusercontent.com/ykhateeb/spec-kit-featureline/main/catalog/workflows.json
specify extension add featureline     # add --force if a --dev or --from copy is already installed
specify workflow  add featureline
```

Later releases: `specify extension update featureline` and `specify workflow update featureline`.

Either way, then:

```bash
specify extension list                # featureline · 9 commands · 2 hooks
specify workflow  info featureline
```

Restart your agent so it sees the new commands. Extension first, always -
the workflow refuses to run without it.

## Use

```bash
specify workflow run featureline -i mode=setup          # once per repo: toolchain, devices, build, smoke, constitution draft
specify workflow run featureline -i mode=devices        # each session: boot simulators, rebuild
specify workflow run featureline -i idea="…"            # each feature
specify workflow resume <run_id>                        # after closing the terminal
```

Shell steps print nothing until they finish, and setup's first build takes
5-15 minutes per platform. Watch setup live from another terminal with
`tail -f .maestro/setup.log`: every setup script's output, with start time,
exit code and duration.

Gates prompt in the terminal and show the file to review.

Or drive it by hand inside your agent - every command ends with a handoff
button to the next step:

```
/speckit.featureline.write-brief interview: customers can request a refund
```

## The pipeline (mode=feature)

```
brief ─▶ ┌ critic ─▶ [gate 1: approve / revise] ─▶ revise ┐ ×3
  ─▶ specify ─▶ clarify ─▶ [gate 2: answers] ─▶ apply
  ─▶ decisions ─▶ [gate 3: picks] ─▶ apply ─▶ plan ─▶ plan critic
  ─▶ flows ─▶ flow critic ─▶ [gate: critiques + hooks]
  ─▶ ┌ tasks ─▶ analyze ─▶ [gate 4: approve / fix] ─▶ fix ┐ ×3
  ─▶ implement ─▶ unit tests
  ─▶ ┌ build ─▶ e2e p1 ─▶ [gate: fix?] ─▶ fix ┐ ×5
  ─▶ ┌ review ─▶ [gate 5: merge / fix] ─▶ fix ─▶ rebuild ┐ ×3
  ─▶ done (you merge)
```

Your answers go into files the gates show: `specs/briefs/_interview.md`,
`specs/<NNN>/clarify.md`, a Pick column in `specs/<NNN>/decisions.md`.
Two overlay slots: `post-implement`, `pre-review`.

## The commands

| Command | Does |
|---|---|
| `write-brief interview: <idea>` / `draft: <idea>` / `revise` | interview → brief → apply critique |
| `critique-brief` | what is wrong with the brief, blocking or not |
| `decide-tech [dir]` / `decide-tech apply <dir>` | decision record, test hooks, plan input → apply picks, grow the constitution |
| `critique-plan [dir]` | plan vs constitution, decisions, spec |
| `write-flows [dir]` | one Maestro flow per acceptance criterion + testids.md |
| `critique-flows [dir]` | flows vs criteria |
| `review-spec [dir]` | runs the flows on every booted device; READY / NOT READY |
| `fix-code e2e\|review\|analyze <dir>` | fix the code, never the flows |
| `draft-constitution` | starter constitution from the repo |

All namespaced `speckit.featureline.<name>`. Two optional hooks: plan critic
after `/speckit.plan`, review after `/speckit.implement`.

Scripts install to `.specify/extensions/featureline/scripts/`:
`build.sh`, `e2e.sh <feature> [tag]`, `boot-devices.sh`, `smoke.sh`,
`setup-check.sh`, `find-app-ids.sh`, `setup-flows.sh`, `log.sh <script>`.

Configuration lives in `.specify/extensions/featureline/featureline-config.yml`
(app ids, build commands). Setup writes it; edit it freely. A
`featureline-config.local.yml` next to it overrides per machine, and
`SPECKIT_FEATURELINE_IOS_BUNDLE_ID` / `_ANDROID_PACKAGE` / `_BUILD_IOS` /
`_BUILD_ANDROID` override everything.

## What it touches

- **Reads**: `specs/**`, `.specify/memory/constitution.md`, `package.json`,
  `app.json` / `app.config.*`, native project files for app ids, the git diff.
- **Writes**: `specs/briefs/`, `specs/<NNN>/` (decisions, critiques, flows
  report, testids, review, Maestro results), `.maestro/`, the constitution
  (appends approved rules; drafts to `constitution-draft.md`), its own config file.
- **Runs**: your build commands, `maestro test`, `xcrun simctl`, `adb`,
  `emulator`, `npm test`. No network calls of its own beyond what those make.
- **Never**: merges, pushes, edits a flow file to make it pass, or writes
  `constitution.md` from a draft without you.

## Design rules baked in

- The spec never names a technology. Tech lives in the constitution and the plan.
- Every decision shows what it rejected.
- Critics read every artifact before you do; you decide.
- E2E flows come from the spec, before the code, and are never edited to pass.
- The review runs on both platforms and checks scope, not style.
- The pipeline never merges.

## Develop

```bash
./scripts/validate.sh                              # manifest, commands, workflow, scripts
specify extension add --dev ./featureline-ext --force   # reinstall after editing
```

CI runs the same validator plus a real `specify extension add` and
`specify workflow add` + `info` on every pull request.

## Release

1. Bump `version` in `featureline-ext/extension.yml` and
   `featureline-workflow/workflow.yml`, add a section to `CHANGELOG.md`.
   Every content change needs a bump - `specify extension update` is
   version-driven, so an unbumped change never reaches installed copies.
   CI refuses a PR that touches `featureline-ext/` without one.
2. Push `main` first, then the tag: `git push && git tag vX.Y.Z && git push --tags`.
3. CI checks the tag matches the manifest, zips both packages with the
   manifest at the archive root, and publishes a GitHub Release with the
   changelog section as notes.
4. CI then commits `catalog/extensions.json` and `catalog/workflows.json`
   pointing at the release to `main`. Run `git pull` before your next push.

To list on the community catalog, open an
[extension submission](https://github.com/github/spec-kit/issues/new?template=extension_submission.yml)
pointing at the release zip.

## License

MIT
