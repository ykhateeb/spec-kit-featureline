#!/usr/bin/env bash
# Prove Maestro -> device -> installed app works on every booted device.
set -uo pipefail
cd "$(git rev-parse --show-toplevel)"
source "$(dirname "$0")/config.sh"
mkdir -p .maestro/_setup
[ -f .maestro/_setup/smoke.yaml ] || cat > .maestro/_setup/smoke.yaml <<'EOT'
appId: ${APP_ID}
name: smoke - app launches
---
- launchApp:
    clearState: true
- waitForAnimationToEnd
EOT
FAIL=0
ios=$(xcrun simctl list devices booted 2>/dev/null | grep -oE '[0-9A-F-]{36}' | head -1 || true)
and=$(adb devices 2>/dev/null | awk 'NR>1 && $2=="device"{print $1; exit}' || true)
[ -n "$ios" ] && { maestro --device "$ios" test -e APP_ID="$IOS_BUNDLE_ID" .maestro/_setup/smoke.yaml && echo "SMOKE PASS ios" || { echo "SMOKE FAIL ios"; FAIL=1; }; }
[ -n "$and" ] && { maestro --device "$and" test -e APP_ID="$ANDROID_PACKAGE" .maestro/_setup/smoke.yaml && echo "SMOKE PASS android" || { echo "SMOKE FAIL android"; FAIL=1; }; }
[ -z "$ios$and" ] && { echo "NO DEVICE BOOTED"; exit 2; }
exit $FAIL
