class_name SimulationMap
extends Resource

@export var name := ''
@export var map_width : int = 0
@export var map_height : int = 0
var data:PackedFloat32Array

func initialize_data(width:int, height: int, new_data:PackedFloat32Array) -> void:
	map_width = width
	map_height = height
	data = new_data	

func get_data_as_image() -> Image:
	return Image.create_from_data(map_width,map_height,false,Image.FORMAT_RF,data.to_byte_array())

func get_value_at_coord(coord:Vector2i) -> float:
	return data[coord.x * map_height + coord.y]
