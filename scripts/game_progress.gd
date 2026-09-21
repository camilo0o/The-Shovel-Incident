extends Node

signal arma_cambiada(arma: ArmaData)

# true = desbloqueado, false = bloqueado
var level_unlocked: Array[bool] = [true, false, false]
var level_completed: Array[bool] = [false, false, false]

var level_scenes: Array[String] = [
	"res://scenes/level1.tscn",
	"res://scenes/level2.tscn",
	"res://scenes/level3.tscn"
]

# Arma elegida en la armería del garage (null = solo puños).
# Vive acá porque este autoload sobrevive a los cambios de escena.
var arma_equipada: ArmaData = null

func equipar_arma(arma: ArmaData) -> void:
	arma_equipada = arma
	arma_cambiada.emit(arma)

func complete_level(index: int) -> void:
	level_completed[index] = true
	var next = index + 1
	if next < level_unlocked.size():
		level_unlocked[next] = true
		
func is_unlocked(index: int) -> bool:
	return level_unlocked[index]

func go_to_level(index: int) -> void:
	if is_unlocked(index):
		get_tree().change_scene_to_file(level_scenes[index])


# Historial de escenas para el botón "Volver" del menú de pausa.
# Se arma solo: cada frame mira cuál es la escena actual y, cuando cambia,
# guarda la anterior. Así no hay que tocar a quienes llaman a
# change_scene_to_file.
const ESCENA_POR_DEFECTO := "res://scenes/main_menu.tscn"

var _historial: Array[String] = []
var _escena_actual := ""
var _volviendo := false

func _process(_delta: float) -> void:
	var escena := get_tree().current_scene
	if escena == null:
		return   # justo en medio de un cambio de escena
	var ruta := escena.scene_file_path
	if ruta == _escena_actual:
		return   # misma escena (p. ej. reinicio al morir): no cuenta como avance

	if _volviendo:
		_volviendo = false   # el destino ya se sacó del historial en volver()
	else:
		var previa := _historial.find(ruta)
		if previa != -1:
			# Se llegó a una escena ya visitada por otro camino (p. ej. el
			# botón Volver del selector de niveles): se descarta lo posterior.
			_historial.resize(previa)
		elif _escena_actual != "":
			_historial.append(_escena_actual)
	_escena_actual = ruta

# Vuelve a la escena anterior. Sin historial, cae al menú principal.
func volver() -> void:
	var destino := ESCENA_POR_DEFECTO
	if not _historial.is_empty():
		destino = _historial.pop_back()
	_volviendo = true
	get_tree().change_scene_to_file(destino)
