"""Generate THE OTHER PLAYER's metric facility kit with Blender 5.2+."""
import bpy
import json
import math
import os
from pathlib import Path
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets" / "models"
SOURCE = ROOT / "art" / "blender" / "source" / "facility_kit.blend"
REPORT = ROOT / "art" / "blender" / "kit_manifest.json"

bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete(use_global=False)
for data in bpy.data.materials:
    bpy.data.materials.remove(data)
bpy.context.scene.unit_settings.system = "METRIC"
bpy.context.scene.unit_settings.scale_length = 1.0
bpy.context.preferences.filepaths.save_version = 0

PALETTE = {
    "painted_steel": ((0.15, 0.19, 0.19, 1), 0.56, 0.58),
    "dark_steel": ((0.052, 0.071, 0.077, 1), 0.70, 0.50),
    "galvanised": ((0.24, 0.27, 0.26, 1), 0.72, 0.63),
    "brushed_metal": ((0.40, 0.43, 0.42, 1), 0.82, 0.38),
    "stainless": ((0.52, 0.55, 0.53, 1), 0.84, 0.28),
    "concrete": ((0.18, 0.19, 0.18, 1), 0.0, 0.91),
    "painted_concrete": ((0.15, 0.18, 0.17, 1), 0.0, 0.85),
    "rubber": ((0.035, 0.045, 0.047, 1), 0.0, 0.89),
    "industrial_plastic": ((0.12, 0.17, 0.18, 1), 0.0, 0.63),
    "glass": ((0.08, 0.16, 0.17, 1), 0.10, 0.18),
    "dirty_glass": ((0.09, 0.13, 0.13, 1), 0.08, 0.46),
    "floor_epoxy": ((0.16, 0.21, 0.20, 1), 0.0, 0.48),
    "cable_insulation": ((0.055, 0.065, 0.07, 1), 0.0, 0.82),
    "warning_paint": ((0.73, 0.44, 0.12, 1), 0.05, 0.66),
    "indicator_green": ((0.04, 0.35, 0.20, 1), 0.0, 0.42),
    "indicator_red": ((0.48, 0.055, 0.035, 1), 0.0, 0.44),
    "label": ((0.67, 0.72, 0.65, 1), 0.0, 0.88),
}
MATERIALS = {}
for name, (color, metallic, roughness) in PALETTE.items():
    material = bpy.data.materials.new(name)
    material.diffuse_color = color
    material.use_nodes = True
    principled = material.node_tree.nodes.get("Principled BSDF")
    principled.inputs["Base Color"].default_value = color
    principled.inputs["Metallic"].default_value = metallic
    principled.inputs["Roughness"].default_value = roughness
    if name.startswith("indicator_"):
        principled.inputs["Emission Color"].default_value = color
        principled.inputs["Emission Strength"].default_value = 0.35
    MATERIALS[name] = material

ASSETS = {}
CURRENT = None

def begin(name, category, bounds):
    global CURRENT
    CURRENT = {"name": name, "category": category, "bounds": bounds, "objects": []}
    ASSETS[name] = CURRENT


def add(obj, suffix, material):
    obj.name = "VIS_%s_%s" % (CURRENT["name"], suffix)
    obj.data.materials.clear()
    obj.data.materials.append(MATERIALS[material])
    CURRENT["objects"].append(obj)
    return obj


def box(suffix, pos, dims, material="painted_steel", bevel=0.012):
    bpy.ops.mesh.primitive_cube_add(size=1, location=pos)
    obj = bpy.context.object
    obj.dimensions = dims
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if bevel > 0:
        mod = obj.modifiers.new("Manufactured edge", "BEVEL")
        mod.width = min(bevel, min(dims) * 0.23)
        mod.segments = 2
        bpy.context.view_layer.objects.active = obj
        bpy.ops.object.modifier_apply(modifier=mod.name)
        weighted = obj.modifiers.new("Weighted normals", "WEIGHTED_NORMAL")
        bpy.ops.object.modifier_apply(modifier=weighted.name)
    return add(obj, suffix, material)


def cylinder(suffix, pos, radius, depth, material="galvanised", vertices=12, rotation=(0,0,0)):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=pos, rotation=rotation)
    return add(bpy.context.object, suffix, material)


def pipe(suffix, start, end, radius=0.04, material="galvanised", vertices=12):
    a, b = Vector(start), Vector(end)
    mid = (a+b)*0.5
    obj = cylinder(suffix, mid, radius, (b-a).length, material, vertices)
    obj.rotation_euler = (b-a).to_track_quat('Z','Y').to_euler()
    return obj


def text(suffix, content, pos, size=0.08, material="label", rotation=(math.pi/2,0,0)):
    bpy.ops.object.text_add(location=pos, rotation=rotation)
    obj = bpy.context.object
    obj.data.body = content
    obj.data.size = size
    obj.data.extrude = 0.0005
    bpy.ops.object.convert(target="MESH")
    return add(bpy.context.object, suffix, material)


def bolts(prefix, xs, ys, front, radius=0.016):
    for i,x in enumerate(xs):
        for j,z in enumerate(ys):
            cylinder("%s_%d_%d"%(prefix,i,j),(x,front,z),radius,0.009,"brushed_metal",8,rotation=(math.pi/2,0,0))

# The X/Z plane is the visible face; +Y is the service/front side in Blender.
begin("wall_section", "environment", [2.4,0.18,3.2])
box("cast_panel",(0,0,0),(2.4,0.18,3.2),"painted_concrete",0.012)
for x in [-1.13,1.13]: box("edge_channel_%s"%x,(x,0.12,0),(0.08,0.08,3.12),"galvanised",0.008)
box("kick_plate",(0,0.105,-1.38),(2.28,0.025,0.38),"dark_steel",0.006)
box("upper_service_seam",(0,0.104,1.05),(2.18,0.008,0.009),"dark_steel",0)
bolts("fastener",[-1.0,1.0],[-1.2,0.92],0.124)

begin("reinforced_wall", "environment", [2.4,0.3,3.2])
box("panel",(0,0,0),(2.4,0.3,3.2),"concrete",0.008)
for x in [-1.1,0,1.1]: box("structural_rib_%s"%x,(x,0.19,0),(0.12,0.13,3.2),"galvanised")
for z in [-1.35,1.35]: box("rail_%s"%z,(0,0.19,z),(2.32,0.12,0.10),"dark_steel")
bolts("anchor",[-0.96,0.96],[-1.18,1.18],0.27,0.022)

begin("wall_corner", "environment", [0.32,0.32,3.2])
box("angle_x",(0,0.14,0),(0.32,0.055,3.2),"galvanised")
box("angle_y",(0.14,0,0),(0.055,0.32,3.2),"galvanised")
for z in [-1.3,0,1.3]: box("anchor_%s"%z,(0.14,0.14,z),(0.1,0.1,0.09),"dark_steel")

begin("floor_section", "environment", [2.0,2.0,0.12])
box("epoxy_slab",(0,0,0),(2,2,0.12),"floor_epoxy",0.012)
for x in [-0.94,0.94]: box("joint_x_%s"%x,(x,0,0.064),(0.014,1.92,0.003),"rubber",0)
for y in [-0.94,0.94]: box("joint_y_%s"%y,(0,y,0.064),(1.92,0.014,0.003),"rubber",0)

begin("ceiling_section", "environment", [2.0,2.0,0.12])
box("service_tile",(0,0,0),(2,2,0.12),"painted_steel")
for x in [-0.9,0.9]: box("rail_%s"%x,(x,0,-0.07),(0.035,1.92,0.035),"galvanised")

begin("structural_beam", "environment", [0.22,0.24,2.4])
box("web",(0,0,0),(0.035,0.22,2.4),"galvanised")
for x in [-0.09,0.09]: box("flange_%s"%x,(x,0,0),(0.045,0.24,2.4),"galvanised")

begin("door_frame", "environment", [2.84,0.4,3.06])
for x in [-1.36,1.36]:
    box("jamb_%s"%x,(x,0,0),(0.13,0.38,3.06),"dark_steel")
    box("seal_%s"%x,(x*0.93,0.21,0),(0.035,0.025,2.83),"rubber",0)
box("header",(0,0,1.45),(2.82,0.4,0.16),"dark_steel")
box("threshold",(0,0,-1.48),(2.82,0.38,0.07),"brushed_metal")
for x in [-1.21,1.21]:
    box("hinge_rail_%s"%x,(x,0.23,0),(0.05,0.05,2.35),"brushed_metal")
text("id","BARRIER / 01",(-0.55,0.21,1.47),0.075)

begin("industrial_door", "environment", [2.6,0.22,2.7])
box("leaf",(0,0,0),(2.6,0.22,2.7),"painted_steel",0.022)
box("recess",(0,0.117,0.16),(2.22,0.018,2.08),"dark_steel",0.009)
box("inset",(0,0.131,0.17),(2.09,0.013,1.94),"painted_steel",0.006)
box("kickplate",(0,0.132,-0.99),(2.38,0.018,0.43),"brushed_metal")
box("window_rim",(0,0.145,0.58),(0.76,0.026,0.36),"rubber")
box("window",(0,0.16,0.58),(0.67,0.014,0.27),"dirty_glass",0.003)
for z in [-0.65,0.1]: box("stiffener_%s"%z,(0,0.147,z),(2.03,0.025,0.024),"galvanised")
box("latch_plate",(1.02,0.17,-0.10),(0.18,0.05,0.34),"brushed_metal")
cylinder("latch",(1.02,0.205,-0.11),0.037,0.055,"stainless",12,rotation=(math.pi/2,0,0))
text("number","01 / REMOTE",(-0.98,0.17,-0.47),0.065)
bolts("edge_bolt",[-1.16,1.16],[-1.16,1.14],0.13)

begin("cable_tray", "environment", [0.4,2.4,0.13])
for x in [-0.19,0.19]: box("rail_%s"%x,(x,0,0),(0.025,2.4,0.13),"galvanised",0.003)
for y in [-1.05,-0.7,-0.35,0,0.35,0.7,1.05]: box("rung_%s"%y,(0,y,-0.05),(0.38,0.034,0.025),"galvanised",0.002)

begin("cable_bundle", "environment", [0.32,2.3,0.18])
for i,(x,z) in enumerate([(-.12,0),(-.04,.04),(.05,-.03),(.13,.02)]): pipe("run_%s"%i,(x,-1.15,z),(x,1.15,z),0.018,"cable_insulation",8)
for y in [-0.9,0,0.9]: box("strap_%s"%y,(0,y,0),(0.31,0.035,0.06),"galvanised",0.004)

begin("ventilation_duct", "environment", [0.7,2.4,0.5])
box("duct",(0,0,0),(0.7,2.4,0.5),"galvanised",0.012)
for y in [-1.1,0,1.1]: box("joint_%s"%y,(0,y,0),(0.76,0.06,0.56),"dark_steel",0.005)

begin("ventilation_grille", "environment", [0.9,0.08,0.55])
box("back",(0,-0.025,0),(0.9,0.03,0.55),"rubber")
for x in [-0.4,0.4]: box("frame_side_%s"%x,(x,0.018,0),(0.07,0.08,0.54),"galvanised")
for z in [-0.24,0.24]: box("frame_top_%s"%z,(0,0.018,z),(0.86,0.08,0.05),"galvanised")
for z in [-0.17,-0.08,0.01,0.10,0.19]: box("louver_%s"%z,(0,0.025,z),(0.77,0.04,0.022),"dark_steel",0.002)

begin("pipe_straight", "environment", [0.14,2.4,0.14])
pipe("tube",(0,-1.2,0),(0,1.2,0),0.054,"galvanised")
for y in [-1.1,1.1]: cylinder("flange_%s"%y,(0,y,0),0.083,0.06,"brushed_metal",16,rotation=(math.pi/2,0,0))

begin("pipe_elbow", "environment", [0.9,0.9,0.14])
pipe("leg_a",(0,-0.45,0),(0,0.3,0),0.054)
pipe("leg_b",(0,0.30,0),(.78,.30,0),0.054)
cylinder("joint",(0,.30,0),.065,.13,"brushed_metal",16)

begin("pipe_junction", "environment", [0.9,0.9,0.14])
pipe("main",(0,-.45,0),(0,.45,0),.054)
pipe("branch",(0,0,0),(.8,0,0),.054)
cylinder("tee",(0,0,0),.075,.15,"brushed_metal",16)

begin("electrical_cabinet", "props", [1.2,0.65,2.1])
box("cabinet",(0,0,0),(1.2,.65,2.1),"dark_steel",.025)
box("door",(0,.341,0),(1.09,.035,1.93),"painted_steel",.012)
box("hinge_left",(-.53,.37,0),(.05,.05,1.55),"galvanised")
box("handle",(.43,.395,0),(.055,.075,.28),"brushed_metal")
for z in [-.66,-.59,-.52,-.45]: box("vent_%s"%z,(0,.368,z),(.55,.012,.018),"rubber",0)
box("warning",(0,.367,.56),(.48,.016,.22),"warning_paint",.003)
text("id","HV-04 / 35A",(-.43,.38,0.68),.061)
bolts("door_bolt",[-.48,.48],[-.84,.85],.37)

begin("breaker_panel", "props", [1.3,0.30,0.85])
box("back",(0,0,0),(1.3,.3,.85),"dark_steel")
box("face",(0,.16,0),(1.21,.03,.76),"painted_steel")
for i,x in enumerate([-.45,-.15,.15,.45]):
    box("breaker_well_%s"%i,(x,.18,0),(.23,.018,.49),"rubber")
    box("toggle_%s"%i,(x,.22,-.02),(.09,.09,.23),"brushed_metal")
    text("channel_%s"%i,str(i+1),(x-.035,.195,.28),.047)
text("id","DISTRIBUTION / BUS 10",(-.54,.2,.34),.044)

begin("equipment_rack", "props", [0.9,0.8,2.0])
for x in [-.42,.42]: box("upright_%s"%x,(x,0,0),(.065,.76,2),"dark_steel")
for z in [-.91,.91]: box("header_%s"%z,(0,0,z),(.9,.8,.08),"dark_steel")
for i in range(5):
    z=-.68+i*.32
    box("module_%s"%i,(0,.39,z),(.75,.06,.24),"industrial_plastic")
    for x in [-.29,-.2]: cylinder("indicator_%s_%s"%(i,x),(x,.43,z),.012,.009,"indicator_green" if i<3 else "indicator_red",8,rotation=(math.pi/2,0,0))

begin("terminal_housing", "props", [0.74,0.48,1.45])
box("pedestal",(0,-.10,-.2),(.68,.48,1.1),"dark_steel",.022)
box("screen_shell",(0,.04,.30),(.74,.31,.73),"painted_steel",.025)
box("screen_gasket",(0,.207,.31),(.62,.025,.54),"rubber",.008)
box("screen_glass",(0,.227,.31),(.56,.008,.48),"dirty_glass",.006)
box("screen_bezel_lower",(0,.22,-.015),(.6,.025,.09),"brushed_metal")
box("keyboard_shelf",(0,.26,-.43),(.7,.43,.08),"galvanised",.008)
for i in range(6): box("key_%s"%i,(-.26+i*.105,.47,-.42),(.07,.015,.09),"industrial_plastic",.003)
for z in [-.56,-.48,-.4]: box("rear_vent_%s"%z,(0,-.36,z),(.46,.012,.025),"rubber",0)
text("id","LINK 02",(-.26,.25,.61),.05)

begin("security_camera_housing", "props", [0.42,0.65,0.28])
box("mount",(0,-.25,0),(.12,.35,.12),"galvanised")
box("housing",(0,.09,0),(.42,.43,.28),"painted_steel")
box("lens_frame",(0,.32,0),(.25,.035,.2),"rubber")
cylinder("lens",(0,.345,0),.07,.04,"dirty_glass",16,rotation=(math.pi/2,0,0))

begin("industrial_light", "environment", [1.5,0.42,0.17])
box("body",(0,0,0),(1.5,.42,.17),"dark_steel")
box("diffuser",(0,0,-.102),(1.25,.27,.035),"label",.006)
for x in [-.64,.64]: box("clamp_%s"%x,(x,0,-.08),(.065,.36,.06),"galvanised")

begin("emergency_light", "environment", [0.36,0.18,0.28])
box("body",(0,0,0),(.36,.18,.28),"dark_steel")
box("lens",(0,.098,0),(.29,.02,.18),"indicator_red",.006)
box("guard",(0,.11,-.09),(.31,.025,.023),"galvanised")

begin("wall_panel", "environment", [1.2,0.14,1.6])
box("recess",(0,0,0),(1.2,.14,1.6),"dark_steel")
box("inner",(0,.075,0),(1.08,.025,1.48),"painted_steel")
bolts("screw",[-.49,.49],[-.69,.69],.094)

begin("warning_sign_frame", "environment", [0.72,0.08,0.30])
box("back",(0,0,0),(.72,.08,.30),"dark_steel")
box("face",(0,.045,0),(.66,.015,.24),"warning_paint",.002)
text("legend","HIGH VOLTAGE",(-.28,.058,-.035),.060,"dark_steel")

begin("maintenance_hatch", "environment", [0.9,0.12,0.72])
box("frame",(0,0,0),(.9,.12,.72),"dark_steel")
box("leaf",(0,.072,0),(.82,.025,.64),"painted_steel")
box("handle",(.24,.09,0),(.08,.045,.25),"brushed_metal")
bolts("screw",[-.35,.35],[-.25,.25],.091)

begin("security_console", "props", [1.18,0.58,0.86])
box("pedestal",(0,-.05,-.18),(1.16,.49,.56),"dark_steel")
box("angled_top",(0,.22,.16),(1.18,.42,.22),"painted_steel")
box("screen_bezel",(0,.315,.13),(1.05,.045,.53),"rubber")
for x in [-.42,.42]: box("toggle_guard_%s"%x,(x,.45,-.22),(.16,.13,.08),"brushed_metal")
for x in [-.38,-.24,-.1,.04,.18,.32]: box("key_%s"%x,(x,.46,-.27),(.09,.045,.055),"industrial_plastic")
text("id","SECURITY / 04",(-.43,.37,.43),.046)

begin("transfer_hatch", "props", [1.2,0.58,0.84])
box("housing",(0,0,0),(1.2,.58,.84),"dark_steel",.024)
box("mouth_recess",(0,.31,0),(1.02,.03,.54),"rubber")
box("tray",(0,.34,-.18),(.93,.45,.055),"stainless")
box("HatchLeaf",(0,.35,.27),(.99,.06,.18),"painted_steel")
for x in [-.49,.49]: box("rail_%s"%x,(x,.37,-.02),(.045,.45,.39),"brushed_metal")
for y in [-.12,0,.12]: cylinder("roller_%s"%y,(0,.35,y),.026,.88,"stainless",12,rotation=(0,math.pi/2,0))
box("Latch",(.45,.41,.29),(.09,.08,.2),"warning_paint")
text("id","TRANSFER / 06",(-.46,.38,.43),.048)

begin("airlock_door", "props", [2.6,0.28,2.7])
box("pressure_leaf",(0,0,0),(2.6,.28,2.7),"dark_steel",.03)
box("inset",(0,.15,0),(2.37,.023,2.45),"painted_steel",.01)
for x in [-1.02,0,1.02]: box("reinforcement_%s"%x,(x,.178,0),(.09,.055,2.38),"galvanised")
for z in [-1.09,1.09]: box("crossbar_%s"%z,(0,.179,z),(2.33,.06,.10),"brushed_metal")
box("seal_left",(-1.25,.14,0),(.05,.055,2.57),"rubber")
box("seal_right",(1.25,.14,0),(.05,.055,2.57),"rubber")
box("inspection_window",(0,.20,.48),(.56,.026,.24),"dirty_glass")
for x in [-.48,.48]: box("locking_bolt_%s"%x,(x,.22,-.73),(.15,.08,.19),"stainless")
box("status",(0,.21,-.75),(.27,.02,.055),"indicator_green")
text("id","AIRLOCK / KEEP CLEAR",(-.78,.23,-.35),.060)

begin("generator_control_unit", "props", [0.95,0.56,1.35])
box("cabinet",(0,0,0),(.95,.56,1.35),"dark_steel",.025)
box("door",(0,.29,0),(.85,.025,1.23),"painted_steel")
box("meter",(0,.31,.33),(.62,.025,.32),"industrial_plastic")
for i,x in enumerate([-.26,0,.26]):
    cylinder("control_%s"%i,(x,.36,-.22),.07,.045,"brushed_metal",16,rotation=(math.pi/2,0,0))
    cylinder("indicator_%s"%i,(x,.345,.1),.025,.02,"indicator_green" if i==0 else "indicator_red",12,rotation=(math.pi/2,0,0))
text("id","CONTACTOR / REMOTE",(-.37,.32,.51),.044)

# Validate transforms/names, save editable source and export each collection as a deterministic GLB.
invalid = []
manifest = {"blender_version": bpy.app.version_string, "unit": "metre", "assets": []}
for name, asset in ASSETS.items():
    objects = asset["objects"]
    for obj in objects:
        if not obj.name.startswith("VIS_") or min(obj.dimensions) <= 0 or max(abs(x-1) for x in obj.scale) > 1e-4:
            invalid.append(obj.name)
    faces = sum(len(obj.data.polygons) for obj in objects)
    if faces > 6000: invalid.append(name+": polygon budget")
    manifest["assets"].append({"name": name, "category": asset["category"], "bounds_m": asset["bounds"], "mesh_objects": len(objects), "triangles_max": faces*2, "collision": "Godot primitive"})
if invalid: raise RuntimeError("Invalid asset(s): " + ", ".join(invalid))
SOURCE.parent.mkdir(parents=True, exist_ok=True)
bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE))
for name, asset in ASSETS.items():
    bpy.ops.object.select_all(action="DESELECT")
    for obj in asset["objects"]: obj.select_set(True)
    bpy.context.view_layer.objects.active = asset["objects"][0]
    output = OUT / asset["category"] / (name + ".glb")
    output.parent.mkdir(parents=True, exist_ok=True)
    temporary = output.with_suffix(".tmp.glb")
    bpy.ops.export_scene.gltf(filepath=str(temporary), export_format="GLB", use_selection=True, export_yup=True)
    data = temporary.read_bytes()
    if not output.exists() or output.read_bytes() != data:
        output.write_bytes(data)
    temporary.unlink()
    print("KIT_EXPORT", name, len(data))
REPORT.parent.mkdir(parents=True, exist_ok=True)
REPORT.write_text(json.dumps(manifest, indent=2)+"\n")
print("KIT_COMPLETE", len(ASSETS), "assets")
