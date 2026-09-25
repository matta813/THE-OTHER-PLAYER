# Building

Use Godot 4.7.2 on Linux. The project targets Forward+; run it with `./tools/run.sh`. Use `./tools/check.sh` for import and runtime parsing and `./tools/test.sh` for logic and chapter-path checks. Headless tests use a dummy renderer and cannot judge lighting or camera feed appearance.

Install matching 4.7.2 export templates through Godot's Export Template Manager. `./tools/export_release.sh` checks the project, runs tests and exports the Linux x86_64 preset to `build/linux/the-other-player.x86_64`. It copies the verified third-party notice beside the build and fails if templates are missing. Run the executable directly outside the editor. The output directory is ignored by Git.

The production shell has no studio splash or dedicated loading screen yet. Visual QA and hardware performance profiling require a desktop Vulkan session and first-time human playthrough. Inspect the Security, Generator and Airlock spaces as well as the opening rooms.
