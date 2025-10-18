class_name InteractionController extends Node

@export var terrainparent:Node3D

func terrain_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		var mesh_instance:MeshInstance3D = terrainparent.get_child(0)
		var arrays:PackedVector3Array = mesh_instance.mesh.surface_get_arrays(0)
		print(arrays.size())
		#var cell_coord := Vector2i(event_position.x / 2,event_position.z / 2)
		#var i0 :int = cell_coord.x * 500 + cell_coord.y
		#print("%s , %s , %s"%[arrays[i0],arrays[i0 + 1], arrays[i0+2]])
