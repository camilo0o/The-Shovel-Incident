class_name CarpiBailarin
extends Node2D

const FUENTE := preload("res://assets/ui/fonts/Ancient Medium.ttf")

const FRASES := [
	"¡Mirá qué pasos, crack!",
	"La vida es un carnaval...",
	"Cadera, cadera, cadera...",
	"Ni Shakira, estimado.",
	"Esto lo ensayé toda la noche.",
	"No lo intentes en casa, loco.",
	"¡Que no pare la música!",
	"El que no baila se lo come la pala.",
	"Pasos prohibidos por la ley de Carpi.",
	"¿Me ves las patitas? Eso es talento.",
]

@export_group("Baile")
const RUTA_HOJA := "res://assets/sprites/carpi2/carpi_baile.png"
@export var hoja_baile: Texture2D
@export var tam_cuadro := Vector2(32, 32)    # tamaño de cada cuadro de la hoja
@export var cuadros := 8
@export var fps := 8.0
@export var escala := 0.6                    # tamaño de Carpi (1.0 = tamaño original de la hoja)
@export var velocidad_cerca := 1.5           # baila más rápido si el jugador está cerca

@export_group("Espíritu")                    # mismos valores que el Carpi que te sigue
@export_range(0.0, 1.0) var opacidad := 0.45
@export var variacion_opacidad := 0.10
@export var tinte := Color(0.75, 0.9, 1.0)
@export var amplitud_flote := 2.0

@export_group("Charla")
@export var tiempo_visible := 3.0

@onready var _zona: Area2D = $Zona

var _jugador: Node = null
var _sprite: AnimatedSprite2D
var _globo: Label
var _aviso: Label
var _oculta_globo_en := 0.0
var _ultima := -1
var _t := 0.0


func _ready() -> void:
	if hoja_baile == null and ResourceLoader.exists(RUTA_HOJA):
		hoja_baile = load(RUTA_HOJA)
	if hoja_baile == null:
		push_error("CarpiBailarin: no encuentro la hoja de baile. Copiá carpi_baile.png a %s o asignala en el Inspector." % RUTA_HOJA)
		return
	_crear_sprite()
	_crear_textos()
	_zona.body_entered.connect(_on_entra)
	_zona.body_exited.connect(_on_sale)


func _process(delta: float) -> void:
	if _globo == null:
		return
	_t += delta
	_sprite.modulate = Color(tinte.r, tinte.g, tinte.b, opacidad + sin(_t * 2.0) * variacion_opacidad)
	_sprite.position.y = sin(_t * 3.0) * amplitud_flote
	if _globo.visible and Time.get_ticks_msec() / 1000.0 >= _oculta_globo_en:
		_globo.visible = false
		_aviso.visible = _jugador != null


func _unhandled_input(event: InputEvent) -> void:
	if _jugador != null and event.is_action_pressed("interactuar"):
		_hablar()
		get_viewport().set_input_as_handled()


func _on_entra(body: Node2D) -> void:
	if body.is_in_group("jugador"):
		_jugador = body
		_sprite.speed_scale = velocidad_cerca
		_aviso.visible = not _globo.visible


func _on_sale(body: Node2D) -> void:
	if body == _jugador:
		_jugador = null
		_sprite.speed_scale = 1.0
		_aviso.visible = false


func _hablar() -> void:
	# Frase al azar, sin repetir la anterior
	var i := randi() % FRASES.size()
	if i == _ultima:
		i = (i + 1) % FRASES.size()
	_ultima = i
	_globo.text = FRASES[i]
	_globo.reset_size()
	_globo.position = Vector2(-_globo.size.x * 0.15, -tam_cuadro.y * escala / 2.0 - 8.0 - _globo.size.y * 0.3)
	_globo.visible = true
	_aviso.visible = false
	_oculta_globo_en = Time.get_ticks_msec() / 1000.0 + tiempo_visible


func _crear_sprite() -> void:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	frames.add_animation(&"baile")
	frames.set_animation_speed(&"baile", fps)
	frames.set_animation_loop(&"baile", true)
	for i in cuadros:
		var atlas := AtlasTexture.new()
		atlas.atlas = hoja_baile
		atlas.region = Rect2(i * tam_cuadro.x, 0, tam_cuadro.x, tam_cuadro.y)
		frames.add_frame(&"baile", atlas)
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = frames
	_sprite.scale = Vector2(escala, escala)
	add_child(_sprite)
	_sprite.play(&"baile")


func _crear_textos() -> void:
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

	_aviso = Label.new()
	_aviso.text = "[E] Hablar"
	_aviso.label_settings = ajustes
	_aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_aviso.custom_minimum_size = Vector2(300, 0)
	_aviso.scale = Vector2(0.3, 0.3)
	_aviso.position = Vector2(-45, -tam_cuadro.y * escala / 2.0 - 14.0)
	_aviso.z_index = 20
	_aviso.visible = false
	add_child(_aviso)
