extends Node2D
# Hace aparecer ítems de munición de forma aleatoria (tiempo y ubicación).
#
# Cómo usarlo en un nivel:
#   1. Agregar este script a un Node2D dentro de la escena del nivel (ej. "MunicionSpawner").
#   2. Colocar dentro de ese nodo uno o más Marker2D, en los puntos del mapa donde
#      se quiere que puedan aparecer los ítems (lugares caminables, sin paredes).
#   3. En el inspector, arrastrar esos Marker2D a la lista "Puntos Spawn".

@export var municion_scene: PackedScene = preload("res://scenes/municion_pickup.tscn")
@export var puntos_spawn: Array[Marker2D] = []

@export_group("Tiempos (segundos)")
@export var intervalo_minimo := 8.0
@export var intervalo_maximo := 15.0

@export_group("Límite")
@export var maximo_activos := 4   # cuántos ítems puede haber en el mapa a la vez

var _activos := 0


func _ready() -> void:
	_programar_siguiente()


func _programar_siguiente() -> void:
	var espera := randf_range(intervalo_minimo, intervalo_maximo)
	await get_tree().create_timer(espera).timeout
	_intentar_spawnear()
	_programar_siguiente()


func _intentar_spawnear() -> void:
	if puntos_spawn.is_empty() or _activos >= maximo_activos:
		return

	var arma := GameProgress.arma_equipada
	if arma == null or arma.tipo != ArmaData.Tipo.DISTANCIA:
		return   # sin arma a distancia equipada, no tiene sentido spawnear munición

	var punto := puntos_spawn[randi() % puntos_spawn.size()]
	if punto == null:
		return

	var item := municion_scene.instantiate()
	get_tree().current_scene.add_child(item)
	item.global_position = punto.global_position

	_activos += 1
	item.tree_exited.connect(func(): _activos -= 1)
	
