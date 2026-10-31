extends CanvasLayer

@export var ruta_jugador: NodePath

var habilitado := true
var _panel_pausa: Panel
var _jugador: Node


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 20
	if not ruta_jugador.is_empty():
		_jugador = get_node(ruta_jugador)
	_panel_pausa = _crear_overlay("Pausa")
	_agregar_boton(_panel_pausa, "Continuar", _alternar_pausa)
	_agregar_boton(_panel_pausa, "Volver", _volver)
	add_child(_panel_pausa)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("pausa") or event.is_echo():
		return
	if not habilitado:
		return
	if is_instance_valid(_jugador) and _jugador.get("controles_bloqueados") == true:
		return
	_alternar_pausa()
	get_viewport().set_input_as_handled()


func deshabilitar() -> void:
	habilitado = false
	_panel_pausa.hide()


func _alternar_pausa() -> void:
	if not habilitado:
		return
	if get_tree().paused and not _panel_pausa.visible:
		return
	get_tree().paused = not get_tree().paused
	_panel_pausa.visible = get_tree().paused
	if _panel_pausa.visible:
		var caja: VBoxContainer = _panel_pausa.get_meta("caja")
		caja.get_child(1).grab_focus()


func _volver() -> void:
	if not habilitado:
		return
	get_tree().paused = false
	GameProgress.volver()


func _crear_overlay(mensaje: String) -> Panel:
	var fondo := Panel.new()
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fondo.mouse_filter = Control.MOUSE_FILTER_STOP
	fondo.visible = false

	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0, 0, 0, 0.75)
	fondo.add_theme_stylebox_override("panel", estilo)

	var caja := VBoxContainer.new()
	var ancho := 260.0
	var alto := 160.0
	caja.set_anchors_preset(Control.PRESET_CENTER)
	caja.offset_left = -ancho / 2.0
	caja.offset_right = ancho / 2.0
	caja.offset_top = -alto / 2.0
	caja.offset_bottom = alto / 2.0
	caja.alignment = BoxContainer.ALIGNMENT_CENTER
	caja.add_theme_constant_override("separation", 12)
	fondo.add_child(caja)

	var titulo := Label.new()
	titulo.text = mensaje
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.autowrap_mode = TextServer.AUTOWRAP_WORD
	titulo.add_theme_font_size_override("font_size", 22)
	caja.add_child(titulo)

	fondo.set_meta("caja", caja)
	return fondo


func _agregar_boton(overlay: Panel, texto: String, al_presionar: Callable) -> void:
	var caja: VBoxContainer = overlay.get_meta("caja")
	var boton := Button.new()
	boton.text = texto
	boton.pressed.connect(al_presionar)
	caja.add_child(boton)
