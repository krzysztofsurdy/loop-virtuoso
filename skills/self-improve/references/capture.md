# Signal capture

Capture is the on-the-go half of the compound loop. It is deterministic and runs
no model, so it is cheap and cannot be steered by content in a run. It only
records evidence; `/improve` decides what, if anything, a signal means.

## Contents

- [What a signal is](#what-a-signal-is)
- [When capture runs](#when-capture-runs)
- [What is recorded](#what-is-recorded)
- [What is not recorded](#what-is-not-recorded)

## What a signal is

A signal is one objective event observed from the loop's own state and event log,
appended as one line of JSON to `signals.jsonl`:

```json
{"ts":"2026-10-27T11:40:00Z","kind":"retry","ref":"ITEM-003/step-2","detail":"attempts=4 threshold=3"}
```

`kind` is the signal type, `ref` identifies the step or path, `detail` is a short
objective note. No prose, no judgment, no conclusion.

## When capture runs

Only when `capture.enabled` is true in the workspace config (set at
`/init-setup`, default on). It fires at iteration boundaries in Mode B
(`run-batch.sh`) and at stop in Mode A (`stop-hook.sh`), reading the current run's
`state.json` and `events.jsonl`. It de-duplicates against what it already
recorded for the run, so a step that stays over threshold is recorded once, not
every iteration.

## What is recorded

| kind | Trigger |
|---|---|
| `retry` | A step's `attempts` reached the retry threshold. |
| `verify-fail` | A step's verify command failed on two or more verdicts. |
| `retro` | At backlog completion, one summary marker so `/improve` runs a close-out pass. |

## What is not recorded

- Nothing from a step that passed on the first try.
- No file contents, diffs, secrets, or model output. Only the step/path
  reference and counts.
- No learning. A signal is not a learning until `/improve` applies the
  durability gate.
