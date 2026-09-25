# Asset standards

- One Godot unit is one metre. Author in Blender with metric scale 1 and applied object scale.
- Generated mesh names start `VIS_`; collision remains a simple Godot shape. If Blender collision is introduced, name it `COL_` and configure Godot import explicitly so it is not rendered.
- Keep each asset centred at a useful installation origin. Height is Blender Z and Godot Y. Use an asset manifest entry with category, bounds, object count and collision policy.
- Export GLB with selection only and Y-up conversion. Keep shader materials in a physically plausible range. Reuse the project's metal, concrete, rubber, plastic and indicator palette.
- Light fixture geometry needs a nearby practical light node in Godot. Emissive material alone does not illuminate the room.
- Tiny repeated items need no LOD. Create LOD1/LOD2 only for larger complex props after measured benefit. Current kit meshes are small and below 12,000 triangles.
- Before replacing an interactable, check its stable ID, `state_dict`/`load_state`, `remote_action`, signals, collision and audio. Do not change save keys for a visual replacement.
