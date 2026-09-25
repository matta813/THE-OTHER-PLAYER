#!/usr/bin/env sh
set -eu
cd "$(dirname "$0")/.."
version="$(godot --version)"
case "$version" in 4.7.2.stable*) ;; *) echo "Godot 4.7.2 stable required; found $version" >&2; exit 1;; esac
python3 tools/blender/validate_kit.py
test -f export_presets.cfg
grep -q '^name="Linux"$' export_presets.cfg
./tools/check.sh
