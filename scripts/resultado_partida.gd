extends CanvasLayer

var _panel_derrota: Panel
var _panel_victoria: Panel
var _juego_terminado := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 30
	_panel_derrota = _crear_overlay("Se acabó el juego, tu pierdes...")
	add_child(_panel_derrota)
	_panel_victoria = _crear_overlay("¡Nivel superado!")
	_agregar_boton(_panel_victoria, "Volver a selección de niveles", _ir_a_seleccion_de_niveles)
	add_child(_panel_victoria)


func _ir_a_seleccion_de_niveles() -> void:
	get_tree().paused = false
	Fade.cambiar_escena("res://scenes/level_select.tscn")

func mostrar_victoria() -> void:
	if _juego_terminado:
		return
	_juego_terminado = true
	get_tree().paused = true
	# Frase de Carpi en el menú de victoria
	var comentario := Label.new()
	comentario.text = "Carpi: «%s»" % CarpiSeguidor.frase(&"jefe")
	comentario.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	comentario.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	comentario.add_theme_color_override("font_color", Color(0.75, 0.9, 1.0))
	var caja: VBoxContainer = _panel_victoria.get_meta("caja")
	caja.add_child(comentario)
	caja.move_child(comentario, 1)
	_panel_victoria.visible = true
	caja.get_child(2).grab_focus()

func mostrar_derrota() -> void:
	if _juego_terminado:
		return
	_juego_terminado = true
	get_tree().paused = true
	_panel_derrota.visible = true
	await get_tree().create_timer(2.0).timeout
	GameProgress.vida_jugador = -1
	get_tree().paused = false
	get_tree().call_deferred("reload_current_scene")


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
