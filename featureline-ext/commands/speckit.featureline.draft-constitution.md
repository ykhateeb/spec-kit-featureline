---
description: Draft a constitution starter from what the repo already does; writes constitution-draft.md, never constitution.md
handoffs:
- label: Write the constitution from the draft
  agent: speckit.constitution
  prompt: Use .specify/memory/constitution-draft.md as the basis. Keep every rule that is true for this repo.
---

# Constitution draft

## User Input

```text
$ARGUMENTS
```

Draft a project constitution starter for this React Native repo and write it
to `.specify/memory/constitution-draft.md`. Read `package.json`,
`tsconfig.json`, the top-level folder layout, and any lint config first. Only
state rules the repo already follows; do not invent rules for tools that are
not installed. Plain, simple English, one rule per line, written so an agent
can enforce it.

Cover:

- language and strictness
- state and data layer
- navigation
- folder structure
- testing - every feature ships with unit tests for logic and one Maestro flow
  per acceptance criterion of its P1 and P2 stories, written before
  implementation, under `.maestro/<feature>/`
- testIDs - every tappable or typable element and every screen root has a
  testID named `<feature>.<screen>.<element>`; flows select by testID only,
  never by visible text
- test hooks - any state a flow needs is created through a hook decided in the
  feature's `decisions.md`
- E2E devices - flows run on iOS simulator and Android emulator through the
  featureline scripts; a feature is not done until p1 flows pass on both
- localisation, if an i18n package is present
- dependencies - none added without a one-line reason in `decisions.md`
- offline, only if a persist package is present

Do not write `constitution.md` itself. The user runs
`__SPECKIT_COMMAND_CONSTITUTION__` with the draft - the constitution is the one
file they write themselves.

## Non-interactive use

When invoked by the featureline workflow there is no human to ask. Never stop to
ask a question; write the artifact, print the end-of-reply summary, and finish.
