extends Area2D
@export var armas: Array[ArmaData] = []

const FUENTE := preload("res://assets/ui/fonts/Ancient Medium.ttf")

@onready var etiqueta: Label = $Etiqueta

var _jugador: Node = null
var _abierto := false
var _capa: CanvasLayer
var _botones: Dictionary = {}   # ArmaData -> Button

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	etiqueta.visible = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_crear_menu()
	GameProgress.arma_cambiada.connect(func(_a): _refrescar())


func _unhandled_input(event: InputEvent) -> void:
	if _abierto:
		if event.is_action_pressed("ui_cancel") or event.is_action_pressed("interactuar"):
			_cerrar()
			get_viewport().set_input_as_handled()
		return
	if _jugador != null and event.is_action_pressed("interactuar"):
		_abrir()
		get_viewport().set_input_as_handled()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("jugador"):
		_jugador = body
		if not _abierto:
			etiqueta.visible = true
			

func _on_body_exited(body: Node2D) -> void:
	if body == _jugador:
		_jugador = null
		etiqueta.visible = false


func _crear_menu() -> void:
	_capa = CanvasLayer.new()
	_capa.layer = 20
	_capa.visible = false
	add_child(_capa)

	# Fondo oscuro que también bloquea los clics hacia el juego
	var fondo := ColorRect.new()
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fondo.color = Color(0, 0, 0, 0.65)
	fondo.mouse_filter = Control.MOUSE_FILTER_STOP
	_capa.add_child(fondo)

	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	fondo.add_child(centro)

	var panel := PanelContainer.new()
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.12, 0.12, 0.12, 0.95)
	estilo.set_border_width_all(2)
	estilo.border_color = Color(1, 0.98, 0.13, 0.9)
	estilo.set_corner_radius_all(4)
	estilo.set_content_margin_all(16)
	panel.add_theme_stylebox_override("panel", estilo)
	centro.add_child(panel)

	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 10)
	panel.add_child(caja)

	var titulo := Label.new()
	titulo.text = "Armería"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_override("font", FUENTE)
	titulo.add_theme_font_size_override("font_size", 32)
	titulo.add_theme_color_override("font_color", Color(1, 0.98, 0.13))
	caja.add_child(titulo)

	for arma in armas:
		if arma == null:
			continue
		var boton := Button.new()
		boton.custom_minimum_size = Vector2(380, 64)
		boton.alignment = HORIZONTAL_ALIGNMENT_LEFT
		boton.icon = arma.icono
		boton.expand_icon = true
		boton.add_theme_constant_override("icon_max_width", 48)
		boton.add_theme_font_size_override("font_size", 16)
		boton.pressed.connect(_seleccionar.bind(arma))
		caja.add_child(boton)
		_botones[arma] = boton

	var cerrar := Button.new()
	cerrar.text = "Cerrar"
	cerrar.pressed.connect(_cerrar)
	caja.add_child(cerrar)

	_refrescar()


func _refrescar() -> void:
	for arma in _botones:
		var boton: Button = _botones[arma]
		var marca := "   (equipada)" if GameProgress.arma_equipada == arma else ""
		boton.text = "%s%s\n%s" % [arma.nombre, marca, arma.descripcion]


func _abrir() -> void:
	_abierto = true
	etiqueta.visible = false
	_jugador.set("controles_bloqueados", true)
	_refrescar()
	_capa.visible = true

	# Foco en el arma equipada (o en la primera) para poder usar teclado
	var foco: Button = _botones.get(GameProgress.arma_equipada)
	if foco == null and not _botones.is_empty():
		foco = _botones.values()[0]
	if foco != null:
		foco.grab_focus()


func _cerrar() -> void:
	if not _abierto:
		return
	_abierto = false
	_capa.visible = false
	etiqueta.visible = _jugador != null

	await get_tree().physics_frame
	await get_tree().physics_frame
	if not _abierto and is_instance_valid(_jugador):
		_jugador.set("controles_bloqueados", false)


func _seleccionar(arma: ArmaData) -> void:
	GameProgress.equipar_arma(arma)
	_cerrar()
