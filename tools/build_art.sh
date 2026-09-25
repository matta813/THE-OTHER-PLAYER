#!/usr/bin/env sh
set -eu
cd "$(dirname "$0")/.."
command -v blender >/dev/null 2>&1 || { echo "Blender is required to rebuild art." >&2; exit 1; }
blender --background --factory-startup --python tools/blender/generate_kit.py
python3 tools/blender/validate_kit.py
