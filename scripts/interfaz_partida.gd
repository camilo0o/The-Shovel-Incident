extends Node
@export var ruta_jugador: NodePath = NodePath("..")

@onready var menu_pausa: CanvasLayer = $MenuPausa
@onready var resultado: CanvasLayer = $ResultadoPartida
var _finalizada := false


func _ready() -> void:
	var jugador := get_node(ruta_jugador)
	jugador.murio.connect(_on_jugador_murio)
	GameProgress.nivel_completado.connect(_on_nivel_completado)


func _on_nivel_completado(nivel_index: int) -> void:
	if _finalizada:
		return
	_finalizada = true
	menu_pausa.deshabilitar()
	resultado.mostrar_victoria(nivel_index)


func _on_jugador_murio() -> void:
	if _finalizada:
		return
	_finalizada = true
	menu_pausa.deshabilitar()
	resultado.mostrar_derrota()
