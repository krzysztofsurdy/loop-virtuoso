#!/bin/bash
# Print the resolved self-improve workspace paths, one per line as key=value.
# Read-only. Used by /improve so it never hardcodes a home.
set -Eeuo pipefail
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/lib" && pwd -P)"
# shellcheck source=/dev/null
source "$LIB_DIR/config.sh"
# shellcheck source=/dev/null
source "$LIB_DIR/self-improve.sh"
echo "home=$(si_home)"
echo "learnings=$(si_learnings_dir)"
echo "signals=$(si_signals_file)"
echo "config=$(si_config_file)"
