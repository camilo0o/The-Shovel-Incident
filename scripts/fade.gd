extends CanvasLayer

@onready var color_rect: ColorRect = $ColorRect

var _cambiando := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	color_rect.color = Color(0, 0, 0, 0)
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

func fade(target_alpha: float, duration: float = 1.0) -> Tween:
	var tween := create_tween()
	tween.tween_property(color_rect, "color:a", target_alpha, duration)
	return tween

func cambiar_escena(path: String, duracion: float = 0.8) -> void:
	if _cambiando:
		return
	_cambiando = true
	get_tree().paused = true
	color_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	await fade(1.0, duracion).finished
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await get_tree().process_frame
	await fade(0.0, duracion).finished
	get_tree().paused = false
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cambiando = false

func recargar_escena(duracion: float = 0.8) -> void:
	cambiar_escena(get_tree().current_scene.scene_file_path, duracion)
