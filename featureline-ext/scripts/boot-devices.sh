#!/usr/bin/env bash
# Boot the newest iPhone simulator (macOS) and the first Android AVD, if not already running.
set -uo pipefail
if [ "$(uname)" = Darwin ] && command -v xcrun >/dev/null; then
  if xcrun simctl list devices booted | grep -q Booted; then
    echo "ios: already booted"
  else
    dev=$(xcrun simctl list devices available | grep -E 'iPhone' | tail -1 | sed -E 's/^ *(.*) \(([0-9A-F-]{36})\).*/\2/')
    [ -n "$dev" ] && { xcrun simctl boot "$dev" && open -a Simulator && echo "ios: booted $dev"; } || echo "ios: no available iPhone simulator"
  fi
fi
if command -v adb >/dev/null; then
  if adb devices | awk 'NR>1 && $2=="device"' | grep -q .; then
    echo "android: already running"
  else
    avd=$(emulator -list-avds 2>/dev/null | head -1)
    if [ -n "$avd" ]; then
      nohup emulator -avd "$avd" -no-snapshot-load >/dev/null 2>&1 &
      adb wait-for-device
      for i in $(seq 1 30); do export ANDROID_SERIAL=$(adb devices | awk 'NR>1 && $2=="device"{print $1; exit}'); [ -n "$ANDROID_SERIAL" ] && break; sleep 2; done
      for i in $(seq 1 60); do [ "$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = 1 ] && break; sleep 2; done
      echo "android: booted $avd"
    else
      echo "android: no AVD - create one in Android Studio"
    fi
  fi
fi
adb devices 2>/dev/null; xcrun simctl list devices booted 2>/dev/null | grep Booted || true
