"""Validate Blender's manifest and generated GLB containers without Blender."""
import json
import struct
import sys
from pathlib import Path

root = Path(__file__).resolve().parents[2]
manifest = json.loads((root / "art/blender/kit_manifest.json").read_text())
issues = []
for asset in manifest["assets"]:
    name = asset["name"]
    path = root / "assets/models" / asset["category"] / (name + ".glb")
    if not path.exists():
        issues.append(f"missing export: {name}")
        continue
    data = path.read_bytes()
    if data[:4] != b"glTF" or struct.unpack_from("<I", data, 8)[0] != len(data):
        issues.append(f"invalid GLB: {name}")
    if data[:4] == b"glTF" and len(data) >= 20:
        json_length, chunk_type = struct.unpack_from("<II", data, 12)
        if chunk_type != 0x4E4F534A:
            issues.append(f"missing GLB JSON: {name}")
        else:
            gltf = json.loads(data[20:20+json_length])
            visual_nodes = [node for node in gltf.get("nodes", []) if "mesh" in node]
            if not visual_nodes or any(not node.get("name", "").startswith("VIS_") for node in visual_nodes):
                issues.append(f"invalid mesh naming: {name}")
            triangles = 0
            for mesh in gltf.get("meshes", []):
                for primitive in mesh.get("primitives", []):
                    if "material" not in primitive:
                        issues.append(f"missing material: {name}")
                    index = primitive.get("indices")
                    if index is not None:
                        triangles += gltf["accessors"][index]["count"] // 3
            if triangles > 12000:
                issues.append(f"too many triangles: {name} ({triangles})")
    if max(asset["bounds_m"]) > 4.0 or asset["triangles_max"] > 12000:
        issues.append(f"outside scale/poly budget: {name}")
    if path.stat().st_size > 4_000_000:
        issues.append(f"oversized GLB: {name}")
if not (root / "art/blender/source/facility_kit.blend").exists():
    issues.append("missing Blender source")
print(f"ASSET VALIDATION: {len(manifest['assets'])} assets, {len(issues)} issues")
for issue in issues:
    print("ERROR:", issue)
sys.exit(bool(issues))
