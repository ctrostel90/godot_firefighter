class_name TreeBase extends Resource

@export var mesh:Mesh
@export var Description := 'Basic'
@export var Age := 0
@export var MaturityAge := 10

var mesh_instance : MeshInstance3D
var mesh_height : float = 0.5

func spawn_tree(parent : Node3D, controller:TreeController, world_position:Vector3) -> void:
	mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = mesh
	world_position.y += mesh_height
	mesh_instance.position = world_position
	controller.tree_map.append(self)
	if Engine.is_editor_hint():
		mesh.owner = parent.get_tree().edited_scene_root
		mesh_instance.owner = parent.get_tree().edited_scene_root
	parent.add_child(mesh_instance)
