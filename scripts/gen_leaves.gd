# Godot version 4

# Creates a mesh with leaf billboards. Iterates over all meshes in the node and generates quads on their surfaces.
# Quads have uv: [0, 0], [1, 0], [1, 1], [0, 1].

extends Node3D

@export var density = 0.1
@export var leaf_material: Material
@export var depth_variation = 0.1
@export var depth_bias = 0.0
@export var use_bias_direction = false
@export var bias_direction = Vector3(0, 1, 0)
@export var hide_original_meshes = true
@export var cast_shadows = true

# UVs const
var UVS = [
	Vector2(0, 0),
	Vector2(1, 0),
	Vector2(1, 1),
	Vector2(0, 1)
]

# Called when the node enters the scene tree for the first time.
func _ready():

	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var indices = PackedInt32Array()
	var uvs = PackedVector2Array()

	# Get all meshes in the node.
	for child in get_children():
		if child is MeshInstance3D:

			# Transform to convert from child space to parent space.
			# var childToParent = global_transform.inverse() * child.global_transform
			var childToParent = Transform3D.IDENTITY

			var mesh_instance = child as MeshInstance3D
			var mesh = mesh_instance.get_mesh()
			if mesh is Mesh:

				# Make mesh invisible.
				if hide_original_meshes:
					mesh_instance.hide()

				var mesh_data = mesh as Mesh
				var surface_count = mesh_data.get_surface_count()

				for i in range(surface_count):
					var surface = mesh_data.surface_get_arrays(i)
					var surface_vertices = surface[Mesh.ARRAY_VERTEX]
					var surface_indices = surface[Mesh.ARRAY_INDEX]
					var surface_normals = surface[Mesh.ARRAY_NORMAL]

					# Assume surface is a triangle list.
					# For each triangle, sample random points uniformly on the triangle and create a quad.

					for l in range(0, surface_indices.size(), 3):
						var i0 = surface_indices[l]
						var i1 = surface_indices[l + 1]
						var i2 = surface_indices[l + 2]

						var v0 = surface_vertices[i0]
						var v1 = surface_vertices[i1]
						var v2 = surface_vertices[i2]

						var normal = (childToParent * surface_normals[i0]).normalized()
						var depth = (randf() - 0.5) * depth_variation + depth_bias

						var area = 0.5 * ((v1 - v0).cross(v2 - v0)).length()
						var num_leaves = area * density

						if use_bias_direction:
							var worldNormal = child.global_transform.basis * surface_normals[i0]
							var dot = worldNormal.dot(bias_direction)
							if dot < 0:
								dot = 0
							num_leaves *= dot

						var num_leaves_fract = num_leaves - int(num_leaves)
						num_leaves = int(num_leaves)
						if randf() < num_leaves_fract:
							num_leaves += 1

						for j in range(num_leaves):
							# https://abhila.sh/writing/5/Random_Sampling.html#:~:text=Uniform%20sampling%20in%20a%20Triangle,distributed%20random%20points%20inside%20it.&text=This%20works%20for%20any%20triangle,the%20parallellogram%20(shown%20below).
							var r1 = randf()
							var r2 = randf()
							var a = 1 - sqrt(r1)
							var b = (1 - r2) * sqrt(r1)
							var c = r2 * sqrt(r1)
							var point = a * v0 + b * v1 + c * v2

							point = childToParent * point

							point += normal * depth
	
							# Add verts and uvs for the quad.
							for k in range(4):
								vertices.append(point)
								normals.append(normal)
								uvs.append(UVS[k])
							
							# Create two triangles for the quad.
							indices.append(vertices.size() - 2)
							indices.append(vertices.size() - 3)
							indices.append(vertices.size() - 4)

							indices.append(vertices.size() - 1)
							indices.append(vertices.size() - 2)
							indices.append(vertices.size() - 4)
	
	print("Number of leaves: ", vertices.size() / 4.0)

	# Create the mesh.
	var suface_array = []
	suface_array.resize(Mesh.ARRAY_MAX)
	suface_array[Mesh.ARRAY_VERTEX] = vertices
	suface_array[Mesh.ARRAY_NORMAL] = normals
	suface_array[Mesh.ARRAY_INDEX] = indices
	suface_array[Mesh.ARRAY_TEX_UV] = uvs

	var leaves_mesh = ArrayMesh.new()
	leaves_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, suface_array)

	# Create the mesh instance.
	var leaves_mesh_instance = MeshInstance3D.new()
	leaves_mesh_instance.set_mesh(leaves_mesh)
	leaves_mesh_instance.set_material_override(leaf_material)
	leaves_mesh_instance.set_cast_shadows_setting(cast_shadows)
	add_child(leaves_mesh_instance)
