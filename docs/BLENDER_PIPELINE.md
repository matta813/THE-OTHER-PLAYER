# Blender pipeline

Blender **5.2.2 LTS** generated the initial 29-asset kit. Run `./tools/build_art.sh` to regenerate the editable `art/blender/source/facility_kit.blend`, manifest and GLBs in `assets/models/{environment,props}`. The source of truth for the generated geometry is `tools/blender/generate_kit.py`; edit its parameterised functions instead of hand-editing exported GLBs. The Blender source file is included to inspect and refine the kit. `tools/blender/validate_kit.py` checks naming, materials, scale/poly limits, GLB structure and the presence of source/export files without starting Blender.

Godot consumes GLBs through `ProductionKit`. Existing `StaticBody3D`/`CollisionShape3D` nodes retain primitive collision and stable IDs. Replacing a rendered mesh must preserve those gameplay nodes and tests. Exported GLBs are committed so ordinary Godot CI does not require Blender. `tools/build_art.sh` writes a GLB only when its bytes changed.

All current `.blend` and `.glb` files are well below 1 MB each, so Git LFS is not configured. Re-evaluate when authored texture or audio masters become large. Do not blindly migrate small runtime assets into LFS.
