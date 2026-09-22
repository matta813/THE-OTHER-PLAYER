#!/usr/bin/env sh
set -eu
cd "$(dirname "$0")/.."
export XDG_DATA_HOME="${XDG_DATA_HOME:-/tmp/top-godot-data}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-/tmp/top-godot-config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-/tmp/top-godot-cache}"
godot --headless --path . --editor --quit
godot --headless --path . --quit-after 3
