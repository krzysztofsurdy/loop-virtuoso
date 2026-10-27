#!/bin/bash
# Self-improvement workspace: paths and config for the compound loop.
#
# The workspace holds what the loop learns across runs. It lives in the
# plugin's own persistent space so a plugin update never deletes it:
#
#   ${CLAUDE_PLUGIN_DATA:-$(cv_state_home)/self-improve}/
#     learnings/      one markdown file per learning (frontmatter + body)
#     signals.jsonl   raw signals captured on the go (append-only)
#     config.json     feature opt-ins recorded at /init-setup
#     README.md       what the store is and how it is used
#
# CLAUDE_PLUGIN_DATA is set by Claude Code when the plugin runs. Outside that
# runtime (tests, manual use) it falls back to the plugin's own state home, so
# every script resolves the same workspace either way.

# shellcheck source=/dev/null
_SI_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
if ! declare -f cv_state_home >/dev/null 2>&1; then
  source "$_SI_LIB_DIR/config.sh"
fi

# si_home: the self-improve workspace root.
si_home() {
  echo "${CLAUDE_PLUGIN_DATA:-$(cv_state_home)/self-improve}"
}

si_learnings_dir() { echo "$(si_home)/learnings"; }
si_signals_file()  { echo "$(si_home)/signals.jsonl"; }
si_config_file()   { echo "$(si_home)/config.json"; }

# si_config: the workspace config as JSON ({} when absent or invalid).
si_config() {
  local f
  f="$(si_config_file)"
  if [[ -f "$f" ]] && jq empty "$f" >/dev/null 2>&1; then cat "$f"; else echo '{}'; fi
}

# si_config_get <jq-path> <default>: read one value, printing the default when
# the key is absent or null.
si_config_get() {
  local path="$1" default="$2"
  si_config | jq -r "($path) // \"$default\"" 2>/dev/null || echo "$default"
}

# si_capture_enabled: true when on-the-go signal capture is opted in.
si_capture_enabled() {
  [[ "$(si_config_get '.capture.enabled' 'false')" == "true" ]]
}

# si_retry_threshold: attempts on one step before it becomes a signal.
si_retry_threshold() {
  si_config_get '.capture.retryThreshold' '3'
}

# si_record_signal <kind> <ref> <detail>: append one raw signal, newline-delimited
# JSON, to signals.jsonl. Deterministic and cheap: no model, no judgment. The
# durability decision is deferred to /improve. Never fails the caller.
si_record_signal() {
  local kind="$1" ref="$2" detail="$3" dir
  si_capture_enabled || return 0
  dir="$(si_home)"
  mkdir -p "$dir" 2>/dev/null || return 0
  jq -nc --arg k "$kind" --arg r "$ref" --arg d "$detail" --arg t "$(si_now)" \
    '{ts: $t, kind: $k, ref: $r, detail: $d}' >> "$dir/signals.jsonl" 2>/dev/null || return 0
  return 0
}

# si_now: an ISO-8601 UTC timestamp, or empty when date is unavailable.
si_now() {
  date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo ""
}
