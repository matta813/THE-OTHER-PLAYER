#!/usr/bin/env sh
set -eu
cd "$(dirname "$0")/.."
mkdir -p build/linux
./tools/ci_validate.sh
./tools/ci_test.sh
export XDG_DATA_HOME="${XDG_DATA_HOME:-/tmp/top-godot-data}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-/tmp/top-godot-config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-/tmp/top-godot-cache}"
godot --headless --path . --export-release Linux build/linux/the-other-player.x86_64
test -x build/linux/the-other-player.x86_64
test -s build/linux/the-other-player.pck
cp THIRD_PARTY.md build/linux/THIRD_PARTY.md
