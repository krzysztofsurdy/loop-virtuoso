#!/bin/bash
# Signal capture records retry/verify-fail signals deterministically, dedupes by
# (kind, ref), honors the opt-in, and emits a retro marker on --close.

si_signals() { echo "$XDG_STATE_HOME/code-virtuoso/self-improve/signals.jsonl"; }

# seed_run <repo>: a backlog plus state where ITEM-001/s1 is over the retry
# threshold and ITEM-002/s1 has two failed verdicts in the event log.
seed_run() {
  local repo="$1" state events
  write_backlog "$repo" feat/x
  state="$(loop_dir "$repo")/state"
  mkdir -p "$state"
  jq -n '{version:1, items:{"ITEM-001":{s1:{status:"pending",attempts:4,notes:"boom"}}}}' > "$state/state.json"
  : > "$state/events.jsonl"
  local f; f="$(loop_dir "$repo")/backlog.json"
  jq -nc '{ts:"t",event:"step_verdict",itemId:"ITEM-002",stepId:"s1",action:"stalled"}' >> "$state/events.jsonl"
  jq -nc '{ts:"t",event:"step_verdict",itemId:"ITEM-002",stepId:"s1",action:"stalled"}' >> "$state/events.jsonl"
}

test_capture_records_retry_and_verify_fail() {
  local repo; repo="$(mk_repo)"
  bash "$SCRIPTS/init-setup.sh" >/dev/null   # capture on
  seed_run "$repo"
  bash "$SCRIPTS/capture.sh" "$(loop_dir "$repo")/backlog.json"
  local sig; sig="$(si_signals)"
  assert_file "$sig"
  assert_eq "$(jq -s '[.[]|select(.kind=="retry" and .ref=="ITEM-001/s1")]|length' "$sig")" "1" "one retry signal"
  assert_eq "$(jq -s '[.[]|select(.kind=="verify-fail" and .ref=="ITEM-002/s1")]|length' "$sig")" "1" "one verify-fail signal"
}

test_capture_dedupes_on_repeat() {
  local repo; repo="$(mk_repo)"
  bash "$SCRIPTS/init-setup.sh" >/dev/null
  seed_run "$repo"
  bash "$SCRIPTS/capture.sh" "$(loop_dir "$repo")/backlog.json"
  bash "$SCRIPTS/capture.sh" "$(loop_dir "$repo")/backlog.json"
  local sig; sig="$(si_signals)"
  assert_eq "$(jq -s '[.[]|select(.kind=="retry")]|length' "$sig")" "1" "retry not duplicated"
}

test_capture_noop_when_disabled() {
  local repo; repo="$(mk_repo)"
  bash "$SCRIPTS/init-setup.sh" --capture off >/dev/null
  seed_run "$repo"
  bash "$SCRIPTS/capture.sh" "$(loop_dir "$repo")/backlog.json"
  local sig; sig="$(si_signals)"
  assert_eq "$([[ -s "$sig" ]] && echo nonempty || echo empty)" "empty" "no signals when capture off"
}

test_capture_close_emits_retro() {
  local repo; repo="$(mk_repo)"
  bash "$SCRIPTS/init-setup.sh" >/dev/null
  seed_run "$repo"
  bash "$SCRIPTS/capture.sh" "$(loop_dir "$repo")/backlog.json" --close
  local sig; sig="$(si_signals)"
  assert_eq "$(jq -s '[.[]|select(.kind=="retro")]|length' "$sig")" "1" "one retro marker"
}
