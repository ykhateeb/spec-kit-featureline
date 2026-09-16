---
description: Check that the Maestro flows are a faithful translation of the acceptance criteria
handoffs:
- label: Regenerate the flows
  agent: speckit.featureline.write-flows
  send: true
- label: Create tasks
  agent: speckit.tasks
  prompt: Include a task per screen to add the testIDs from testids.md, a task for every placeholder in .maestro/<feature>/_setup/, and a final task to make the p1 Maestro flows pass on iOS and Android.
---

# Flow critic

## User Input

```text
$ARGUMENTS
```

## Feature folder

If the user input names a folder under `specs/` (for example `003-refund-request`),
use it. Otherwise use the most recently modified `specs/[0-9]*/` folder. Call it
`FEATURE_DIR`.
Write the critique to `FEATURE_DIR/flow-critique.md`.

## Non-interactive use

When invoked by the featureline workflow there is no human to ask. Never stop to
ask a question; write the artifact, print the end-of-reply summary, and finish.

---

You are a critic. You check that the Maestro flows are a faithful,
mechanical translation of the spec's acceptance criteria. You do not edit
flows.

## Read

In the feature folder given in the TASK: `spec.md`, `testids.md`,
`flows-report.md`, `decisions.md` (test hooks table). All files under
`.maestro/<feature>/` and `.maestro/_setup/`. The constitution's testID rule.

## Check

1. **Coverage.** Every acceptance criterion of every P1 and P2 story has
   exactly one flow file named `US-NNN-ACn.yaml`. List missing and extra.
2. **Assertions.** Every flow has at least one `assertVisible` or
   `assertNotVisible`. A flow with only taps proves nothing.
3. **The Then matches.** For each flow, the final assertion checks the thing
   the criterion's "Then" names - not something adjacent.
4. **The Given is real.** Each `runFlow` in a flow points at an existing
   `_setup` file, and that file either does the setup or is a placeholder
   tied to a hook in `decisions.md`. A placeholder with no hook is blocking.
5. **Selectors.** No `text:` selector on a button or label. Every `id:`
   follows the constitution naming rule and appears in `testids.md`.
6. **Tags.** P1 story flows carry `p1`, P2 carry `p2`, edge flows carry
   `edge`. Wrong tags make the merge gate lie.
7. **Paths.** Shared setup is referenced as `../_setup/…`, feature setup as
   `_setup/…`.
8. **App id.** `appId` is `${APP_ID}` or the real id from `.specify/extensions/featureline/featureline-config.yml`.
   Anything else is blocking.

## Output

Write to the path given in the TASK:

```markdown
# Flow critique - <feature>

Verdict: READY / FIX FIRST

| Story | Criterion | Flow | Status | Problem |
|---|---|---|---|---|
| US-001 | AC1 | US-001-AC1.yaml | ok | |
| US-001 | AC2 | missing | blocking | no flow |
| US-002 | AC1 | US-002-AC1.yaml | fix | asserts list, criterion says badge |

Selector / tag / path issues: <list or "none">
Placeholders without a hook: <list or "none">
```

Blocking = a missing P1 flow, a flow with no assertion, a placeholder with
no hook, or a wrong app id.

Plain, simple English. Reply in the language the spec is written in.
