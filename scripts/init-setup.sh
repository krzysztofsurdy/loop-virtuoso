#!/bin/bash
# Scaffold the self-improvement workspace in the plugin's persistent space.
#
#   init-setup.sh [--capture on|off] [--retry N]
#
# Idempotent: it never clobbers existing learnings, and it merges the given
# flags into config.json, preserving earlier choices for flags not passed.
# Writes only inside the self-improve workspace. Exits 0 on success, 2 on error.
set -Eeuo pipefail
trap 'echo "init-setup: error at line $LINENO" >&2; exit 2' ERR

LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/lib" && pwd -P)"
# shellcheck source=/dev/null
source "$LIB_DIR/config.sh"
# shellcheck source=/dev/null
source "$LIB_DIR/self-improve.sh"

capture="" retry=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --capture) capture="$2"; shift 2 ;;
    --retry) retry="$2"; shift 2 ;;
    *) echo "init-setup: unknown argument '$1'" >&2; exit 2 ;;
  esac
done

onoff() { case "$1" in on|true|yes) echo true ;; off|false|no) echo false ;; *) echo "" ;; esac }

home="$(si_home)"
learnings="$(si_learnings_dir)"
signals="$(si_signals_file)"
config="$(si_config_file)"

mkdir -p "$learnings"
[[ -f "$signals" ]] || : > "$signals"

# Merge flags into existing config, keeping prior values for anything not passed.
# Default on a first run: capture on (record on the go).
existing="$(si_config)"
cap_val=""; [[ -n "$capture" ]] && cap_val="$(onoff "$capture")"
[[ -n "$capture" && -z "$cap_val" ]] && { echo "init-setup: --capture takes on or off" >&2; exit 2; }

merged="$(printf '%s' "$existing" | jq \
  --arg cap "$cap_val" --arg retry "$retry" '
  def setbool($cur; $flag; $default): if $flag == "" then ($cur // $default) else ($flag == "true") end;
  def setnum($cur; $flag; $default): if $flag == "" then ($cur // $default) else ($flag | tonumber) end;
  {
    capture: {
      enabled: setbool(.capture.enabled; $cap; true),
      retryThreshold: setnum(.capture.retryThreshold; $retry; 3)
    }
  }')"

tmp="$(mktemp "${TMPDIR:-/tmp}/si-config.XXXXXX")"
printf '%s\n' "$merged" > "$tmp"
mv "$tmp" "$config"

if [[ ! -f "$home/README.md" ]]; then
  cat > "$home/README.md" <<'EOF'
# loop-virtuoso self-improvement workspace

What the loop learns across runs. It lives here, in the plugin's persistent
space, so a plugin update never deletes it. Nothing here is applied
automatically: signals are recorded on the go, `/loop-virtuoso:improve` reviews
them, and a human commits the ones worth keeping into a repo.

- `learnings/`  one markdown file per learning (frontmatter + body). The schema
  is in the plugin's learning-store skill reference.
- `signals.jsonl`  raw signals captured during runs (append-only). Not learnings
  yet: `/improve` applies the durability test before any becomes one.
- `config.json`  the capture opt-in set at `/init-setup`.
EOF
fi

cap_state="$(printf '%s' "$merged" | jq -r '.capture.enabled')"
echo "Self-improve workspace ready at: $home"
echo "  learnings/        $([[ -d "$learnings" ]] && echo present)"
echo "  signals.jsonl     $([[ -f "$signals" ]] && echo present)"
echo "  config.json       capture=$cap_state"
echo "Existing learnings are preserved. Re-run to change the opt-in."
