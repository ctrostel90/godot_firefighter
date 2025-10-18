class_name World extends Node

var GridSize := Vector2i.ZERO : 
	set(value):
		GridSize = value
		GridCells.clear()
		for cell:int in range(value.x * value.y):
			GridCells.append(WorldCell.new())
var GridCells : Array[WorldCell]
