#!/usr/bin/env python3
"""Assigns co-located files under App/ to the right target.

All three targets synchronize App/; each target's exception set lists the files it must not
build. *SnapshotTests.swift and Core/SnapshotTestSupport/ → FreePulseCheckSnapshotTests, other *Tests.swift →
FreePulseCheckTests, everything else → the app. __Snapshots__ folders belong to no target.
Run after adding, moving or removing any file under App/.
"""
import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parent.parent
PROJECT = ROOT / "FreePulseCheck.xcodeproj" / "project.pbxproj"
APP = ROOT / "App"
OPAQUE_SUFFIXES = {".xcassets", ".bundle"}


def entries(root):
    for path in sorted(root.iterdir()):
        if path.name.startswith("."):
            continue
        if path.is_dir() and path.suffix not in OPAQUE_SUFFIXES and path.name != "__Snapshots__":
            yield from entries(path)
        else:
            yield path


def kind(path):
    if path.name == "__Snapshots__":
        return "reference"
    if "SnapshotTestSupport" in path.parts or path.name.endswith("SnapshotTests.swift"):
        return "snapshot"
    if path.name.endswith("Tests.swift"):
        return "unit"
    return "app"


files = [(str(path.relative_to(APP)), kind(path)) for path in entries(APP)]
exclusions = {
    "F1C0000000000000000000E1": [name for name, k in files if k != "app"],
    "F1C0000000000000000000E2": [name for name, k in files if k != "unit"],
    "F1C0000000000000000000E3": [name for name, k in files if k != "snapshot"],
}

text = PROJECT.read_text()
for set_id, names in exclusions.items():
    listing = "".join(f'\t\t\t\t"{name}",\n' for name in names)
    pattern = re.compile(rf"({set_id} /\* [^*]* \*/ = {{\n\t\t\tisa = PBXFileSystemSynchronizedBuildFileExceptionSet;\n\t\t\tmembershipExceptions = \(\n)(.*?)(\t\t\t\);)", re.S)
    text, count = pattern.subn(lambda match: match.group(1) + listing + match.group(3), text)
    if count != 1:
        raise SystemExit(f"Exception set {set_id} not found in {PROJECT}")
PROJECT.write_text(text)
counts = {k: sum(1 for _, kk in files if kk == k) for k in ("app", "unit", "snapshot", "reference")}
print(", ".join(f"{v} {k}" for k, v in counts.items()))
