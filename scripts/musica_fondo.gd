extends Node

# Música compartida por el menú principal y el garage.

var musica: AudioStream = preload("res://assets/audio/music/menu_garage.mp3")
const ESCENAS_CON_MUSICA: Array[String] = [
	"res://scenes/main_menu.tscn",
	"res://scenes/garage.tscn",
	"res://scenes/settings.tscn",
]
const VOLUMEN_DB := -6.0
const SILENCIO_DB := -60.0
const DURACION_FADE := 0.6

var _player: AudioStreamPlayer
var _escena_actual := ""
var _tween: Tween

func _ready() -> void:
	if "loop" in musica:
		musica.loop = true
	_player = AudioStreamPlayer.new()
	_player.stream = musica
	_player.volume_db = SILENCIO_DB
	add_child(_player)

func _process(_delta: float) -> void:
	var escena := get_tree().current_scene
	if escena == null:
		return   # justo en medio de un cambio de escena
	var ruta := escena.scene_file_path
	if ruta == _escena_actual:
		return
	_escena_actual = ruta

	if ruta in ESCENAS_CON_MUSICA:
		_subir()
	else:
		_bajar()


func _subir() -> void:
	if _tween != null:
		_tween.kill()
	if not _player.playing:
		_player.volume_db = SILENCIO_DB
		_player.play()
	_tween = create_tween()
	_tween.tween_property(_player, "volume_db", VOLUMEN_DB, DURACION_FADE)


func _bajar() -> void:
	if not _player.playing:
		return
	if _tween != null:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_player, "volume_db", SILENCIO_DB, DURACION_FADE)
	_tween.tween_callback(_player.stop)
