extends Node

# true = desbloqueado, false = bloqueado
var level_unlocked: Array[bool] = [true, false, false]
var level_completed: Array[bool] = [false, false, false]

var level_scenes: Array[String] = [
	"res://scenes/nivel1.tscn",
	"res://scenes/nivel2.tscn",
	"res://scenes/nivel3.tscn"
]

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
