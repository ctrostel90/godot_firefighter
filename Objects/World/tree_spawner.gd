class_name TreeSpawner extends Node3D

@export var noise_settings : TerrainGeneratorSettings
@export var tree_controller : TreeController

@export var tree_parent:Node3D
@export var trees:Array[TreeBase]

func spawn_trees()->void:
	var space_state = get_world_3d().direct_space_state
	for x in noise_settings.MapSize.x:
		for y in noise_settings.MapSize.y:
			var world_coord := Vector3(
				(x * noise_settings.GridScale.x),
				0,
				y * noise_settings.GridScale.y)
			var query := PhysicsRayQueryParameters3D.create(world_coord + Vector3.UP * 500,
															world_coord + Vector3.DOWN * 10)
			var result = space_state.intersect_ray(query)
			if result.size() == 0:
				continue
			
			if result['position'].y > 17:
				world_coord.y = result['position'].y
				trees[0].spawn_tree(tree_parent,tree_controller,world_coord)


func _on_button_2_pressed() -> void:
	spawn_trees()
