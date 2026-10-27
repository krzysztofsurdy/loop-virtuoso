#!/bin/bash
# /init-setup scaffolds the self-improve workspace in the plugin's persistent
# space, idempotently, recording the capture opt-in.

si_home_path() { echo "$XDG_STATE_HOME/code-virtuoso/self-improve"; }

test_init_setup_creates_workspace() {
  bash "$SCRIPTS/init-setup.sh" >/dev/null
  local si; si="$(si_home_path)"
  assert_file "$si/learnings"
  assert_file "$si/signals.jsonl"
  assert_file "$si/config.json"
  assert_eq "$(jq -r '.capture.enabled' "$si/config.json")" "true" "capture defaults on"
  assert_eq "$(jq -r '.capture.retryThreshold' "$si/config.json")" "3" "retry default"
}

test_init_setup_preserves_learnings_and_merges() {
  bash "$SCRIPTS/init-setup.sh" >/dev/null
  local si; si="$(si_home_path)"
  echo "keep me" > "$si/learnings/x.md"
  bash "$SCRIPTS/init-setup.sh" --capture off --retry 5 >/dev/null
  assert_eq "$(cat "$si/learnings/x.md")" "keep me" "learning preserved"
  assert_eq "$(jq -r '.capture.enabled' "$si/config.json")" "false" "capture toggled off"
  assert_eq "$(jq -r '.capture.retryThreshold' "$si/config.json")" "5" "retry updated"
}

test_init_setup_rejects_bad_flag() {
  local out rc=0
  out="$(bash "$SCRIPTS/init-setup.sh" --capture maybe 2>&1)" || rc=$?
  assert_eq "$rc" "2" "bad value exits 2"
  assert_contains "$out" "on or off" "explains the valid values"
}
