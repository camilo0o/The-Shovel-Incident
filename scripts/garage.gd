extends Node2D

@onready var tilemap: TileMapLayer = $TileMapLayer
@onready var camera: Camera2D = $Camera2D

func _ready():
	encuadrar_nivel()

func encuadrar_nivel():
	var used_rect = tilemap.get_used_rect()
	var tile_size = tilemap.tile_set.tile_size
	var level_size = Vector2(used_rect.size) * Vector2(tile_size)
	var level_center = Vector2(used_rect.position) * Vector2(tile_size) + level_size / 2.0
	
	var viewport_size = get_viewport_rect().size
	var zoom_factor = max(level_size.x / viewport_size.x, level_size.y / viewport_size.y)
	
	camera.zoom = Vector2.ONE / zoom_factor
	camera.position = level_center
