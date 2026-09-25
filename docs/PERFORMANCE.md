# Performance and scene budget

Use `godot --path . res://tests/performance_probe.tscn` from a desktop Vulkan session for a local Forward+ sample. The probe loads Chapter 1 at the maintenance corridor, samples 180 process frames, and reports instance, light and viewport render counts. `./tools/capture_screenshots.sh` renders location views one process per camera position; set `TOP_CAPTURE_DIR` for output. Headless CI validates logic and export but cannot judge lighting or GPU performance.

## September 2026 local sample

Godot 4.7.2, Intel Iris Xe (TGL GT2), 1280×720, Forward+:

| Measure | Result |
| --- | ---: |
| Scene mesh instances | 1,174 |
| Scene lights | 24 |
| Shadow-enabled lights | 8 |
| Visible objects at sample view | 610 |
| Draw calls at sample view | 281 |
| Primitives at sample view | 62,286 |
| 180 process-frame wall time | 2,200–2,217 ms |
| Engine FPS at end of sample | 84–85 |

Two consecutive samples after the hero-prop pass reported 84–85 FPS, versus a 59 FPS earlier sample; renderer timing varies with warmup and local conditions, so this does not establish a sustained improvement. The wall-time figure includes engine overhead and is not a precise GPU frame-time benchmark; GPU timing, VRAM, shader stalls and sustained route-wide FPS remain unmeasured. The mesh count is high because many small static modular pieces are separate instances. Initial targets for later optimization: keep visible draw calls below roughly 300 at 720p on this class of GPU, review the eight shadow casters and merge only repeated static detail where measurements show benefit. The 31 GLBs contain no large textures. Godot primitive collision is kept separate from visual meshes.
