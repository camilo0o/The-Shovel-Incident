extends CharacterBody2D
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite

signal vida_cambiada(vida_actual: int, vida_maxima: int)
signal municion_cambiada(cantidad: int)
signal murio

const MASK_ENEMIGOS := 1 << 2

const ACCION_PUNO := "ataque_corto"
const ACCION_ARMA := "ataque_largo"

const TEXTURA_PUNO := preload("res://assets/sprites/armas/puno.png")

@export var vida_maxima := 5
var municion := 0

@export_group("Piñazo")
@export var dano_puno := 1
@export var alcance_puno := 16.0
@export var tamano_puno := Vector2(16, 16)
@export var cooldown_puno := 0.3

@export_group("Proyectil")
@export var bala_scene: PackedScene = preload("res://scenes/bala.tscn")

@export_group("Debug")
@export var debug_hitbox := false

var speed = 100.0
var last_direction = "front"
var mira_vector := Vector2.DOWN

var vida := 0
var invulnerable := false

var _hud_layer: CanvasLayer
var _hud_barra: ProgressBar
var _hud_municion: Label
var _hud_monedas: Label
var _hud_carpinchos: Label

var _frames_originales: SpriteFrames

var _panel_pausa: Control
var _panel_derrota: Control
var _panel_victoria: Control
var _juego_terminado := false

var arma: ArmaData = null
var controles_bloqueados := false
var puede_pegar_puno := true
var puede_usar_arma := true

var _arma_pivote: Node2D
var _arma_sprite: Sprite2D
var _puno_sprite: Sprite2D
var _animando_arma := false
var _direccion_dibujada := ""

var _golpe_visible := false
var _golpe_rect := Rect2()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	animated_sprite.process_mode = Node.PROCESS_MODE_PAUSABLE

	add_to_group("jugador")
	if GameProgress.vida_jugador > 0:
		vida = GameProgress.vida_jugador
	else:
		vida = vida_maxima
	
	municion = GameProgress.municion
	
	_crear_visuales_de_ataque()
	_crear_hud_vida()
	_crear_paneles_de_estado()
	GameProgress.arma_cambiada.connect(_on_arma_cambiada)
	_on_arma_cambiada(GameProgress.arma_equipada)

	_frames_originales = animated_sprite.sprite_frames
	GameProgress.skin_cambiada.connect(aplicar_skin)
	aplicar_skin(GameProgress.skin_equipada)


func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed("pausa") and not _juego_terminado and not controles_bloqueados:
		_alternar_pausa()
	if get_tree().paused:
		return

	if controles_bloqueados:
		velocity = Vector2.ZERO
		move_and_slide()
		update_animation("idle")
		return

	get_input()
	move_and_slide()
	_actualizar_arma_visual()

	if Input.is_action_just_pressed(ACCION_PUNO):
		atacar_con_puno()
	elif Input.is_action_just_pressed(ACCION_ARMA) or (arma != null and arma.automatica and Input.is_action_pressed(ACCION_ARMA)):
		atacar_con_arma()

func get_input():
	var input_direction = Input.get_vector("left", "right", "up", "down")
	if input_direction == Vector2.ZERO:
		velocity = Vector2.ZERO
		update_animation("idle")
		return
	if abs(input_direction.x) > abs(input_direction.y):
		if input_direction.x > 0:
			last_direction = "right"
		else:
			last_direction = "left"
	else:
		if input_direction.y > 0:
			last_direction = "front"
		else:
			last_direction = "back"
	update_animation("run")
	velocity = input_direction * speed
	mira_vector = input_direction.normalized()

func aplicar_skin(skin: SkinData) -> void:
	if skin == null:
		animated_sprite.sprite_frames = _frames_originales
	else:
		animated_sprite.sprite_frames = skin.construir_frames()
	animated_sprite.play(animated_sprite.animation)

func update_animation(state):
	animated_sprite.play(state + "_" + last_direction)

func _direccion_vector() -> Vector2:
	match last_direction:
		"right":
			return Vector2.RIGHT
		"left":
			return Vector2.LEFT
		"back":
			return Vector2.UP
		_:
			return Vector2.DOWN


func _golpear(dano: int, alcance: float, tamano: Vector2) -> int:
	var centro_local := _direccion_vector() * alcance

	var forma := RectangleShape2D.new()
	forma.size = tamano
	var consulta := PhysicsShapeQueryParameters2D.new()
	consulta.shape = forma
	consulta.transform = Transform2D(0.0, global_position + centro_local)
	consulta.collision_mask = MASK_ENEMIGOS
	consulta.collide_with_bodies = true

	var golpeados := []
	for r in get_world_2d().direct_space_state.intersect_shape(consulta):
		var cuerpo = r.collider
		if cuerpo in golpeados:
			continue
		golpeados.append(cuerpo)
		if cuerpo.has_method("recibir_dano"):
			cuerpo.recibir_dano(dano, global_position)

	if debug_hitbox:
		_mostrar_golpe(Rect2(centro_local - tamano / 2.0, tamano))
	return golpeados.size()

func atacar_con_puno() -> void:
	if not puede_pegar_puno:
		return
	puede_pegar_puno = false

	_golpear(dano_puno, alcance_puno, tamano_puno)
	_animar_puno()

	await get_tree().create_timer(cooldown_puno).timeout
	puede_pegar_puno = true

func _animar_puno() -> void:
	var dir := _direccion_vector()
	var mano := Vector2(0, 4)
	_puno_sprite.position = mano + dir * 4.0
	_puno_sprite.visible = true
	var tween := create_tween()
	tween.tween_property(_puno_sprite, "position", mano + dir * alcance_puno, 0.06)
	tween.tween_interval(0.05)
	tween.tween_callback(func(): _puno_sprite.visible = false)

func atacar_con_arma() -> void:
	if arma == null or not puede_usar_arma:
		return
	if arma.tipo == ArmaData.Tipo.DISTANCIA and arma.consume_municion and municion <= 0:
		return
	puede_usar_arma = false

	match arma.tipo:
		ArmaData.Tipo.CUERPO_A_CUERPO:
			_giro_de_arma()
		ArmaData.Tipo.DISTANCIA:
			_disparar()

	await get_tree().create_timer(arma.cooldown).timeout
	puede_usar_arma = true

func _giro_de_arma() -> void:
	_animando_arma = true
	var base := _direccion_vector().angle() + PI / 2.0
	var signo := -1.0 if last_direction == "left" else 1.0
	var inicio := base - signo * deg_to_rad(70.0)
	inicio = _arma_pivote.rotation + angle_difference(_arma_pivote.rotation, inicio)

	var tween := create_tween()
	tween.tween_property(_arma_pivote, "rotation", inicio, 0.05)
	tween.tween_callback(_impactar_arma)
	tween.tween_property(_arma_pivote, "rotation", inicio + signo * deg_to_rad(140.0), 0.09)
	await tween.finished
	_animando_arma = false

func _impactar_arma() -> void:
	_golpear(arma.dano, arma.alcance, arma.tamano_golpe)

func _disparar() -> void:
	if arma.consume_municion:
		municion -= 1
		GameProgress.municion = municion
		municion_cambiada.emit(municion)

	var dir := mira_vector
	var bala := bala_scene.instantiate()
	bala.direccion = dir
	bala.dano = arma.dano
	bala.velocidad = arma.velocidad_bala
	bala.vida_util = arma.vida_util_bala
	bala.textura = arma.bala_textura
	bala.tirador = self
	get_tree().current_scene.add_child(bala)
	bala.global_position = global_position + dir * arma.distancia_boca

	_animando_arma = true
	var pos0 := _arma_pivote.position
	var tween := create_tween()
	tween.tween_property(_arma_pivote, "position", pos0 - dir * 3.0, 0.04)
	tween.tween_property(_arma_pivote, "position", pos0, 0.08)
	await tween.finished
	_animando_arma = false

func agregar_municion(cantidad: int) -> void:
	municion += cantidad
	GameProgress.municion = municion
	municion_cambiada.emit(municion)

func curar(cantidad: int) -> void:
	if vida <= 0:
		return
	vida = min(vida + cantidad, vida_maxima)
	GameProgress.vida_jugador = vida
	vida_cambiada.emit(vida, vida_maxima)

func _crear_hud_vida() -> void:
	_hud_layer = CanvasLayer.new()
	_hud_layer.layer = 10
	add_child(_hud_layer)

	_hud_barra = ProgressBar.new()
	_hud_barra.min_value = 0
	_hud_barra.max_value = vida_maxima
	_hud_barra.value = vida
	_hud_barra.show_percentage = false
	_hud_barra.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_hud_barra.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_hud_barra.offset_left = 16
	_hud_barra.offset_right = 16 + 120
	_hud_barra.offset_top = -32
	_hud_barra.offset_bottom = -16

	var fondo := StyleBoxFlat.new()
	fondo.bg_color = Color(0.1, 0.1, 0.1, 0.85)
	fondo.set_corner_radius_all(3)
	fondo.set_border_width_all(2)
	fondo.border_color = Color(0, 0, 0)

	var relleno := StyleBoxFlat.new()
	relleno.bg_color = Color(0.8, 0.15, 0.15)
	relleno.set_corner_radius_all(3)

	_hud_barra.add_theme_stylebox_override("background", fondo)
	_hud_barra.add_theme_stylebox_override("fill", relleno)

	_hud_layer.add_child(_hud_barra)

	vida_cambiada.connect(_actualizar_hud_vida)

	_hud_municion = Label.new()
	_hud_municion.text = "Munición: %d" % municion
	_hud_municion.add_theme_font_size_override("font_size", 16)
	_hud_municion.add_theme_color_override("font_color", Color.WHITE)
	_hud_municion.add_theme_color_override("font_outline_color", Color.BLACK)
	_hud_municion.add_theme_constant_override("outline_size", 4)

	_hud_municion.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_hud_municion.offset_left = 16 + 120 + 12
	_hud_municion.offset_right = 16 + 120 + 12 + 100
	_hud_municion.offset_top = -32
	_hud_municion.offset_bottom = -16
	_hud_municion.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	_hud_layer.add_child(_hud_municion)
	_hud_municion.visible = false

	municion_cambiada.connect(_actualizar_hud_municion)

	_hud_monedas = Label.new()
	_hud_monedas.text = "Bananas: %d" % GameProgress.monedas
	_hud_monedas.add_theme_font_size_override("font_size", 16)
	_hud_monedas.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
	_hud_monedas.add_theme_color_override("font_outline_color", Color.BLACK)
	_hud_monedas.add_theme_constant_override("outline_size", 4)
	
	_hud_monedas.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_hud_monedas.offset_left = 16
	_hud_monedas.offset_right = 16 + 160
	_hud_monedas.offset_top = -56
	_hud_monedas.offset_bottom = -40
	_hud_monedas.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	_hud_layer.add_child(_hud_monedas)
	
	GameProgress.monedas_cambiadas.connect(_actualizar_hud_monedas)

	_hud_carpinchos = Label.new()
	_hud_carpinchos.text = "Carpinchos: %d" % GameProgress.carpinchos
	_hud_carpinchos.add_theme_font_size_override("font_size", 16)
	_hud_carpinchos.add_theme_color_override("font_color", Color(1, 0.55, 0.1))
	_hud_carpinchos.add_theme_color_override("font_outline_color", Color.BLACK)
	_hud_carpinchos.add_theme_constant_override("outline_size", 4)
	_hud_carpinchos.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_hud_carpinchos.offset_left = 16
	_hud_carpinchos.offset_right = 16 + 160
	_hud_carpinchos.offset_top = -80
	_hud_carpinchos.offset_bottom = -64
	_hud_carpinchos.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_hud_layer.add_child(_hud_carpinchos)

	GameProgress.carpinchos_cambiados.connect(_actualizar_hud_carpinchos)

func _actualizar_hud_vida(vida_actual: int, vida_max: int) -> void:
	if _hud_barra == null:
		return
	_hud_barra.max_value = vida_max
	_hud_barra.value = vida_actual

func _actualizar_hud_municion(cantidad: int) -> void:
	if _hud_municion == null:
		return
	_hud_municion.text = "Munición: %d" % cantidad

func _actualizar_hud_monedas(cantidad: int) -> void:
	if _hud_monedas == null:
		return
	_hud_monedas.text = "Bananas: %d" % cantidad

func _actualizar_hud_carpinchos(cantidad: int) -> void:
	if _hud_carpinchos == null:
		return
	_hud_carpinchos.text = "Carpinchos: %d" % cantidad

func _actualizar_visibilidad_municion() -> void:
	if _hud_municion == null:
		return
	_hud_municion.visible = arma != null and arma.tipo == ArmaData.Tipo.DISTANCIA

func _crear_paneles_de_estado() -> void:
	_panel_pausa = _crear_overlay("Pausa")
	_agregar_boton(_panel_pausa, "Continuar", _alternar_pausa)
	_agregar_boton(_panel_pausa, "Volver", _volver)
	_hud_layer.add_child(_panel_pausa)

	_panel_derrota = _crear_overlay("Se acabó el juego, tu pierdes...")
	_hud_layer.add_child(_panel_derrota)

	_panel_victoria = _crear_overlay("¡Nivel superado!")
	_agregar_boton(_panel_victoria, "Volver a selección de niveles", _ir_a_seleccion_de_niveles)
	_hud_layer.add_child(_panel_victoria)


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


func _alternar_pausa() -> void:
	if _juego_terminado:
		return
	get_tree().paused = not get_tree().paused
	_panel_pausa.visible = get_tree().paused

func _volver() -> void:
	get_tree().paused = false
	GameProgress.volver()

func _ir_a_seleccion_de_niveles() -> void:
	get_tree().paused = false
	Fade.cambiar_escena("res://scenes/level_select.tscn")

func mostrar_victoria() -> void:
	if _juego_terminado:
		return
	_juego_terminado = true
	get_tree().paused = true
	_panel_victoria.visible = true

func _mostrar_derrota() -> void:
	if _juego_terminado:
		return
	_juego_terminado = true
	get_tree().paused = true
	_panel_derrota.visible = true
	await get_tree().create_timer(2.0).timeout
	GameProgress.vida_jugador = -1
	get_tree().paused = false
	get_tree().call_deferred("reload_current_scene")

func _crear_visuales_de_ataque() -> void:
	_arma_pivote = Node2D.new()
	_arma_pivote.visible = false
	add_child(_arma_pivote)

	_arma_sprite = Sprite2D.new()
	_arma_sprite.offset = Vector2(0, -8)
	_arma_pivote.add_child(_arma_sprite)

	_puno_sprite = Sprite2D.new()
	_puno_sprite.texture = TEXTURA_PUNO
	_puno_sprite.visible = false
	add_child(_puno_sprite)

func _on_arma_cambiada(nueva: ArmaData) -> void:
	arma = nueva
	_animando_arma = false
	_direccion_dibujada = ""
	_arma_pivote.visible = arma != null and arma.icono != null
	if arma != null:
		_arma_sprite.texture = arma.icono
		if arma.icono != null:
			_arma_sprite.offset = Vector2(0, -arma.icono.get_height() / 2.0)
	_actualizar_arma_visual()
	_actualizar_visibilidad_municion()

func _actualizar_arma_visual() -> void:
	if arma == null or _animando_arma:
		return
	_arma_pivote.position = _posicion_mano()
	_arma_pivote.rotation = _rotacion_reposo()

	if _direccion_dibujada != last_direction:
		_direccion_dibujada = last_direction
		if last_direction == "back":
			move_child(_arma_pivote, animated_sprite.get_index())
		else:
			move_child(_arma_pivote, get_child_count() - 1)

func _posicion_mano() -> Vector2:
	match last_direction:
		"right":
			return Vector2(7, 4)
		"left":
			return Vector2(-7, 4)
		"back":
			return Vector2(-6, 3)
		_:
			return Vector2(6, 5)

func _rotacion_reposo() -> float:
	if arma.tipo == ArmaData.Tipo.DISTANCIA:
		return mira_vector.angle() + PI / 2.0
	var inclinacion := deg_to_rad(20.0)
	return -inclinacion if (last_direction == "left" or last_direction == "back") else inclinacion

func _mostrar_golpe(rect: Rect2) -> void:
	_golpe_rect = rect
	_golpe_visible = true
	queue_redraw()
	await get_tree().create_timer(0.08).timeout
	_golpe_visible = false
	queue_redraw()

func _draw() -> void:
	if _golpe_visible:
		draw_rect(_golpe_rect, Color(1, 1, 1, 0.35))

func recibir_dano(cantidad: int, _origen: Vector2 = Vector2.ZERO) -> void:
	if invulnerable or vida <= 0:
		return
	vida -= cantidad
	GameProgress.vida_jugador = vida
	print("Vida jugador: ", vida)
	vida_cambiada.emit(vida, vida_maxima)

	if vida <= 0:
		murio.emit()
		_mostrar_derrota()
		return

	invulnerable = true
	animated_sprite.modulate = Color(1, 0.4, 0.4)
	await get_tree().create_timer(0.7).timeout
	animated_sprite.modulate = Color.WHITE
	invulnerable = false
