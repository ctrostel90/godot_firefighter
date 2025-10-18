class_name TreeBase extends Resource



@export var Description := 'Basic'
@export var Age := 0
@export var MaturityAge := 10

@export_category('Model Details')
@export var mesh:Mesh
@export var shader_override : ShaderMaterial
@export var tree_color := Color.GREEN
@export var spawn_offset := Vector3(0,0.5,0)

var mesh_instance : MeshInstance3D

func spawn_tree(parent : Node3D, controller:TreeController, world_position:Vector3) -> void:
	mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = mesh
	world_position += spawn_offset
	mesh_instance.position = world_position
	
	if shader_override == null:
		var new_material := StandardMaterial3D.new()
		new_material.albedo_color = tree_color
		mesh_instance.mesh.surface_set_material(0,new_material)
	else:
		mesh_instance.mesh.surface_set_material(0,shader_override)
	
	controller.tree_map.append(self)
	if Engine.is_editor_hint():
		mesh.owner = parent.get_tree().edited_scene_root
		mesh_instance.owner = parent.get_tree().edited_scene_root
	parent.add_child(mesh_instance)
