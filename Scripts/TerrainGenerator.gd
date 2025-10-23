@tool
class_name TerrainGenerator extends Node

signal TerrainGenerated

@export var NoiseSettings : TerrainGeneratorSettings
@export var mesh_parent : Node3D

@export var interaction_controller:InteractionController

var _debug : bool = false
var _verticies : PackedVector3Array
var _normals : PackedVector3Array
var height_map : PackedByteArray

@export var Generate:bool : 
	set(value):
		for child in mesh_parent.get_children():
			child.queue_free()
		generate_mesh()
		_debug = true


func generate_mesh() -> void:
	var noise_map : PackedVector3Array = GenerateNoiseMap()
	var arr_mesh : ArrayMesh = GenerateMesh(noise_map)
	var _mesh : MeshInstance3D = MeshInstance3D.new()
	_mesh.mesh = arr_mesh
	var material = StandardMaterial3D.new()
	material.heightmap_texture = create_texture()
	_mesh.material_override = material
	
	var static_body := StaticBody3D.new()
	var collision_shape := CollisionShape3D.new()
	var shape : ConcavePolygonShape3D = arr_mesh.create_trimesh_shape()
	collision_shape.shape = shape
	static_body.add_child(collision_shape)
	#static_body.connect('input_event',interaction_controller.terrain_input_event)
	_mesh.add_child(static_body)
	mesh_parent.add_child(_mesh)
	_mesh.owner = get_tree().edited_scene_root
	collision_shape.owner = get_tree().edited_scene_root
	static_body.owner = get_tree().edited_scene_root

func create_texture() -> ImageTexture:
	var img = Image.create_from_data(NoiseSettings.MapSize.x,NoiseSettings.MapSize.y,false,Image.FORMAT_L8,height_map)
	TerrainGenerated.emit(img)
	return ImageTexture.create_from_image(img)

func GenerateNoiseMap() -> PackedVector3Array:
	var map:PackedVector3Array = []
	NoiseSettings.NoiseSystem.seed = NoiseSettings.Seed
	
	for x in range(NoiseSettings.MapSize.x + 1):
		for z in range(NoiseSettings.MapSize.y + 1):
			var samplePos := Vector2(x,z)
			var height: float = (NoiseSettings.NoiseSystem.get_noise_2d(samplePos.x,samplePos.y) + 1) / 2.0
			height = NoiseSettings.HeightCurve.sample(height) 
			map.append(Vector3(
				x * NoiseSettings.GridScale.x,
				height * NoiseSettings.HeightMultiplier,
				z * NoiseSettings.GridScale.y
			))
	height_map.clear()
	for x in range(NoiseSettings.MapSize.x):
		for z in range(NoiseSettings.MapSize.y):
			var samplePos := Vector2(x,z)
			var height: float = (NoiseSettings.NoiseSystem.get_noise_2d(samplePos.x,samplePos.y) + 1) / 2.0
			height = NoiseSettings.HeightCurve.sample(height) 
			height_map.append(int(height * 255))
	return map


func GenerateMesh(noise_map:PackedVector3Array) -> ArrayMesh:
	var verts = PackedVector3Array()
	var uvs = PackedVector2Array()
	var normals = PackedVector3Array()
	var indicies = PackedInt32Array()
	verts = noise_map
	
	for vertex in verts:
		uvs.append(Vector2(vertex.x / float(NoiseSettings.GridScale.x * NoiseSettings.MapSize.x), vertex.z / float(NoiseSettings.GridScale.y * NoiseSettings.MapSize.y)))
		#uvs.append(Vector2.ONE)
		normals.append(vertex.normalized())
		var gridcoord:Vector2i = Vector2i(Vector2(vertex.x / float(NoiseSettings.GridScale.x), vertex.z / float(NoiseSettings.GridScale.y)))
		
		if gridcoord.x > 0 and gridcoord.y > 0:
			indicies.append(gridcoord.x * (NoiseSettings.MapSize.y + 1) + gridcoord.y)
			indicies.append((gridcoord.x-1) * (NoiseSettings.MapSize.y + 1) + gridcoord.y)
			indicies.append((gridcoord.x-1) * (NoiseSettings.MapSize.y + 1) + gridcoord.y-1)
			
			indicies.append(gridcoord.x * (NoiseSettings.MapSize.y + 1) + gridcoord.y)
			indicies.append((gridcoord.x-1) * (NoiseSettings.MapSize.y + 1) + gridcoord.y-1)
			indicies.append(gridcoord.x * (NoiseSettings.MapSize.y + 1) + gridcoord.y-1)
	
	normals.resize(verts.size())
	for vertex in verts:
		vertex = Vector3.ZERO
	for vertex in verts:
		var gridcoord:Vector2i = Vector2i(Vector2(vertex.x / float(NoiseSettings.GridScale.x), vertex.z / float(NoiseSettings.GridScale.y)))
		if gridcoord.x == NoiseSettings.MapSize.x and gridcoord.y == NoiseSettings.MapSize.y:
			break
		var i0 = GetIndexFromVector(gridcoord,NoiseSettings.MapSize)
		var i1 = GetIndexFromVector(Vector2i(gridcoord.x + 1,gridcoord.y), NoiseSettings.MapSize)
		var i2 = GetIndexFromVector(gridcoord + Vector2i.ONE, NoiseSettings.MapSize)
		var i3 = GetIndexFromVector(Vector2i(gridcoord.x,gridcoord.y + 1), NoiseSettings.MapSize)
		
		var v0 = verts[i0]
		var v1 = verts[i1]
		var v2 = verts[i2]
		var v3 = verts[i3]
		var normal = calculate_triangle_normal(v0, v1, v2)
		normals[i0] += normal
		normals[i1] += normal
		normals[i2] += normal
		
		normal = calculate_triangle_normal(v0, v2, v3)
		normals[i0] += normal
		normals[i2] += normal
		normals[i3] += normal
	
	for normal in normals:
		normal = normal.normalized()
	
	_normals = normals
	_verticies = verts
	var arr_mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indicies
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return arr_mesh

func _physics_process(_delta: float) -> void:
	pass
	#if not _debug:
		#return
	#for i in range(_normals.size()):
		#DebugDraw3D.draw_arrow(_verticies[i],_normals[i],Color.BLUE,0.05)


func calculate_triangle_normal(v0: Vector3, v1: Vector3, v2: Vector3) -> Vector3:
	var edge1 = v1 - v0
	var edge2 = v2 - v0
	return edge1.cross(edge2) * -1

func GetIndexFromVector(coordinates:Vector2i, mapsize:Vector2i) -> int:
	return coordinates.x * mapsize.y + coordinates.y	

func GetCoordFromIndex(index:int, mapsize:Vector2i) -> Vector2i:
	@warning_ignore("integer_division")
	var x = index / mapsize.x
	var y = index % mapsize.y
	return Vector2i(x,y)


func _on_button_pressed() -> void:
	generate_mesh()
