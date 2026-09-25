# Continuous integration

`.github/workflows/ci.yml` runs on pull requests and pushes to `main`. It downloads the official Godot 4.7.2 stable Linux editor and matching export templates, validates the asset manifest and project, runs the seven headless test scenes, exports the Linux x86_64 release, and uploads `the-other-player-linux`. No secrets or Blender installation are needed. The workflow deliberately downloads clean binaries and imports assets from source; no machine-specific Godot cache is shared.

Local parity:

```sh
./tools/ci_validate.sh
./tools/ci_test.sh
./tools/ci_build.sh
```

`ci_build.sh` repeats validation and tests before export. Godot 4.7.2 stable and matching Linux export templates must be installed locally. `ci_validate.sh` fails if the expected engine version, export preset, Blender source/GLBs, or Godot parse check is missing. The CI workflow uses the official editor build; local Fedora builds may have a distribution suffix but must report 4.7.2 stable. The GitHub-hosted workflow still needs its first actual run after this commit; local parity passing does not prove a remote runner passed.

Godot command-line export and headless behavior follow the [Godot command-line documentation](https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html). Workflow artifacts use [GitHub Actions artifacts](https://docs.github.com/en/actions/concepts/workflows-and-actions/workflow-artifacts).
