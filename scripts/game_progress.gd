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
