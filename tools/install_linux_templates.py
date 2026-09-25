"""Install only Linux Godot export templates from an official .tpz archive."""
import sys
import zipfile
from pathlib import Path

archive = Path(sys.argv[1])
destination = Path(sys.argv[2])
destination.mkdir(parents=True, exist_ok=True)
required = {"linux_debug.x86_64", "linux_release.x86_64"}
with zipfile.ZipFile(archive) as source:
    for name in source.namelist():
        basename = Path(name).name
        if basename in required:
            (destination / basename).write_bytes(source.read(name))
for basename in required:
    if not (destination / basename).is_file():
        raise SystemExit(f"Missing Godot template: {basename}")
print(f"Installed Linux templates: {destination}")
