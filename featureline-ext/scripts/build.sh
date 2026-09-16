#!/usr/bin/env bash
# Build and install the app on every booted device.
# Reads featureline-config.yml via config.sh.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
source "$(dirname "$0")/config.sh"

built=0
if xcrun simctl list devices booted 2>/dev/null | grep -q Booted; then
  echo "== build iOS: $BUILD_IOS"
  bash -c "$BUILD_IOS"
  xcrun simctl listapps booted | grep -q "$IOS_BUNDLE_ID" || { echo "iOS: $IOS_BUNDLE_ID not installed after build"; exit 1; }
  built=1
fi
# Pin adb to ANDROID_SERIAL if it's online, else the first online device; a stale "offline" entry makes bare adb fail with "more than one device".
ANDROID_SERIAL=$(adb devices 2>/dev/null | awk -v s="${ANDROID_SERIAL:-}" 'NR>1 && $2=="device" && (s=="" || $1==s){print $1; exit}' || true)
if [ -n "$ANDROID_SERIAL" ]; then
  export ANDROID_SERIAL
  echo "== build Android: $BUILD_ANDROID"
  bash -c "$BUILD_ANDROID"
  adb shell pm list packages | grep -q "$ANDROID_PACKAGE" || { echo "Android: $ANDROID_PACKAGE not installed after build"; exit 1; }
  built=1
fi
[ "$built" = 1 ] || { echo "No device booted. Run /pipeline-setup maestro."; exit 2; }
echo "== build ok"
