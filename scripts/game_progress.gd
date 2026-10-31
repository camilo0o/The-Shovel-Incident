extends Node

signal arma_cambiada(arma: ArmaData)
signal monedas_cambiadas(cantidad: int)
signal carpinchos_cambiados(cantidad: int)
signal skin_cambiada(skin: SkinData)
signal carpi_evento(evento: StringName)   # Carpi reacciona: &"kill", &"fallo"

var monedas := 0
var carpinchos := 0
var skins_desbloqueadas: Array[SkinData] = []
var skin_equipada: SkinData = preload("res://resources/skins/ropa_basica.tres")
var armas_desbloqueadas: Array[ArmaData] = []
# true = desbloqueado, false = bloqueado
var level_unlocked: Array[bool] = [true, false, false]
var level_completed: Array[bool] = [false, false, false]
var municion := 60
var vida_jugador := -1

var level_scenes: Array[String] = [
	"res://scenes/level1.tscn",
	"res://scenes/level2.tscn",
	"res://scenes/level3.tscn"
]

var arma_equipada: ArmaData = null

func equipar_arma(arma: ArmaData) -> void:
	if arma != null and not esta_desbloqueada(arma):
		return
	arma_equipada = arma
	arma_cambiada.emit(arma)

func agregar_monedas(cantidad: int) -> void:
	monedas += cantidad
	monedas_cambiadas.emit(monedas)

func esta_desbloqueada(arma: ArmaData) -> bool:
	return arma.costo <= 0 or arma in armas_desbloqueadas

func puede_comprar(arma: ArmaData) -> bool:
	return not esta_desbloqueada(arma) and monedas >= arma.costo

func comprar_arma(arma: ArmaData) -> bool:
	if not puede_comprar(arma):
		return false
	monedas -= arma.costo
	armas_desbloqueadas.append(arma)
	monedas_cambiadas.emit(monedas)
	return true


func agregar_carpinchos(cantidad: int) -> void:
	carpinchos += cantidad
	carpinchos_cambiados.emit(carpinchos)

func skin_desbloqueada(skin: SkinData) -> bool:
	return skin == null or skin.costo <= 0 or skin in skins_desbloqueadas

func puede_comprar_skin(skin: SkinData) -> bool:
	return skin != null and not skin_desbloqueada(skin) and carpinchos >= skin.costo

func comprar_skin(skin: SkinData) -> bool:
	if not puede_comprar_skin(skin):
		return false
	carpinchos -= skin.costo
	skins_desbloqueadas.append(skin)
	carpinchos_cambiados.emit(carpinchos)
	return true

func equipar_skin(skin: SkinData) -> void:
	if not skin_desbloqueada(skin):
		return
	skin_equipada = skin
	skin_cambiada.emit(skin)

func complete_level(index: int) -> void:
	level_completed[index] = true
	var next = index + 1
	if next < level_unlocked.size():
		level_unlocked[next] = true
		
func is_unlocked(index: int) -> bool:
	return level_unlocked[index]

func go_to_level(index: int) -> void:
	if is_unlocked(index):
		Fade.cambiar_escena(level_scenes[index])



const ESCENA_POR_DEFECTO := "res://scenes/main_menu.tscn"

var _historial: Array[String] = []
var _escena_actual := ""
var _volviendo := false

func _process(_delta: float) -> void:
	var escena := get_tree().current_scene
	if escena == null:
		return
	var ruta := escena.scene_file_path
	if ruta == _escena_actual:
		return

	if _volviendo:
		_volviendo = false
	else:
		var previa := _historial.find(ruta)
		if previa != -1:
			_historial.resize(previa)
		elif _escena_actual != "":
			_historial.append(_escena_actual)
	_escena_actual = ruta

var _cambiando := false

func volver() -> void:
	if _cambiando:
		return
	_cambiando = true

	var destino := ESCENA_POR_DEFECTO
	if not _historial.is_empty():
		destino = _historial.pop_back()
	_volviendo = true

	await Fade.cambiar_escena(destino)
	_cambiando = false
