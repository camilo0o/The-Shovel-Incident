extends Area2D
const FUENTE := preload("res://assets/ui/fonts/Ancient Medium.ttf")

@onready var etiqueta: Label = $Etiqueta

var _jugador: Node = null
var _abierto := false
var _capa: CanvasLayer
var _boton: Button

func _ready() -> void:
	etiqueta.visible = false
	_crear_menu()
	GameProgress.habilidad_cambiada.connect(func(_e): _refrescar())
	GameProgress.nivel_completado.connect(func(_i): _refrescar())


func _unhandled_input(event: InputEvent) -> void:
	if _abierto:
		if event.is_action_pressed("ui_cancel"):
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
	titulo.text = "Mesa de habilidades"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_override("font", FUENTE)
	titulo.add_theme_font_size_override("font_size", 32)
	titulo.add_theme_color_override("font_color", Color(1, 0.98, 0.13))
	caja.add_child(titulo)
	_boton = Button.new()
	_boton.custom_minimum_size = Vector2(380, 64)
	_boton.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_boton.add_theme_font_size_override("font_size", 16)
	_boton.pressed.connect(_alternar)
	caja.add_child(_boton)

	var cerrar := Button.new()
	cerrar.text = "Cerrar"
	cerrar.pressed.connect(_cerrar)
	caja.add_child(cerrar)

	_refrescar()

func _refrescar() -> void:
	if _boton == null:
		return
	if not GameProgress.invisibilidad_desbloqueada():
		_boton.text = "Invisibilidad (bloqueada)\nCompletá el nivel 2 para desbloquearla"
		_boton.disabled = true
	else:
		var marca := "   (equipada)" if GameProgress.invisibilidad_equipada else ""
		_boton.text = "Invisibilidad%s\n25 s activa · 35 s de recarga" % marca
		_boton.disabled = false

func _abrir() -> void:
	_abierto = true
	etiqueta.visible = false
	_jugador.set("controles_bloqueados", true)
	_refrescar()
	_capa.visible = true

	if not _boton.disabled:
		_boton.grab_focus()


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


func _alternar() -> void:
	GameProgress.equipar_invisibilidad(not GameProgress.invisibilidad_equipada)
	_cerrar()
