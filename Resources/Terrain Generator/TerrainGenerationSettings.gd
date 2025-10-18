class_name TerrainGeneratorSettings
extends Resource

@export var MapSize: Vector2i
@export var Seed: int
@export var NoiseSystem : FastNoiseLite

@export var GridScale := Vector2.ONE
@export var HeightCurve : Curve
@export var HeightMultiplier : float =  1.0
