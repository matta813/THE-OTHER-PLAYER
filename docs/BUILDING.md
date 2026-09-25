# Building

Use Godot 4.7.2 stable on Linux. The project targets Forward+ and runs with `./tools/run.sh`. Matching 4.7.2 Linux export templates are required for a release export.

```sh
./tools/ci_validate.sh
./tools/ci_test.sh
./tools/ci_build.sh
```

The build lands in `build/linux/the-other-player.x86_64` with its `.pck` and `THIRD_PARTY.md`. Run the executable from that directory. `./tools/export_release.sh` remains the shorter combined check/test/export entry point. Build output is ignored by Git. The source Blender file and generator are under `art/` and `tools/blender/`; they are not required to run or export the committed GLBs. See [CI.md](CI.md) and [BLENDER_PIPELINE.md](BLENDER_PIPELINE.md).

Visual QA requires a Vulkan desktop session. `./tools/capture_screenshots.sh` saves consistent Forward+ views to `/tmp/top-screenshots` or `TOP_CAPTURE_DIR`. The opening, Security Office, Generator, Transfer, and Airlock should also be walked by a human. The capture utility does not simulate a full playthrough.
