#!/bin/bash
# Record on-the-go signals for the compound loop. Deterministic, no model.
#
#   capture.sh <backlog_file> [--close]
#
# Reads the run's state (step attempts) and event log (verify verdicts) and
# appends new signals to the self-improve workspace, de-duplicated by (kind, ref)
# so a persistent condition is recorded once, not every iteration. With --close
# it also records one retro marker at backlog completion.
#
# Best-effort: it must never break the loop, so any error ends capture quietly
# (exit 0) after a note to stderr. Does nothing unless capture is opted in.
set -Eeuo pipefail
trap 'echo "capture: skipped on error at line $LINENO" >&2; exit 0' ERR

LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/lib" && pwd -P)"
# shellcheck source=/dev/null
source "$LIB_DIR/config.sh"
# shellcheck source=/dev/null
source "$LIB_DIR/self-improve.sh"
# shellcheck source=/dev/null
source "$LIB_DIR/backlog.sh"
# shellcheck source=/dev/null
source "$LIB_DIR/events.sh"

backlog="" close=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --close) close=true; shift ;;
    *) backlog="$1"; shift ;;
  esac
done

si_capture_enabled || exit 0
[[ -n "$backlog" && -f "$backlog" ]] || exit 0

signals_file="$(si_signals_file)"
mkdir -p "$(si_home)"

# record_once <kind> <ref> <detail>: append unless (kind, ref) is already present.
record_once() {
  local kind="$1" ref="$2" detail="$3"
  if [[ -f "$signals_file" ]] && \
     jq -se --arg k "$kind" --arg r "$ref" 'any(.[]?; .kind == $k and .ref == $r)' \
        "$signals_file" >/dev/null 2>&1; then
    return 0
  fi
  si_record_signal "$kind" "$ref" "$detail"
}

threshold="$(si_retry_threshold)"

# retry: a step whose attempts reached the threshold.
view="$(backlog_view "$backlog" 2>/dev/null || echo '{}')"
while IFS=$'\t' read -r ref attempts; do
  [[ -z "$ref" ]] && continue
  record_once "retry" "$ref" "attempts=$attempts threshold=$threshold"
done < <(printf '%s' "$view" | jq -r --argjson t "$threshold" \
  '.items[]? | .id as $i | .steps[]? | select((.attempts // 0) >= $t) | "\($i)/\(.id)\t\(.attempts)"' 2>/dev/null)

# verify-fail: a step with two or more non-verified verdicts in the event log.
events="$(events_path_for "$backlog")"
if [[ -f "$events" ]]; then
  while IFS=$'\t' read -r ref count; do
    [[ -z "$ref" ]] && continue
    record_once "verify-fail" "$ref" "failed_verdicts=$count"
  done < <(jq -rs \
    '[ .[] | select(.event == "step_verdict" and (.action // "") != "verified") ]
     | group_by((.itemId // "?") + "/" + (.stepId // "?"))
     | .[] | select(length >= 2)
     | "\((.[0].itemId // "?"))/\((.[0].stepId // "?"))\t\(length)"' "$events" 2>/dev/null)
fi

# retro: one close-out marker so /improve runs a summary pass for the run.
if $close; then
  record_once "retro" "backlog:$(basename "$(dirname "$(dirname "$backlog")")")" "run completed"
fi

exit 0
