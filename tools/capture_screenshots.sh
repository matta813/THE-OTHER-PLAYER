#!/usr/bin/env sh
set -eu
cd "$(dirname "$0")/.."
export TOP_CAPTURE_DIR="${TOP_CAPTURE_DIR:-/tmp/top-screenshots}"
for shot in arrival security generator transfer airlock terminal_close security_close transfer_close airlock_close; do
  TOP_CAPTURE_SHOT="$shot.png" godot --path . res://tests/visual_capture.tscn
done
printf 'Screenshots: %s\n' "$TOP_CAPTURE_DIR"
