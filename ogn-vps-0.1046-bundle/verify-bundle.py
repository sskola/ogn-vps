#!/usr/bin/env python3
"""Read-only SHA-256 verification of an OGN VPS bundle."""
from pathlib import Path
import hashlib
import sys

root = Path(sys.argv[1] if len(sys.argv) > 1 else Path(__file__).parent).resolve()
manifest = root / "manifest.sha256"
if not manifest.is_file():
    raise SystemExit(f"Missing {manifest}")
def is_macos_metadata(path: Path) -> bool:
    return path.name == ".DS_Store" or path.name.startswith("._")

listed = set()
for number, line in enumerate(manifest.read_text().splitlines(), 1):
    try:
        expected, relative = line.split("  ", 1)
    except ValueError:
        raise SystemExit(f"Malformed manifest line {number}")
    path = (root / relative).resolve()
    if not path.is_relative_to(root) or not path.is_file() or relative in listed or is_macos_metadata(path):
        raise SystemExit(f"Missing, duplicate, or invalid path: {relative}")
    listed.add(relative)
    actual = hashlib.sha256(path.read_bytes()).hexdigest()
    if actual != expected:
        raise SystemExit(f"SHA-256 mismatch: {relative}")
actual_files = {str(p.relative_to(root)) for p in root.rglob("*") if p.is_file() and p.name != "manifest.sha256" and not is_macos_metadata(p)}
if actual_files != listed:
    raise SystemExit(f"File set differs: missing={sorted(listed - actual_files)}, extra={sorted(actual_files - listed)}")
print(f"Verified {len(listed)} bundle files")
