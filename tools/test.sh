#!/usr/bin/env sh
set -eu
cd "$(dirname "$0")/.."
export XDG_DATA_HOME="${XDG_DATA_HOME:-/tmp/top-godot-data}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-/tmp/top-godot-config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-/tmp/top-godot-cache}"
godot --headless --path . res://tests/test_runner.tscn
godot --headless --path . res://tests/scene_geometry_test.tscn
godot --headless --path . res://tests/adaptive_scene_test.tscn
godot --headless --path . res://tests/chapter_scene_test.tscn
godot --headless --path . res://tests/chapter_adaptive_test.tscn
godot --headless --path . res://tests/loading_flow_test.tscn
smoke_data_dir="$(mktemp -d /tmp/top-smoke-data.XXXXXX)"
smoke_config_dir="$(mktemp -d /tmp/top-smoke-config.XXXXXX)"
smoke_cache_dir="$(mktemp -d /tmp/top-smoke-cache.XXXXXX)"
XDG_DATA_HOME="$smoke_data_dir" XDG_CONFIG_HOME="$smoke_config_dir" XDG_CACHE_HOME="$smoke_cache_dir" exec godot --headless --path . res://tests/production_smoke_test.tscn
