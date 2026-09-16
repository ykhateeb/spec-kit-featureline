---
description: Fix the code after failing flows (fix e2e <dir>), a NOT READY review (fix review <dir>) or an analyze report (fix analyze <dir>); never edits flows
handoffs:
- label: Run the review
  agent: speckit.featureline.review-spec
  send: true
- label: Run analyze again
  agent: speckit.analyze
  send: true
---

# Fix

## User Input

```text
$ARGUMENTS
```

## Feature folder

If the user input names a folder under `specs/` (for example `003-refund-request`),
use it. Otherwise use the most recently modified `specs/[0-9]*/` folder. Call it
`FEATURE_DIR`.

## Mode

**`e2e`** - read `FEATURE_DIR/maestro-summary.txt` and the `maestro-*.xml`
files next to it. For each failing flow, find the failing step and classify:

- **A. code bug** - the tap worked, the assertion fails. Fix the code.
- **B. missing or misnamed testID** - element not found. `FEATURE_DIR/testids.md`
  is the source of truth: add the ID to the code. Never rename it in the flow.
- **C. spec ambiguity** - the flow expects something the plan put elsewhere.
  Do NOT fix. Write the reason under `## Blocked` in `maestro-summary.txt`
  and stop.
- **D. hook or environment** - a `_setup` step failed. Fix the `_setup` flow
  or the hook.

Fix A, B and D in the code. Never edit any file under `.maestro/<FEATURE_DIR>/`
except `_setup/`. Mark the related task in `tasks.md`.

**`review`** - read `FEATURE_DIR/review.md`. For every Missing or Partial
criterion, implement the missing behaviour following `tasks.md` and the
constitution. For every row under "Built but never asked for": remove it
unless `spec.md` now contains a story for it. Never edit flow files. Mark
tasks in `tasks.md`.

**`analyze`** - the last `__SPECKIT_COMMAND_ANALYZE__` run reported
inconsistencies. Fix them in `spec.md` or `plan.md` only. Never edit `tasks.md`
by hand - it will be regenerated. If a fix changes an acceptance criterion,
re-run `__SPECKIT_COMMAND_FEATURELINE_WRITE-FLOWS__` for that story.

After any code fix, rebuild with `.specify/extensions/featureline/scripts/build.sh`
before re-running flows.

## Non-interactive use

When invoked by the featureline workflow there is no human to ask. Never stop to
ask a question; write the artifact, print the end-of-reply summary, and finish.
