extends Control
## Menú de opciones. La interfaz se arma por código con el mismo estilo del menú principal
## (fuente Ancient Medium, fondo de pared, botones redondeados) y se maneja con teclado o mouse.

const FUENTE := "res://assets/ui/fonts/Ancient Medium.ttf"
const FONDO := "res://assets/ui/pared.svg"
const ORO := Color(1.0, 0.82, 0.35)
const TEXTO := Color(0.95, 0.93, 0.98)

var _sliders := {}       # bus -> HSlider
var _porcentajes := {}   # bus -> Label
var _chk_silencio: CheckButton
var _chk_pantalla: CheckButton
var _btn_volver: Button


func _ready() -> void:
	_aplicar_tema()
	_construir()
	_refrescar()
	_sliders["Master"].grab_focus()


func _exit_tree() -> void:
	Ajustes.guardar()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_volver()
	elif event.is_action_pressed("interactuar"):
		var foco := get_viewport().gui_get_focus_owner()
		if foco is Button and not foco.disabled:
			get_viewport().set_input_as_handled()
			foco.pressed.emit()


# --- Construcción de la interfaz ---------------------------------------------

func _aplicar_tema() -> void:
	var tema := Theme.new()
	if ResourceLoader.exists(FUENTE):
		tema.default_font = load(FUENTE)
	tema.default_font_size = 24

	tema.set_color("font_color", "Label", TEXTO)

	# Botones (mismo look que el menú principal: blancos y redondeados).
	for estado in ["normal", "hover", "pressed", "disabled"]:
		var color := Color(1.0, 0.99, 1.0)
		if estado == "hover":
			color = Color(0.85, 0.85, 0.85)
		elif estado == "pressed":
			color = Color(0.5, 0.5, 0.49)
		tema.set_stylebox(estado, "Button", _caja(color, 16))
	tema.set_stylebox("focus", "Button", _caja_borde(Color(0, 0, 0, 0), ORO, 16, 3))
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		tema.set_color(c, "Button", Color.BLACK)

	# Casillas: texto claro sobre el panel oscuro, y resaltado dorado al enfocar.
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color",
			"font_hover_pressed_color"]:
		tema.set_color(c, "CheckButton", TEXTO)
	tema.set_stylebox("focus", "CheckButton", _caja_borde(Color(0, 0, 0, 0), ORO, 10, 2))

	# Sliders: pista oscura, relleno dorado.
	var pista := _caja(Color(0.25, 0.22, 0.32), 6)
	pista.content_margin_top = 6
	pista.content_margin_bottom = 6
	var relleno := _caja(ORO, 6)
	relleno.content_margin_top = 6
	relleno.content_margin_bottom = 6
	tema.set_stylebox("slider", "HSlider", pista)
	tema.set_stylebox("grabber_area", "HSlider", relleno)
	tema.set_stylebox("grabber_area_highlight", "HSlider", relleno)
	tema.set_stylebox("focus", "HSlider", _caja_borde(Color(0, 0, 0, 0), ORO, 8, 2))

	theme = tema


func _construir() -> void:
	# Fondo
	var fondo: Control
	if ResourceLoader.exists(FONDO):
		var textura := TextureRect.new()
		textura.texture = load(FONDO)
		textura.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		textura.stretch_mode = TextureRect.STRETCH_SCALE
		fondo = textura
	else:
		var color := ColorRect.new()
		color.color = Color(0.12, 0.09, 0.17)
		fondo = color
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fondo)

	var velo := ColorRect.new()
	velo.color = Color(0.1, 0.05, 0.2, 0.5)
	velo.set_anchors_preset(Control.PRESET_FULL_RECT)
	velo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(velo)

	# Panel central
	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(centro)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(620, 0)
	panel.add_theme_stylebox_override("panel",
		_caja_borde(Color(0.07, 0.05, 0.11, 0.92), Color(0.45, 0.38, 0.6), 20, 3))
	centro.add_child(panel)

	var margen := MarginContainer.new()
	for lado in ["left", "right"]:
		margen.add_theme_constant_override("margin_" + lado, 36)
	for lado in ["top", "bottom"]:
		margen.add_theme_constant_override("margin_" + lado, 28)
	panel.add_child(margen)

	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 14)
	margen.add_child(caja)

	var titulo := Label.new()
	titulo.text = "Opciones"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 40)
	titulo.add_theme_color_override("font_color", ORO)
	caja.add_child(titulo)

	caja.add_child(_seccion("Audio"))
	_fila_volumen(caja, "General", "Master")
	_fila_volumen(caja, "Música", "Musica")
	_fila_volumen(caja, "Efectos", "Efectos")

	_chk_silencio = CheckButton.new()
	_chk_silencio.text = "Silenciar todo"
	_chk_silencio.toggled.connect(_on_silencio_toggled)
	caja.add_child(_chk_silencio)

	caja.add_child(_seccion("Pantalla"))
	_chk_pantalla = CheckButton.new()
	_chk_pantalla.text = "Pantalla completa"
	_chk_pantalla.toggled.connect(_on_pantalla_toggled)
	caja.add_child(_chk_pantalla)

	# Botones
	var botones := HBoxContainer.new()
	botones.add_theme_constant_override("separation", 16)
	botones.alignment = BoxContainer.ALIGNMENT_CENTER
	caja.add_child(botones)

	var btn_reset := Button.new()
	btn_reset.text = "Restablecer"
	btn_reset.custom_minimum_size = Vector2(220, 52)
	btn_reset.pressed.connect(_on_restablecer)
	botones.add_child(btn_reset)

	_btn_volver = Button.new()
	_btn_volver.text = "Volver"
	_btn_volver.custom_minimum_size = Vector2(220, 52)
	_btn_volver.pressed.connect(_volver)
	botones.add_child(_btn_volver)

	var ayuda := Label.new()
	ayuda.text = "↑ ↓ moverse    ← → ajustar    Esc volver"
	ayuda.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ayuda.add_theme_font_size_override("font_size", 16)
	ayuda.add_theme_color_override("font_color", Color(0.65, 0.62, 0.75))
	caja.add_child(ayuda)


func _seccion(texto: String) -> Control:
	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 4)
	var et := Label.new()
	et.text = texto
	et.add_theme_font_size_override("font_size", 28)
	et.add_theme_color_override("font_color", ORO)
	caja.add_child(et)
	var linea := HSeparator.new()
	caja.add_child(linea)
	return caja


func _fila_volumen(padre: Control, nombre: String, bus: String) -> void:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 16)
	padre.add_child(fila)

	var et := Label.new()
	et.text = nombre
	et.custom_minimum_size.x = 130
	fila.add_child(et)

	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.focus_mode = Control.FOCUS_ALL
	slider.value_changed.connect(_on_volumen_cambiado.bind(bus))
	slider.drag_ended.connect(func(_cambio: bool) -> void: Ajustes.guardar())
	fila.add_child(slider)

	var pct := Label.new()
	pct.custom_minimum_size.x = 70
	pct.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	fila.add_child(pct)

	_sliders[bus] = slider
	_porcentajes[bus] = pct


# --- Estado / eventos ----------------------------------------------------------

func _refrescar() -> void:
	for bus in _sliders.keys():
		_sliders[bus].set_value_no_signal(Ajustes.volumen[bus])
		_actualizar_porcentaje(bus)
	_chk_silencio.set_pressed_no_signal(Ajustes.silenciar)
	_chk_pantalla.set_pressed_no_signal(Ajustes.pantalla_completa)


func _actualizar_porcentaje(bus: String) -> void:
	_porcentajes[bus].text = "%d%%" % roundi(Ajustes.volumen[bus] * 100.0)


func _on_volumen_cambiado(valor: float, bus: String) -> void:
	Ajustes.set_volumen(bus, valor)
	_actualizar_porcentaje(bus)


func _on_silencio_toggled(activo: bool) -> void:
	Ajustes.set_silenciar(activo)
	Ajustes.guardar()


func _on_pantalla_toggled(activo: bool) -> void:
	Ajustes.set_pantalla_completa(activo)
	Ajustes.guardar()


func _on_restablecer() -> void:
	Ajustes.restablecer()
	_refrescar()


func _volver() -> void:
	Ajustes.guardar()
	GameProgress.volver()


# --- Helpers de estilo ---------------------------------------------------------

func _caja(color: Color, radio: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(radio)
	return s


func _caja_borde(color: Color, borde: Color, radio: int, grosor: int) -> StyleBoxFlat:
	var s := _caja(color, radio)
	s.set_border_width_all(grosor)
	s.border_color = borde
	return s
