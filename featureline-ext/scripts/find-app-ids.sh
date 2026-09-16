#!/usr/bin/env bash
# Detect bundle id / package and build commands. Writes featureline-config.yml (project copy) if missing.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
EXT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ENV="$EXT_DIR/featureline-config.yml"
if [ -f "$ENV" ]; then echo "featureline-config.yml exists - keeping it:"; cat "$ENV"; exit 0; fi
ios=""; and=""
if [ -f app.json ]; then
  ios=$(python3 -c "import json;d=json.load(open('app.json')).get('expo',{});print(d.get('ios',{}).get('bundleIdentifier',''))" 2>/dev/null || true)
  and=$(python3 -c "import json;d=json.load(open('app.json')).get('expo',{});print(d.get('android',{}).get('package',''))" 2>/dev/null || true)
fi
[ -z "$ios" ] && [ -f ios/*.xcodeproj/project.pbxproj ] 2>/dev/null && ios=$(grep -m1 PRODUCT_BUNDLE_IDENTIFIER ios/*.xcodeproj/project.pbxproj | sed 's/.*= *//; s/;.*//' | tr -d ' "')
[ -z "$and" ] && [ -f android/app/build.gradle ] && and=$(grep -m1 applicationId android/app/build.gradle | sed 's/.*applicationId *//; s/[" ]//g')
if grep -q '"expo"' package.json; then
  bi='npx expo run:ios --configuration Release --no-bundler'
  ba='npx expo run:android --variant release --no-bundler'
else
  bi='npx react-native run-ios --mode Release --no-packager'
  ba='npx react-native run-android --mode release --no-packager'
fi
cat > "$ENV" <<EOT
# Written by featureline-setup. Edit freely - it is never overwritten.
IOS_BUNDLE_ID="${ios:-SET_ME}"
ANDROID_PACKAGE="${and:-SET_ME}"
BUILD_IOS="$bi"
BUILD_ANDROID="$ba"
EOT
echo "wrote $ENV:"; cat "$ENV"
grep -q SET_ME "$ENV" && { echo "!! an app id was not found - edit $ENV before building"; exit 1; }
exit 0
