"""Tests in the shape the Extension Development Guide recommends
(specify_cli.extensions.ExtensionManifest), plus the checks scripts/validate.sh does offline."""
import re
import subprocess
from pathlib import Path

import pytest
import yaml

ROOT = Path(__file__).resolve().parent.parent
EXT = ROOT / "featureline-ext"
WF = ROOT / "featureline-workflow" / "workflow.yml"


@pytest.fixture(scope="session")
def manifest():
    return yaml.safe_load((EXT / "extension.yml").read_text())


def test_manifest_loads_with_speckit():
    """The guide's own example: the Spec Kit manifest class must accept it."""
    speckit = pytest.importorskip("specify_cli.extensions")
    m = speckit.ExtensionManifest(EXT / "extension.yml")
    assert m.id == "featureline"
    assert len(m.commands) == 9


def test_extension_id_and_version(manifest):
    e = manifest["extension"]
    assert re.fullmatch(r"[a-z0-9-]+", e["id"])
    assert re.fullmatch(r"\d+\.\d+\.\d+", e["version"])
    assert "<" in manifest["requires"]["speckit_version"], "version range must have an upper bound"


def test_command_names_files_and_verb_noun(manifest):
    for c in manifest["provides"]["commands"]:
        assert re.fullmatch(r"speckit\.featureline\.[a-z]+-[a-z-]+", c["name"]), f"{c['name']} is not verb-noun"
        assert (EXT / c["file"]).exists(), c["file"]
        fm = yaml.safe_load((EXT / c["file"]).read_text().split("---")[1])
        assert fm["description"]


def test_command_bodies_use_tokens_not_literals(manifest):
    for c in manifest["provides"]["commands"]:
        body = (EXT / c["file"]).read_text().split("---", 2)[2]
        assert not re.search(r"(?<![\w`.-])/speckit\.", body), f"{c['file']} has a literal /speckit. invocation"


def test_handoffs_resolve(manifest):
    known = {c["name"] for c in manifest["provides"]["commands"]} | {
        "speckit.specify", "speckit.clarify", "speckit.plan", "speckit.tasks",
        "speckit.analyze", "speckit.implement", "speckit.constitution", "speckit.checklist"}
    for c in manifest["provides"]["commands"]:
        fm = yaml.safe_load((EXT / c["file"]).read_text().split("---")[1])
        for h in fm.get("handoffs", []):
            assert h["agent"] in known, f"{c['file']} -> {h['agent']}"


def test_hooks_target_own_commands(manifest):
    names = {c["name"] for c in manifest["provides"]["commands"]}
    for ev, h in manifest.get("hooks", {}).items():
        assert ev.startswith(("before_", "after_"))
        for x in (h if isinstance(h, list) else [h]):
            assert x["command"] in names


def test_scripts_exist_and_parse(manifest):
    for s in manifest["provides"]["scripts"]:
        p = EXT / s["file"]
        assert p.exists(), s["file"]
        subprocess.run(["bash", "-n", str(p)], check=True)


def test_config_template_declared_and_present(manifest):
    cfg = manifest["provides"]["config"][0]
    assert cfg["name"] == "featureline-config.yml"
    assert (EXT / cfg["template"]).exists()


def test_workflow_calls_only_known_commands(manifest):
    wf = yaml.safe_load(WF.read_text())
    assert wf["workflow"]["id"] == manifest["extension"]["id"]
    assert wf["workflow"]["version"] == manifest["extension"]["version"]
    known = {c["name"] for c in manifest["provides"]["commands"]} | {
        "speckit.specify", "speckit.clarify", "speckit.plan", "speckit.tasks",
        "speckit.analyze", "speckit.implement", "speckit.constitution"}
    ids = []

    def walk(steps):
        for s in steps:
            ids.append(s["id"])
            assert ":" not in s["id"]
            if "command" in s:
                assert s["command"] in known, f"{s['id']} -> {s['command']}"
            for k in ("steps", "then", "else", "default"):
                if k in s:
                    walk(s[k])
            for st in s.get("cases", {}).values():
                walk(st)

    walk(wf["steps"])
    assert len(ids) == len(set(ids)), "duplicate step ids"
