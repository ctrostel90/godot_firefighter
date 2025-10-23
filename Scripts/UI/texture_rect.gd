extends TextureRect

@export var cellular_computer : CellularComputer

func _ready() -> void:
	cellular_computer.connect('TerrainGenerated',on_new_terrain)

func on_new_terrain(image:ImageTexture) -> void:
	texture = image
