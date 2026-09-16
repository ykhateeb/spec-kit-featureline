#!/usr/bin/env bash
# Run Maestro flows for one feature on every booted device.
# Usage: .maestro/scripts/e2e.sh <feature-dir> [tag]
#   feature-dir  e.g. 003-refund-request   (folder name under specs/ and .maestro/)
#   tag          optional, e.g. p1 - only flows with that tag
# Writes specs/<feature>/maestro-<platform>.xml and maestro-summary.txt.
# Exit 0 all pass, 1 any fail, 2 no device booted.
set -uo pipefail
cd "$(git rev-parse --show-toplevel)"
source "$(dirname "$0")/config.sh"

FEATURE="${1:?feature dir required}"
TAG="${2:-}"
FLOWS=".maestro/$FEATURE"
OUT="specs/$FEATURE"
SUMMARY="$OUT/maestro-summary.txt"
[ -d "$FLOWS" ] || { echo "No flows at $FLOWS"; exit 1; }
mkdir -p "$OUT"
: > "$SUMMARY"
FAIL=0
TAGARG=()
[ -n "$TAG" ] && TAGARG=(--include-tags "$TAG")

run_platform() {
  local platform="$1" app_id="$2" device="$3"
  echo "== $platform ($device) tag=${TAG:-all}" | tee -a "$SUMMARY"
  if maestro --device "$device" test -e APP_ID="$app_id" ${TAGARG[@]+"${TAGARG[@]}"} \
       --format junit --output "$OUT/maestro-$platform.xml" "$FLOWS" >> "$SUMMARY" 2>&1; then
    echo "PASS $platform" | tee -a "$SUMMARY"
  else
    echo "FAIL $platform" | tee -a "$SUMMARY"
    FAIL=1
  fi
}

IOS_DEV="$(xcrun simctl list devices booted 2>/dev/null | grep -oE '[0-9A-F-]{36}' | head -1 || true)"
AND_DEV="$(adb devices 2>/dev/null | awk -v s="${ANDROID_SERIAL:-}" 'NR>1 && $2=="device" && (s=="" || $1==s){print $1; exit}' || true)"

[ -n "$IOS_DEV" ] && run_platform ios "$IOS_BUNDLE_ID" "$IOS_DEV"
[ -n "$AND_DEV" ] && run_platform android "$ANDROID_PACKAGE" "$AND_DEV"
if [ -z "$IOS_DEV$AND_DEV" ]; then
  echo "NO DEVICE BOOTED - run /pipeline-setup maestro" | tee -a "$SUMMARY"
  exit 2
fi
echo "== result: $([ "$FAIL" = 0 ] && echo PASS || echo FAIL)" | tee -a "$SUMMARY"
exit "$FAIL"
