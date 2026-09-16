#!/usr/bin/env bash
# Source this from any featureline script. Loads featureline-config.yml (project copy next to
# this scripts/ folder) and exports IOS_BUNDLE_ID, ANDROID_PACKAGE, BUILD_IOS, BUILD_ANDROID.
# Precedence (lowest -> highest): template defaults, featureline-config.yml,
# featureline-config.local.yml, SPECKIT_FEATURELINE_* environment variables.
EXT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_FILE="$EXT_DIR/featureline-config.yml"
CONFIG_LOCAL="$EXT_DIR/featureline-config.local.yml"
CONFIG_TEMPLATE="$EXT_DIR/featureline-config.template.yml"

eval "$(python3 - "$CONFIG_TEMPLATE" "$CONFIG_FILE" "$CONFIG_LOCAL" <<'PY'
import sys, os, shlex
def load(p):
    if not os.path.exists(p): return {}
    try:
        import yaml
        return yaml.safe_load(open(p)) or {}
    except ImportError:
        # minimal fallback: key: "value" pairs under 2-level sections
        d, sec = {}, None
        for line in open(p):
            s = line.split('#',1)[0].rstrip()
            if not s.strip(): continue
            if not s.startswith(' '): sec = s.rstrip(':'); d[sec] = {}
            elif sec and ':' in s:
                k, v = s.strip().split(':',1); d[sec][k.strip()] = v.strip().strip('"').strip("'")
        return d
cfg = {}
for p in sys.argv[1:]:
    for sec, vals in load(p).items():
        cfg.setdefault(sec, {}).update(vals or {})
def get(sec, key, env):
    return os.environ.get(env) or cfg.get(sec, {}).get(key, "")
print("export IOS_BUNDLE_ID=%s"   % shlex.quote(get('ios','bundle_id','SPECKIT_FEATURELINE_IOS_BUNDLE_ID')))
print("export ANDROID_PACKAGE=%s" % shlex.quote(get('android','package','SPECKIT_FEATURELINE_ANDROID_PACKAGE')))
print("export BUILD_IOS=%s"       % shlex.quote(get('build','ios','SPECKIT_FEATURELINE_BUILD_IOS')))
print("export BUILD_ANDROID=%s"   % shlex.quote(get('build','android','SPECKIT_FEATURELINE_BUILD_ANDROID')))
PY
)"
export CONFIG_FILE
