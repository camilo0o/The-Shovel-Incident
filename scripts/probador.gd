extends Area2D
# Probador del garage. Al acercarse se abre un menú con las skins disponibles.
# Las skins bloqueadas se compran con carpinchos (GameProgress.carpinchos).

@export var skins: Array[SkinData] = []
@export var abrir_al_acercarse := true   # false = hay que apretar [E], como en la armería

const FUENTE := preload("res://assets/ui/fonts/Ancient Medium.ttf")
const HOJA_CARPINCHO := preload("res://assets/sprites/items/Sprite-moneda-carpincho-naranja-efecto.png")
const HOJA_ORIGINAL := preload("res://assets/sprites/personaje/Character_Idle_Front-Sheet.png")

var _jugador: Node = null
var _abierto := false
var _etiqueta: Label
var _capa: CanvasLayer
var _lbl_carpinchos: Label
var _filas: Array[Dictionary] = []   # [{skin: SkinData o null, boton: Button}]


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_crear_etiqueta()
	_crear_menu()
	GameProgress.skin_cambiada.connect(func(_s): _refrescar())
	GameProgress.carpinchos_cambiados.connect(func(_c): _refrescar())


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
	if not body.is_in_group("jugador"):
		return
	_jugador = body
	if abrir_al_acercarse:
		_abrir()
	else:
		_etiqueta.visible = true


func _on_body_exited(body: Node2D) -> void:
	if body == _jugador:
		_jugador = null
		_etiqueta.visible = false


func _crear_etiqueta() -> void:
	var ajustes := LabelSettings.new()
	ajustes.font = FUENTE
	ajustes.font_size = 24
	ajustes.font_color = Color(1, 0.98, 0.13, 0.94)
	ajustes.outline_size = 8
	ajustes.outline_color = Color.BLACK

	_etiqueta = Label.new()
	_etiqueta.text = "[E] Probador"
	_etiqueta.label_settings = ajustes
	_etiqueta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_etiqueta.custom_minimum_size = Vector2(300, 0)
	_etiqueta.scale = Vector2(0.3, 0.3)
	_etiqueta.position = Vector2(-45, -72)   # centrada sobre el casillero
	_etiqueta.z_index = 10
	_etiqueta.visible = false
	add_child(_etiqueta)


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
	estilo.border_color = Color(1, 0.55, 0.1, 0.9)
	estilo.set_corner_radius_all(4)
	estilo.set_content_margin_all(16)
	panel.add_theme_stylebox_override("panel", estilo)
	centro.add_child(panel)

	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 10)
	panel.add_child(caja)

	var titulo := Label.new()
	titulo.text = "Probador"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_override("font", FUENTE)
	titulo.add_theme_font_size_override("font_size", 32)
	titulo.add_theme_color_override("font_color", Color(1, 0.55, 0.1))
	caja.add_child(titulo)

	# Contador: ícono de la moneda carpincho + cantidad
	var fila_monedas := HBoxContainer.new()
	fila_monedas.alignment = BoxContainer.ALIGNMENT_CENTER
	fila_monedas.add_theme_constant_override("separation", 8)
	caja.add_child(fila_monedas)

	var atlas_moneda := AtlasTexture.new()
	atlas_moneda.atlas = HOJA_CARPINCHO
	atlas_moneda.region = Rect2(50, 76, 105, 98)   # recorte de la moneda, primer cuadro
	var icono_moneda := TextureRect.new()
	icono_moneda.texture = atlas_moneda
	icono_moneda.custom_minimum_size = Vector2(28, 28)
	icono_moneda.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icono_moneda.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	fila_monedas.add_child(icono_moneda)

	_lbl_carpinchos = Label.new()
	_lbl_carpinchos.add_theme_font_size_override("font_size", 20)
	_lbl_carpinchos.add_theme_color_override("font_color", Color(1, 0.7, 0.3))
	fila_monedas.add_child(_lbl_carpinchos)

	# Primera fila: el personaje original (skin null) para poder volver a él
	var atlas_original := AtlasTexture.new()
	atlas_original.atlas = HOJA_ORIGINAL
	atlas_original.region = Rect2(0, SkinData.FILA * SkinData.FRAME.y, SkinData.FRAME.x, SkinData.FRAME.y)
	_agregar_fila(caja, null, atlas_original)
	for skin in skins:
		if skin != null:
			_agregar_fila(caja, skin, skin.icono())

	var cerrar := Button.new()
	cerrar.text = "Cerrar"
	cerrar.pressed.connect(_cerrar)
	caja.add_child(cerrar)

	_refrescar()


func _agregar_fila(caja: VBoxContainer, skin: SkinData, icono: Texture2D) -> void:
	var boton := Button.new()
	boton.custom_minimum_size = Vector2(380, 64)
	boton.alignment = HORIZONTAL_ALIGNMENT_LEFT
	boton.icon = icono
	boton.expand_icon = true
	boton.add_theme_constant_override("icon_max_width", 48)
	boton.add_theme_font_size_override("font_size", 16)
	boton.pressed.connect(_seleccionar.bind(skin))
	caja.add_child(boton)
	_filas.append({"skin": skin, "boton": boton})


func _refrescar() -> void:
	if _lbl_carpinchos != null:
		_lbl_carpinchos.text = "Carpinchos: %d" % GameProgress.carpinchos

	for fila in _filas:
		var skin: SkinData = fila["skin"]
		var boton: Button = fila["boton"]
		var nombre := "Personaje original" if skin == null else skin.nombre
		var desc := "" if skin == null else skin.descripcion

		if GameProgress.skin_desbloqueada(skin):
			var marca := "   (equipada)" if GameProgress.skin_equipada == skin else ""
			boton.text = "%s%s\n%s" % [nombre, marca, desc]
			boton.disabled = false
		else:
			var faltan := skin.costo - GameProgress.carpinchos
			var aviso := "" if faltan <= 0 else "  (te faltan %d)" % faltan
			boton.text = "%s (bloqueada)  -  %d carpinchos%s\n%s" % [nombre, skin.costo, aviso, desc]
			boton.disabled = not GameProgress.puede_comprar_skin(skin)


func _abrir() -> void:
	_abierto = true
	_etiqueta.visible = false
	_jugador.set("controles_bloqueados", true)
	_refrescar()
	_capa.visible = true

	# Foco en la skin equipada para poder usar teclado
	for fila in _filas:
		if fila["skin"] == GameProgress.skin_equipada:
			(fila["boton"] as Button).grab_focus()
			break


func _cerrar() -> void:
	if not _abierto:
		return
	_abierto = false
	_capa.visible = false
	_etiqueta.visible = _jugador != null and not abrir_al_acercarse

	# Espera dos frames para que el mismo clic/tecla no active al jugador
	await get_tree().physics_frame
	await get_tree().physics_frame
	if not _abierto and is_instance_valid(_jugador):
		_jugador.set("controles_bloqueados", false)


func _seleccionar(skin: SkinData) -> void:
	if not GameProgress.skin_desbloqueada(skin):
		# Comprar y equipar de una; el menú queda abierto para ver el resultado
		if GameProgress.comprar_skin(skin):
			GameProgress.equipar_skin(skin)
		return
	GameProgress.equipar_skin(skin)
	_cerrar()
