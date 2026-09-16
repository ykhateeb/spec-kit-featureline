#!/usr/bin/env bash
# Run a script with its output also appended to .maestro/setup.log. Workflow shell steps capture
# stdout and print nothing until they finish, so `tail -f .maestro/setup.log` is the live view.
# Keeps the script's stdout and exit code, so step output and exit_code conditions are unchanged.
set -o pipefail
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
mkdir -p .maestro
L=.maestro/setup.log
start=$(date +%s)
echo "== $(date '+%F %T') start: $*" >> "$L"
"$@" 2>&1 | tee -a "$L"
rc=$?
echo "== $(date '+%F %T') exit $rc after $(( $(date +%s) - start ))s: $*" >> "$L"
exit $rc
