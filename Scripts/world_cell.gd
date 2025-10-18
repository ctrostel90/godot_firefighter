class_name WorldCell

@export var grid_coordinate := Vector2i.ZERO
@export var _verticies : Array[Vector3] = []

func AddVertex(Vertex:Vector3) -> void:
	assert(_verticies.size()<4)
	_verticies.append(Vertex)

func GetPositionInsideCellFromRatio(_Position:Vector2) -> Vector3:
	return Vector3.ONE

func GetCenterPosition() -> Vector3:
	if _verticies.size() == 0:
		return Vector3.ZERO
	var tmp = Vector3.ZERO
	for vertex in _verticies:
		tmp += vertex
	return tmp / float(_verticies.size())

#
func _init():
	pass

static func GetGridCoordinatesFromVertex(VertexGridPosition:Vector2i,GridSize:Vector2i) -> Array[Vector2i]:
	var grid_coordinates:Array[Vector2i]
	if VertexGridPosition.x != GridSize.x: 
		grid_coordinates.append(VertexGridPosition + Vector2i.RIGHT)
	if VertexGridPosition.y != GridSize.y: 
		grid_coordinates.append(VertexGridPosition + Vector2i.DOWN)
	return grid_coordinates
