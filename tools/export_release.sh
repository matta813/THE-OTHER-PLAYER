#!/usr/bin/env sh
set -eu
cd "$(dirname "$0")/.."
export XDG_DATA_HOME="${XDG_DATA_HOME:-/tmp/top-godot-data}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-/tmp/top-godot-config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-/tmp/top-godot-cache}"
./tools/check.sh
./tools/test.sh
mkdir -p build/linux
godot --headless --path . --export-release Linux build/linux/the-other-player.x86_64
test -x build/linux/the-other-player.x86_64 || { echo "Linux export was not created. Install the matching Godot export templates." >&2; exit 1; }
cp THIRD_PARTY.md build/linux/THIRD_PARTY.md
echo "Release build: build/linux/the-other-player.x86_64"
