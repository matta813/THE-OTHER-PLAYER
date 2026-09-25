# Asset pipeline

Place source assets under `assets/` by type. Keep generated `.godot/` imports out of Git. Store the source file, any authored Godot material resource, and a verified license entry in `THIRD_PARTY.md`.

- `assets/textures/environment/`, `assets/textures/props/`, `assets/textures/decals/`
- `assets/meshes/environment/`, `assets/meshes/props/`
- `assets/audio/ambience/`, `machinery/`, `doors/`, `ui/`, `player/`, `voice/`
- `assets/fonts/`, `assets/icons/`
- `assets/materials/master/`, `assets/materials/instances/`

Use lowercase snake_case with a stable object name and role: `security_console_albedo.png`, `security_console_normal.png`, `security_console_roughness.png`, `security_console_metallic.png`, `security_console_ao.png`, `security_console_emissive.png`. Import normal maps as normal data; roughness, metallic and AO as data rather than colour. Check colour space and packing in Godot. Keep emissive levels restrained. Material instances should share master shaders and consistent world or texel scale.

Model in metres, with 1 Godot unit = 1 metre. Put the origin at the logical placement/pivot point, face -Z for interactable fronts, and apply scale before export. Export glTF 2.0 (`.glb` preferred) with deliberate collision meshes or create collision in a reusable scene. Prepare lower-detail versions for large repeated objects; do not create LODs where they add no value. Keep important interaction and save logic in text scripts, with stable IDs independent of mesh paths.

Audio: archive source masters separately; import 48 kHz WAV or Ogg for the game. Use mono for positional emitters and stereo for non-positional ambience or UI. Trim clicks and silence, design clean loops, and mark loop points. Route ambience, SFX, UI and voice to their matching buses. Check positional falloff in the room, overlap and quiet moments before accepting an asset.

Current production assets are procedural materials and synthesized sound. The directories above are conventions for future authored assets, not a claim that those assets already exist.
