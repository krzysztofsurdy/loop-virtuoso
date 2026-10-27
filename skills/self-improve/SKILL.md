---
name: self-improve
description: How loop-virtuoso learns across runs. The self-improvement workspace, the learning schema, the durability capture gate, how the loop reads learnings back, and the /improve review that turns captured signals into commit-ready proposals. Use when running /loop-virtuoso:improve, when the loop reads or writes learnings, or when explaining the compound loop.
user-invocable: false
---

# Self-improvement (the compound loop)

loop-virtuoso gets better across runs by writing down what a run taught it and
reading it back on the next run. The discipline that keeps this useful, rather
than a growing pile of noise, is a hard capture gate and a human-gated review.
Nothing is applied automatically.

The cycle has three deterministic, separable stages:

1. **Capture (on the go, no model).** During a run, the loop appends raw
   *signals* to `signals.jsonl` when something objective happens: a step retried
   past the threshold, a write-boundary violation was reverted, a verify command
   failed repeatedly. A signal is evidence, not a conclusion. See [capture.md](references/capture.md).
2. **Review (`/improve`, model, human-gated).** `/improve` reads the signals and
   the existing learnings, optionally researches current best practice, applies
   the durability gate, refreshes the store, and reports what is worth committing
   to a repo as a ready-to-apply diff. It never commits or wires anything itself.
   See [improve.md](references/improve.md).
3. **Read back (planning and execution).** `backlog-compiler` and the loop consult
   the learnings store, frontmatter-first, and flag a conflict with current code
   instead of letting a stale learning override present evidence.

## The hard boundary

The loop records candidates automatically; it never modifies its own live agents,
pipelines, or memory without a human applying the change. A loop that silently
rewrites what it runs has no independent check and is steerable by untrusted
content in a run. Capture is deterministic (no model on the hot path); judgment
lives only in `/improve`; application lives only with a human.

## The durability gate

A signal becomes a learning only if it passes the counterfactual test:

> If this note vanished, would a future run repeat the mistake or redo
> substantial investigation?

If the answer is no, because the reasoning is already recoverable from the final
code, tests, or docs, it is dropped with a reason. Completion, effort, and diff
size never qualify a learning on their own. One learning per concern; batching a
run's whole story into one note is refused.

## Workspace

Set up by `/loop-virtuoso:init-setup`, in the plugin's persistent space so a
plugin update never deletes it:

```
${CLAUDE_PLUGIN_DATA}/self-improve/   (falls back to the plugin state home outside the runtime)
  learnings/      one markdown file per learning (frontmatter + body)
  signals.jsonl   raw captured signals, append-only
  config.json     the capture opt-in (default on)
```

## Reference Files

| Reference | When to open |
|---|---|
| [schema.md](references/schema.md) | Writing or reading a learning file: the frontmatter fields, the bug and knowledge tracks, and `retire_when` |
| [improve.md](references/improve.md) | Running `/improve`: the durability gate, frontmatter-first retrieval, the 5-outcome refresh, and the commit-ready output |
| [capture.md](references/capture.md) | Understanding or extending what the loop records as a signal |
