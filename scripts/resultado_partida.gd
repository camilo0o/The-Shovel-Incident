extends CanvasLayer

var _panel_derrota: Panel
var _panel_victoria: Panel
var _juego_terminado := false
var _boton_victoria: Button
var _carpi_celebrando: TextureRect
var _pose_carpi: AtlasTexture


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 30
	_panel_derrota = _crear_overlay("Se acabó el juego, tu pierdes...")
	add_child(_panel_derrota)
	_panel_victoria = _crear_overlay("¡Nivel superado!")
	_boton_victoria = _agregar_boton(_panel_victoria, "Volver a selección de niveles", _ir_a_seleccion_de_niveles)
	add_child(_panel_victoria)


func _ir_a_seleccion_de_niveles() -> void:
	get_tree().paused = false
	Fade.cambiar_escena("res://scenes/level_select.tscn")

func mostrar_victoria(nivel_index: int = -1) -> void:
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
	if nivel_index == 2:
		_agregar_carpi_fisicoculturista(caja)
	_panel_victoria.visible = true
	_boton_victoria.grab_focus()


func _agregar_carpi_fisicoculturista(caja: VBoxContainer) -> void:
	var hoja: Texture2D = load("res://assets/ui/victoria/carpi_fisicoculturismo.png")
	_pose_carpi = AtlasTexture.new()
	_pose_carpi.atlas = hoja
	_pose_carpi.region = Rect2(0, 0, hoja.get_width() / 2.0, hoja.get_height())
	_pose_carpi.filter_clip = true

	_carpi_celebrando = TextureRect.new()
	_carpi_celebrando.name = "CarpiFisicoculturista"
	_carpi_celebrando.texture = _pose_carpi
	_carpi_celebrando.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_carpi_celebrando.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_carpi_celebrando.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_carpi_celebrando.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caja.add_child(_carpi_celebrando)
	caja.move_child(_carpi_celebrando, 1)
	_ajustar_victoria_final()
	get_viewport().size_changed.connect(_ajustar_victoria_final)

	# La celebracion sigue animada mientras el juego esta pausado.
	var poses := Timer.new()
	poses.name = "PosesCarpi"
	poses.process_mode = Node.PROCESS_MODE_ALWAYS
	poses.wait_time = 1.5
	poses.timeout.connect(_alternar_pose_carpi)
	add_child(poses)
	poses.start()


func _alternar_pose_carpi() -> void:
	var region := _pose_carpi.region
	region.position.x = region.size.x if region.position.x == 0.0 else 0.0
	_pose_carpi.region = region


func _ajustar_victoria_final() -> void:
	var pantalla := get_viewport().get_visible_rect().size
	var ancho := minf(420.0, pantalla.x - 32.0)
	var alto_imagen := minf(260.0, pantalla.y * 0.4)
	_carpi_celebrando.custom_minimum_size = Vector2(0, alto_imagen)
	var caja: VBoxContainer = _panel_victoria.get_meta("caja")
	caja.offset_left = -ancho / 2.0
	caja.offset_right = ancho / 2.0
	caja.offset_top = -(alto_imagen + 160.0) / 2.0
	caja.offset_bottom = (alto_imagen + 160.0) / 2.0

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


func _agregar_boton(overlay: Panel, texto: String, al_presionar: Callable) -> Button:
	var caja: VBoxContainer = overlay.get_meta("caja")
	var boton := Button.new()
	boton.text = texto
	boton.pressed.connect(al_presionar)
	caja.add_child(boton)
	return boton
