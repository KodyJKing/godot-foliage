import bpy
import bmesh

def set_uvs(uv_layer, face, uvs):
    for loop, uv in zip(face.loops, uvs):
        loop[uv_layer].uv = uv

def main():
    # Make sure we're in object mode and have a valid object selected
    if bpy.context.object.mode != 'OBJECT':
        bpy.ops.object.mode_set(mode='OBJECT')
    
    obj = bpy.context.active_object
    if not obj or obj.type != 'MESH':
        print("No mesh object selected")
        return

    # Enter edit mode to access bmesh data
    bpy.ops.object.mode_set(mode='EDIT')
    bm = bmesh.from_edit_mesh(obj.data)

    # Get or create the UV layer
    uv_layer = bm.loops.layers.uv.verify()

    # Define the UV coordinates
    uvs = [(0, 0), (0, 1), (1, 1), (1, 0)]

    # Iterate over all faces and apply the UV coordinates to quads
    for face in bm.faces:
        if len(face.verts) == 4:
            set_uvs(uv_layer, face, uvs)

    # Update the mesh and return to object mode
    bmesh.update_edit_mesh(obj.data)
    bpy.ops.object.mode_set(mode='OBJECT')

class SetLeafUVs(bpy.types.Operator):
    bl_idname = "script.set_leaf_uvs"
    bl_label = "Set Leaf UVs"
    bl_options = {'REGISTER', 'UNDO'}

    def execute(self, context):
        main()
        return {'FINISHED'}

# Add to UV menu
def menu_func(self, context):
    self.layout.operator("script.set_leaf_uvs", text="Set Leaf UVs")

def register():
    bpy.utils.register_class(SetLeafUVs)
    bpy.types.VIEW3D_MT_uv_map.append(menu_func)

if __name__ == "__main__":
    main()