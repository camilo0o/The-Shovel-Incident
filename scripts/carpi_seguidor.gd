class_name CarpiSeguidor
extends Node2D

const FUENTE := preload("res://assets/ui/fonts/Ancient Medium.ttf")

const FRASES := {
	&"inicio": ["¿Que andás bo?", "Arrancamos, estimado.", "Vamo' arriba, loco."],
	&"kill": ["¡Bien ahí, loco!", "Ya tenés la pala en tus manos, estimado...", "¡Qué máquina!", "Uno menos."],
	&"fallo": ["¡Mancooo!!", "¿A quién le pegás, loco?", "Pegale al enemigo, no al aire."],
	&"jefe": ["¡Lo hiciste pelota, loco!", "Se lo comió la pala, estimado.", "¡Bien ahí, campeón!"],
	&"idle": ["Che, ¿no tenés hambre?", "Qué calor hace acá, ¿no?", "¿Seguro que es por acá?", "Yo te cuido la espalda... de lejos."],
}

@export_group("Charla")
@export var tiempo_visible := 2.5
@export var pausa_minima := 3.0            # segundos mínimos entre frases
@export var idle_min := 12.0               # frase random cada tanto
@export var idle_max := 25.0
# Probabilidad de que reaccione a cada evento (1.0 = siempre)
@export_range(0.0, 1.0) var prob_kill := 0.7
@export_range(0.0, 1.0) var prob_fallo := 0.25
@export_group("Seguimiento")
@export var velocidad := 80.0

@export var distancia_seguir := 28.0
@export var distancia_parar := 18.0

@export_group("Espíritu")
@export_range(0.0, 1.0) var opacidad := 0.45
@export var variacion_opacidad := 0.10  
@export var tinte := Color(0.75, 0.9, 1.0)
@export var amplitud_flote := 2.0
 
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
 
var _jugador: Node2D
var _siguiendo := false
var _t := 0.0
var _globo: Label
var _hablando_hasta := 0.0
var _ultima_frase := -100.0
var _prox_idle := 0.0


func _ready() -> void:
	_crear_globo()
	GameProgress.carpi_evento.connect(_on_evento)
	_prox_idle = randf_range(idle_min, idle_max)
	await get_tree().create_timer(1.0).timeout
	decir(&"inicio", true)


static func frase(evento: StringName) -> String:
	var lista: Array = FRASES.get(evento, [])
	return "" if lista.is_empty() else lista.pick_random()


func _on_evento(evento: StringName) -> void:
	match evento:
		&"kill":
			decir(evento, randf() < prob_kill)
		&"fallo":
			decir(evento, randf() < prob_fallo)
		_:
			decir(evento, true)


# forzar = false: solo habla si pasó la pausa mínima
func decir(evento: StringName, quiere: bool = true) -> void:
	if not quiere:
		return
	if _t - _ultima_frase < pausa_minima:
		return
	var texto := frase(evento)
	if texto == "":
		return
	_ultima_frase = _t
	_hablando_hasta = _t + tiempo_visible
	_globo.text = texto
	_globo.reset_size()
	# Centrado sobre la cabeza (el label está escalado a 0.3)
	_globo.position = Vector2(-_globo.size.x * 0.15, -48.0 - _globo.size.y * 0.3)
	_globo.visible = true


func _crear_globo() -> void:
	var ajustes := LabelSettings.new()
	ajustes.font = FUENTE
	ajustes.font_size = 24
	ajustes.font_color = Color(1, 0.98, 0.85)
	ajustes.outline_size = 8
	ajustes.outline_color = Color.BLACK

	_globo = Label.new()
	_globo.label_settings = ajustes
	_globo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_globo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_globo.custom_minimum_size = Vector2(300, 0)
	_globo.scale = Vector2(0.3, 0.3)
	_globo.z_index = 20
	_globo.visible = false
	add_child(_globo)
 
func _process(delta: float) -> void:
	_t += delta
	_efecto_espiritu()

	if _globo.visible and _t >= _hablando_hasta:
		_globo.visible = false
	_prox_idle -= delta
	if _prox_idle <= 0.0:
		_prox_idle = randf_range(idle_min, idle_max)
		decir(&"idle")
	
	if _jugador == null or not is_instance_valid(_jugador):
		_jugador = get_tree().get_first_node_in_group("jugador") as Node2D
		if _jugador == null:
			return
	
	var al_jugador := _jugador.global_position - global_position
	var distancia := al_jugador.length()
	
	if distancia > distancia_seguir:
		_siguiendo = true
	elif distancia < distancia_parar:
		_siguiendo = false
		
	if _siguiendo:
		global_position += al_jugador.normalized() * velocidad * delta
		_animar(al_jugador)
	else:
		sprite.stop()
		sprite.frame = 0
		
func _animar(dir: Vector2) -> void:
	var anim: StringName
	if abs(dir.x) > abs(dir.y):
		anim = &"derecha" if dir.x > 0 else &"izquierda"
	else:
		anim = &"abajo" if dir.y > 0 else &"arriba"
	if sprite.animation != anim or not sprite.is_playing():
		sprite.play(anim)
		

func _efecto_espiritu() -> void:
	var alfa := opacidad + sin(_t * 2.0) * variacion_opacidad
	sprite.modulate = Color(tinte.r, tinte.g, tinte.b, alfa)
	sprite.position.y = sin(_t * 3.0) * amplitud_flote
