extends Node

const MENU := "res://assets/audio/music/menu_garage.mp3"

const PISTAS := {
	"res://scenes/main_menu.tscn": [MENU, -6.0],
	"res://scenes/garage.tscn": [MENU, -6.0],
	"res://scenes/settings.tscn": [MENU, -6.0],
	"res://scenes/level1.tscn": ["res://assets/audio/music/fondo_level1_music.mp3", -18.5],
	"res://scenes/level2.tscn": ["res://assets/audio/music/fondo_level2_music.mp3", -19.9],
	"res://scenes/level3.tscn": ["res://assets/audio/music/fondo_level3.mp3", -20.3],
	"res://scenes/boss_room_1.tscn": ["res://assets/audio/music/horror_bossroom1.mp3", -18.9],
	"res://scenes/boss_room_2.tscn": ["res://assets/audio/music/churchMusic_bossroom2.mp3", -18.9],
	"res://scenes/boss_room_3.tscn": ["res://assets/audio/music/creepy_bossroom3.mp3", -20.3],
}
const SILENCIO_DB := -60.0
const DURACION_FADE := 0.6

var _player: AudioStreamPlayer
var _escena_actual := ""
var _pista_sonando := ""
var _tween: Tween
var _cache := {}


func _ready() -> void:
	# Que siga andando aunque el árbol esté en pausa (Fade, menú de pausa).
	process_mode = Node.PROCESS_MODE_ALWAYS
	_player = AudioStreamPlayer.new()
	_player.bus = &"Musica"
	_player.volume_db = SILENCIO_DB
	if OS.has_feature("web"):
		_player.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
	add_child(_player)


func _process(_delta: float) -> void:
	var escena := get_tree().current_scene
	if escena == null:
		return   # justo en medio de un cambio de escena
	var ruta := escena.scene_file_path
	if ruta == _escena_actual:
		return
	_escena_actual = ruta

	if PISTAS.has(ruta):
		_sonar(PISTAS[ruta][0], PISTAS[ruta][1])
	else:
		_bajar()


func _sonar(mp3: String, volumen_db: float) -> void:
	if _tween != null:
		_tween.kill()
	if _player.playing and _pista_sonando == mp3:
		# Misma pista (menú -> garage): sigue sonando, solo se ajusta el volumen.
		_tween = create_tween()
		_tween.tween_property(_player, "volume_db", volumen_db, DURACION_FADE)
	elif _player.playing:
		# Otra pista: baja la actual y después arranca la nueva.
		_tween = create_tween()
		_tween.tween_property(_player, "volume_db", SILENCIO_DB, DURACION_FADE)
		_tween.tween_callback(_arrancar.bind(mp3, volumen_db))
	else:
		_arrancar(mp3, volumen_db)


func _arrancar(mp3: String, volumen_db: float) -> void:
	var stream := _cargar(mp3)
	if stream == null:
		return
	_pista_sonando = mp3
	_player.stream = stream
	_player.volume_db = SILENCIO_DB
	_player.play()
	_tween = create_tween()
	_tween.tween_property(_player, "volume_db", volumen_db, DURACION_FADE)


func _bajar() -> void:
	if not _player.playing:
		return
	if _tween != null:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_player, "volume_db", SILENCIO_DB, DURACION_FADE)
	_tween.tween_callback(_detener)


func _detener() -> void:
	_player.stop()
	_pista_sonando = ""


func _cargar(mp3: String) -> AudioStream:
	if _cache.has(mp3):
		return _cache[mp3]
	var stream: AudioStream = load(mp3)
	if stream == null:
		push_warning("MusicaFondo: no se pudo cargar " + mp3)
		return null
	if "loop" in stream:
		stream.loop = true
	_cache[mp3] = stream
	return stream
