#!/usr/bin/env bash
# Create shared _setup flows if missing. Never overwrites.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
mkdir -p .maestro/_setup
[ -f .maestro/_setup/clear-state.yaml ] || cat > .maestro/_setup/clear-state.yaml <<'EOT'
appId: ${APP_ID}
name: setup - fresh install state
---
- launchApp:
    clearState: true
    clearKeychain: true
EOT
if grep -qiE 'auth|login|signin|clerk|supabase|firebase' package.json && [ ! -f .maestro/_setup/login.yaml ]; then
cat > .maestro/_setup/login.yaml <<'EOT'
appId: ${APP_ID}
name: setup - log in as the test user
---
- launchApp:
    clearState: true
# Fill in with your login screen's testIDs (constitution naming rule), then remove the # marks.
# - tapOn:
#     id: "auth.login.email"
# - inputText: ${TEST_EMAIL}
# - tapOn:
#     id: "auth.login.password"
# - inputText: ${TEST_PASSWORD}
# - tapOn:
#     id: "auth.login.submit"
# - assertVisible:
#     id: "home.screen"
EOT
echo "wrote login.yaml - fill in the testIDs"
fi
[ -f .maestro/README.md ] || cat > .maestro/README.md <<'EOT'
# Maestro E2E

- app ids and build commands live in `.specify/extensions/featureline/featureline-config.yml`. Edit freely.
- `_setup/` - shared flows: clear-state, login (fill in), smoke.
- `<NNN-feature>/` - one flow per acceptance criterion, written by the featureline workflow.
  Feature flows reference shared ones as `../_setup/<file>.yaml`.

Build:  `.specify/extensions/featureline/scripts/build.sh`
Run:    `.specify/extensions/featureline/scripts/e2e.sh <NNN-feature> [p1]`
Boot:   `.specify/extensions/featureline/scripts/boot-devices.sh`
EOT
ls -la .maestro/_setup
