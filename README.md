# THE OTHER PLAYER

An offline, first-person psychological-horror game built with Godot 4. Chapter 1, **Connection**, is playable from a restrained facility main menu. The unseen partner observes behaviour, helps remotely, and can act a little too early. Version **0.1.0 pre-alpha** is defined in `scripts/core/release_info.gd`. Chapter 2 has not begun.

## Play

Use Godot 4.7.2 on Linux (Forward+):

```sh
./tools/run.sh
```

From the menu choose New Game or Continue. Chapter 1 moves through Arrival, Security, Transfer, Generator, Communications and Exit Airlock. See `docs/CHAPTER_01.md` for the route. Esc opens Pause; from there you can save to or load from four manual slots, adjust settings, return to menu or quit. Autosaves are written at chapter checkpoints. Quick save and quick load remain on F5/F9. Existing version 1–4 `user://save.json` and `user://checkpoint.json` files remain loadable.

Controls: WASD movement, mouse look, Shift sprint, Ctrl crouch, E interact, Esc pause, F5 quick save, F9 quick load. Controls can be rebound in Settings. In debug builds only, F3 opens telemetry; with it open F6 teleports to the current task, F7 sets a cooperative state, and F8 advances remote timers.

## Build and validation

```sh
./tools/ci_validate.sh
./tools/ci_test.sh
./tools/ci_build.sh
```

The local CI scripts validate the generated art and project, run seven test scenes, and create `build/linux/the-other-player.x86_64`. Install the matching Godot 4.7.2 export templates first. Run the executable from its build directory; `THIRD_PARTY.md` is copied alongside it. Build output and Godot import caches are ignored by Git. See `docs/BUILDING.md` for details.

## Repository

- `scenes/`: main menu and Chapter 1 scene.
- `scripts/core/`: runtime registry, scene flow, version and persistent settings.
- `scripts/save/`: versioned save data and slot metadata.
- `scripts/world/`, `scripts/facility/`, `scripts/other_player/`: chapter spaces, interactions and adaptive systems.
- `scripts/ui/`, `scripts/audio/`: menus, captions, terminal and sound.
- `art/`: editable Blender source and manifest; `assets/models/`: 31 generated GLB environment and prop modules. See `docs/BLENDER_PIPELINE.md`.
- `resources/`: authored dialogue. `tests/` and `tools/`: checks, scene tests and build scripts.

This remains a pre-alpha production pass. Chapter 1 has integrated Blender visuals, mechanical motion, sound layers and shared menu styling, but several spaces still look simple. Recorded audio, a fuller terminal/loading design, route-wide performance measurement, verified 30–45 minute playtime and a first-time human playtest remain outstanding. See `docs/CI.md`, `docs/PERFORMANCE.md` and `docs/ROADMAP.md`.
