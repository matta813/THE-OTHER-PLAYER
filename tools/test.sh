#!/usr/bin/env sh
set -eu
cd "$(dirname "$0")/.."
export XDG_DATA_HOME="${XDG_DATA_HOME:-/tmp/top-godot-data}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-/tmp/top-godot-config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-/tmp/top-godot-cache}"
godot --headless --path . res://tests/test_runner.tscn
godot --headless --path . res://tests/scene_geometry_test.tscn
exec godot --headless --path . res://tests/adaptive_scene_test.tscn
