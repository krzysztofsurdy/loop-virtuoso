---
description: "Scaffold the self-improvement workspace in the plugin's persistent space (survives updates): the learnings store and on-the-go signal capture. The capture opt-in is decided here."
allowed-tools: ["Bash(${CLAUDE_PLUGIN_ROOT}/scripts/init-setup.sh:*)"]
---

# Self-improve: init setup

Set up loop-virtuoso's self-improvement workspace. It lives in the plugin's own
persistent space, so a plugin update never deletes it. One opt-in is decided
here and can be changed by re-running this command:

- **Signal capture** (`capture`, default on): the loop records raw signals on the
  go (a step retried past the threshold, a recurring verify failure). Recording
  is deterministic and cheap; nothing is judged or applied automatically.
  `/loop-virtuoso:improve` reviews the signals later.

Unless the user already said otherwise, keep capture on. Then run the script,
passing a flag only when the user wants to change it:

```
${CLAUDE_PLUGIN_ROOT}/scripts/init-setup.sh [--capture on|off] [--retry N]
```

Omitted flags keep their current value (or the default on a first run). The
script is idempotent and never deletes existing learnings.

Relay the script's summary. Then, if capture is on, tell the user signals will
accumulate during loop runs and `/loop-virtuoso:improve` turns them into
reviewed, commit-ready proposals. Do not edit any learning or config file by
hand here; the script owns the workspace.
