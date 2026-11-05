extends CharacterBody2D
# Enemigo del nivel 3. Su comportamiento no hereda de otros personajes.

signal murio

enum Estado { LIBRE, ATACANDO, MUERTO }

@export var vida_maxima := 3
@export var velocidad := 45.0
@export var rango_deteccion := 140.0
@export var rango_ataque := 32.0
@export var dano := 1
@export var cooldown_ataque := 1.6
@export_range(0.1, 0.9) var momento_golpe := 0.65
@export var fuerza_retroceso := 120.0
@export var monedas_al_morir := 2

@export_group("Sonido")
@export var sonido_idle: AudioStream
@export var intervalo_sonido_min := 3.0
@export var intervalo_sonido_max := 7.0

const MONEDA_SCENE := preload("res://scenes/moneda_pickup.tscn")

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var colision: CollisionShape2D = $CollisionShape2D
@onready var indicador_arma: Sprite2D = $ArmaRobada

var vida := 0
var estado := Estado.LIBRE
var jugador: Node2D
var puede_atacar := true
var empuje := Vector2.ZERO
var arma_robada: ArmaData
var _identificador_robo: String
var _barra_vida: ProgressBar
var _audio: AudioStreamPlayer2D


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	add_to_group("enemigos")
	vida = vida_maxima
	_identificador_robo = str(get_path())
	arma_robada = GameProgress.armas_robadas.get(_identificador_robo)
	_crear_barra_vida()
	_actualizar_indicador_arma()
	_pose_reposo()
	_crear_audio()
	_bucle_sonido()


func _physics_process(delta: float) -> void:
	if estado == Estado.MUERTO:
		return
	if not is_instance_valid(jugador):
		jugador = get_tree().get_first_node_in_group("jugador") as Node2D
		if jugador == null:
			return
	var hacia_jugador := jugador.global_position - global_position
	var distancia := hacia_jugador.length()
	if estado == Estado.ATACANDO:
		velocity = Vector2.ZERO
	elif distancia > rango_deteccion or jugador.invisible:
		velocity = Vector2.ZERO
		_pose_reposo()
	elif distancia > rango_ataque:
		velocity = hacia_jugador.normalized() * velocidad
		sprite.offset = Vector2.ZERO
		sprite.play(&"movement")
	else:
		velocity = Vector2.ZERO
		_pose_reposo()
		if puede_atacar:
			_atacar()
	empuje = empuje.move_toward(Vector2.ZERO, 600.0 * delta)
	velocity += empuje
	move_and_slide()


func _pose_reposo() -> void:
	sprite.offset = Vector2.ZERO
	sprite.animation = &"movement"
	sprite.stop()
	sprite.frame = 0


func _atacar() -> void:
	if estado != Estado.LIBRE or not puede_atacar or not is_instance_valid(jugador):
		return
	estado = Estado.ATACANDO
	puede_atacar = false
	var derecha := jugador.global_position.x >= global_position.x
	var animacion := &"attack_right" if derecha else &"attack_left"
	# Compensa los márgenes diferentes de las hojas de ataque y caminata.
	sprite.offset = Vector2(14 if derecha else -14, -16)
	sprite.play(animacion)
	var frames := sprite.sprite_frames
	var duracion := frames.get_frame_count(animacion) / frames.get_animation_speed(animacion)
	await get_tree().create_timer(duracion * momento_golpe, false).timeout
	if estado == Estado.MUERTO:
		return
	_impactar()
	await get_tree().create_timer(duracion * (1.0 - momento_golpe), false).timeout
	if estado == Estado.MUERTO:
		return
	estado = Estado.LIBRE
	_pose_reposo()
	await get_tree().create_timer(cooldown_ataque, false).timeout
	if estado != Estado.MUERTO:
		puede_atacar = true


func _impactar() -> void:
	if not is_instance_valid(jugador):
		return
	if global_position.distance_to(jugador.global_position) > rango_ataque * 1.3:
		return
	if arma_robada == null and jugador.has_method("recibir_ataque_desarmante"):
		arma_robada = jugador.recibir_ataque_desarmante(dano, global_position)
		if arma_robada != null:
			GameProgress.armas_robadas[_identificador_robo] = arma_robada
			_actualizar_indicador_arma()
	elif jugador.has_method("recibir_dano"):
		jugador.recibir_dano(dano, global_position)


func recibir_dano(cantidad: int, origen: Vector2 = Vector2.ZERO) -> void:
	if estado == Estado.MUERTO:
		return
	vida -= cantidad
	_barra_vida.value = vida
	if origen != Vector2.ZERO:
		empuje = (global_position - origen).normalized() * fuerza_retroceso
	if vida <= 0:
		_morir()
		return
	sprite.modulate = Color(1, 0.3, 0.3)
	await get_tree().create_timer(0.1, false).timeout
	if estado != Estado.MUERTO:
		sprite.modulate = Color.WHITE


func _morir() -> void:
	estado = Estado.MUERTO
	velocity = Vector2.ZERO
	puede_atacar = false
	set_physics_process(false)
	colision.set_deferred("disabled", true)
	_barra_vida.hide()
	if _audio != null:
		_audio.stop()
	indicador_arma.hide()
	_devolver_arma()
	murio.emit()
	GameProgress.carpi_evento.emit(&"kill")
	_soltar_moneda.call_deferred(global_position)
	var tween := create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 0.4)
	tween.tween_callback(queue_free)


func _devolver_arma() -> void:
	if arma_robada == null:
		return
	GameProgress.armas_robadas.erase(_identificador_robo)
	var recuperada := arma_robada
	arma_robada = null
	var objetivo := get_tree().get_first_node_in_group("jugador")
	if objetivo != null and objetivo.has_method("recuperar_arma"):
		objetivo.recuperar_arma(recuperada)
	else:
		GameProgress.equipar_arma(recuperada)


func _actualizar_indicador_arma() -> void:
	indicador_arma.visible = arma_robada != null and arma_robada.icono != null
	if not indicador_arma.visible:
		return
	indicador_arma.texture = arma_robada.icono
	var lado_mayor := maxf(indicador_arma.texture.get_width(), indicador_arma.texture.get_height())
	indicador_arma.scale = Vector2.ONE * (16.0 / maxf(lado_mayor, 1.0))


func _soltar_moneda(posicion: Vector2) -> void:
	var escena := get_tree().current_scene
	if escena == null:
		return
	var moneda := MONEDA_SCENE.instantiate()
	moneda.cantidad = monedas_al_morir
	escena.add_child(moneda)
	moneda.global_position = posicion


func _crear_barra_vida() -> void:
	_barra_vida = ProgressBar.new()
	_barra_vida.max_value = vida_maxima
	_barra_vida.value = vida
	_barra_vida.show_percentage = false
	_barra_vida.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_barra_vida.size = Vector2(22, 4)
	_barra_vida.position = Vector2(-11, -25)
	_barra_vida.z_index = 10
	var fondo := StyleBoxFlat.new()
	fondo.bg_color = Color(0.1, 0.1, 0.1, 0.85)
	var relleno := StyleBoxFlat.new()
	relleno.bg_color = Color(0.85, 0.15, 0.15)
	_barra_vida.add_theme_stylebox_override("background", fondo)
	_barra_vida.add_theme_stylebox_override("fill", relleno)
	add_child(_barra_vida)


func _crear_audio() -> void:
	if sonido_idle == null:
		return
	_audio = AudioStreamPlayer2D.new()
	_audio.stream = sonido_idle
	_audio.max_distance = 300.0
	add_child(_audio)


func _bucle_sonido() -> void:
	if _audio == null:
		return
	await get_tree().create_timer(randf_range(0.5, intervalo_sonido_max), false).timeout
	while estado != Estado.MUERTO:
		_audio.play()
		await _audio.finished
		await get_tree().create_timer(randf_range(intervalo_sonido_min, intervalo_sonido_max), false).timeout
