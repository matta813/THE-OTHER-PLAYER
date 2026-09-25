# AGENTS.md

Godot 4.7.2 stable / Linux, typed GDScript, Forward+. Run `./tools/run.sh`, `./tools/ci_validate.sh`, `./tools/ci_test.sh`, and `./tools/ci_build.sh` before major commits.

1. Inspect the architecture and dependencies before creating or rewriting systems.
2. Keep gameplay rules text-based; preserve scene-owned stable IDs, `remote_action`, state serialization, telemetry and adaptive hooks when replacing visuals. Saves must not depend on node paths.
3. Keep GameRuntime a small registry. Preserve existing save compatibility and test old paths.
4. Use reusable scenes/resources and primitive collision around authored meshes. Do not put important logic in binary art resources.
5. The generated Blender kit comes from `tools/blender/generate_kit.py`. Edit source parameters and regenerate `.blend`, manifest and GLBs coherently with `./tools/build_art.sh`; never hand-edit a generated GLB without understanding its source.
6. Use Blender automation for suitable new 3D assets. Runtime GLBs are committed so ordinary CI does not require Blender. Respect licenses and update `THIRD_PARTY.md` for external assets.
7. Run the game after meaningful visual or interaction changes, inspect Forward+ captures, fix introduced parser/runtime errors, and update architecture/art documentation.
8. Keep adaptive-system internals out of production UI. Debug presentation belongs only in debug builds.
9. Avoid new dependencies without a concrete reason. Make coherent commits. Never claim placeholder visuals, untested CI runs or incomplete playtests are finished.
