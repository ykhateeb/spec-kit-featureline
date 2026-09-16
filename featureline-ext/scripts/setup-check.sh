#!/usr/bin/env bash
# Toolchain check. Prints one line per item: ok / missing + fix. Exit 1 if anything is missing.
# Writes the same report to .maestro/setup-report.txt for the gate to show.
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
mkdir -p .maestro
R=.maestro/setup-report.txt; : > "$R"; MISSING=0
say() { echo "$*" | tee -a "$R"; }
chk() { # label, test-cmd, fix
  if bash -c "$2" >/dev/null 2>&1; then say "ok       $1"; else say "MISSING  $1"; say "         fix: $3"; MISSING=1; fi
}
say "== featureline setup check ($(date +%F))"
chk "Spec Kit project (.specify/)"      "test -d .specify" \
    "uvx --from git+https://github.com/github/spec-kit.git specify init . --integration claude"
# Constitution is drafted at the end of setup mode, so it is reported but never counted as missing.
if test -f .specify/memory/constitution.md && ! grep -q '\[PROJECT_NAME\]' .specify/memory/constitution.md; then
  say "ok       constitution written"
else
  say "later    constitution written (setup mode drafts it in its last step)"
fi
# Test script: added automatically when package.json has none (jest if installed, else a no-op placeholder).
HAS_TEST="node -e \"process.exit(require('./package.json').scripts?.test ? 0 : 1)\""
if test -f package.json && ! bash -c "$HAS_TEST" >/dev/null 2>&1; then
  if test -x node_modules/.bin/jest; then T=jest; else T="echo 'no unit tests yet'"; fi
  npm pkg set "scripts.test=$T" >/dev/null 2>&1 && say "added    package.json test script: $T"
fi
chk "package.json test script"          "$HAS_TEST" "add a test script to package.json"
chk "Maestro CLI"                        "command -v maestro" "curl -Ls https://get.maestro.mobile.dev | bash  (then restart the shell)"
chk "Java"                               "command -v java" "brew install openjdk@17"
if [ "$(uname)" = Darwin ]; then
chk "Xcode CLI tools (simctl)"           "xcrun simctl help" "xcode-select --install"
else
say "skip     iOS (not macOS)"
fi
chk "adb on PATH"                        "command -v adb" "export ANDROID_HOME=~/Library/Android/sdk; add \$ANDROID_HOME/platform-tools and \$ANDROID_HOME/emulator to PATH"
chk "Android emulator on PATH"           "command -v emulator" "same as adb - add \$ANDROID_HOME/emulator to PATH"
chk "at least one Android AVD"           "emulator -list-avds | grep -q ." "Android Studio -> Device Manager -> Create device (Pixel 7, latest stable API)"
say "== $([ $MISSING = 0 ] && echo 'all ok' || echo 'fix the MISSING lines, then resume')"
exit $MISSING
