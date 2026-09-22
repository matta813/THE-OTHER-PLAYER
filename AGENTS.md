# AGENTS.md

Godot 4.x / Linux, typed GDScript, Forward+. Commands: `./tools/run.sh`, `./tools/check.sh`, `./tools/test.sh`.

1. Inspect existing architecture before creating systems.
2. Understand dependencies before rewrites.
3. Keep core logic text-based.
4. Prefer reusable scenes/resources.
5. Run after meaningful changes.
6. Fix introduced parser/runtime errors.
7. Update documentation with architecture.
8. Preserve save compatibility.
9. Avoid dependencies without clear reason.
10. Make coherent commits.
11. Never claim placeholders complete.
12. Keep important logic out of binary resources.

Facility objects use stable IDs; saves do not depend on node paths. Keep GameRuntime a small registry.
