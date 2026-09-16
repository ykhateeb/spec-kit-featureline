#!/usr/bin/env bash
# Local validation - the same checks CI runs. No Spec Kit needed.
set -euo pipefail
cd "$(dirname "$0")/.."
python3 - <<'PY'
import yaml, re, os, glob, sys
ok = True
def fail(msg):
    global ok; ok = False; print("FAIL", msg)

# ---- extension manifest
m = yaml.safe_load(open('featureline-ext/extension.yml'))
e = m['extension']
if m.get('schema_version') != "1.0": fail("schema_version must be '1.0'")
if not re.fullmatch(r'[a-z0-9-]+', e['id']): fail(f"bad extension id {e['id']}")
if not re.fullmatch(r'\d+\.\d+\.\d+', e['version']): fail(f"bad version {e['version']}")
names = set()
for c in m['provides']['commands']:
    if not re.fullmatch(r'speckit\.[a-z0-9-]+\.[a-z0-9-]+', c['name']): fail(f"bad command name {c['name']}")
    if c['name'].split('.')[1] != e['id']: fail(f"{c['name']} not namespaced to {e['id']}")
    if c['file'].startswith(('/', '..')) or not os.path.exists('featureline-ext/' + c['file']): fail(f"missing/invalid file {c['file']}")
    names.add(c['name'])
for s in m['provides'].get('scripts', []):
    if not re.fullmatch(r'[a-z0-9-]+', s['name']): fail(f"bad script name {s['name']}")
    if not os.path.exists('featureline-ext/' + s['file']): fail(f"missing script {s['file']}")
events = {'before_specify','after_specify','before_plan','after_plan','before_tasks','after_tasks','before_implement','after_implement','before_analyze','after_analyze','before_checklist','after_checklist','before_clarify','after_clarify','before_constitution','after_constitution'}
for ev, h in m.get('hooks', {}).items():
    if ev not in events: fail(f"unknown hook event {ev}")
    hs = h if isinstance(h, list) else [h]
    for x in hs:
        if x['command'] not in names: fail(f"hook {ev} -> unknown command {x['command']}")

# ---- command files: frontmatter, no literal slash invocations, handoff targets resolve
core = {'speckit.specify','speckit.clarify','speckit.plan','speckit.tasks','speckit.analyze','speckit.implement','speckit.constitution','speckit.checklist'}
for f in sorted(glob.glob('featureline-ext/commands/*.md')):
    txt = open(f).read()
    parts = txt.split('---')
    if len(parts) < 3: fail(f"{f}: no frontmatter"); continue
    fm = yaml.safe_load(parts[1])
    if 'description' not in fm: fail(f"{f}: no description")
    for h in fm.get('handoffs', []):
        if h['agent'] not in names | core: fail(f"{f}: handoff to unknown {h['agent']}")
    body = parts[2]
    if re.search(r'(?<![\w`.-])/speckit\.', body): fail(f"{f}: literal /speckit. invocation in body - use __SPECKIT_COMMAND_X__ tokens")
    for t in re.findall(r'__SPECKIT_COMMAND_[A-Z0-9_-]+__', body):
        if not re.fullmatch(r'__SPECKIT_COMMAND_[A-Z0-9-]+(_[A-Z0-9-]+)*__', t): fail(f"{f}: malformed token {t}")

# ---- workflow: parse, unique ids, no ':' in ids, every command step targets a known command
wf = yaml.safe_load(open('featureline-workflow/workflow.yml'))
if wf['workflow']['id'] != e['id']: fail("workflow id must equal extension id")
ids = []
def walk(steps):
    for s in steps:
        ids.append(s['id'])
        if ':' in s['id']: fail(f"step id contains ':' - {s['id']}")
        if 'command' in s and s['command'] not in names | core: fail(f"step {s['id']} -> unknown command {s['command']}")
        for k in ('steps', 'then', 'else', 'default'):
            if k in s: walk(s[k])
        if 'cases' in s:
            for st in s['cases'].values(): walk(st)
walk(wf['steps'])
dups = {i for i in ids if ids.count(i) > 1}
if dups: fail(f"duplicate step ids {dups}")

# ---- versions in sync
if wf['workflow']['version'] != e['version']: print(f"WARN workflow version {wf['workflow']['version']} != extension version {e['version']}")
print("commands:", len(names), "| steps:", len(ids))
sys.exit(0 if ok else 1)
PY
for f in featureline-ext/scripts/*.sh; do bash -n "$f" || { echo "FAIL syntax $f"; exit 1; }; done
echo "validate: ok"
