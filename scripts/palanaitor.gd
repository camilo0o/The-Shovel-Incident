extends CharacterBody2D

signal murio

enum Estado { LIBRE, ATACANDO, MUERTO }

@export var vida_maxima := 12
@export var velocidad := 40.0
@export var rango_deteccion := 240.0
@export var rango_ataque := 42.0
@export var dano := 2
@export var duracion_ataque := 0.8
@export var cooldown_ataque := 1.2
@export var fuerza_retroceso := 140.0
@export var nivel_index := 0
@export var monedas_al_morir := 1

@onready var sprite: AnimatedSprite2D = $AnimatedSprite
@onready var colision: CollisionShape2D = $CollisionShape2D

var vida := 0
var estado := Estado.LIBRE
var jugador: Node2D
var puede_atacar := true
var empuje := Vector2.ZERO
var _ultima_animacion: StringName = &"caminar_abajo"
var _barra_vida: ProgressBar


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	add_to_group("enemigos")
	vida = vida_maxima
	_crear_barra_vida()
	_pose_reposo()


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
	elif distancia > rango_deteccion:
		velocity = Vector2.ZERO
		_pose_reposo()
	elif distancia > rango_ataque:
		velocity = hacia_jugador.normalized() * velocidad
		sprite.play(_animacion_hacia_jugador())
	else:
		velocity = Vector2.ZERO
		_pose_reposo()
		if puede_atacar:
			_atacar()
	empuje = empuje.move_toward(Vector2.ZERO, 600.0 * delta)
	velocity += empuje
	move_and_slide()


func _animacion_hacia_jugador() -> StringName:
	if not is_instance_valid(jugador):
		return _ultima_animacion
	var direccion := jugador.global_position - global_position
	if direccion == Vector2.ZERO:
		return _ultima_animacion
	if absf(direccion.x) > absf(direccion.y):
		_ultima_animacion = &"caminar_derecha" if direccion.x > 0.0 else &"caminar_izquierda"
	else:
		_ultima_animacion = &"caminar_abajo" if direccion.y > 0.0 else &"caminar_arriba"
	return _ultima_animacion


func _pose_reposo() -> void:
	sprite.animation = _animacion_hacia_jugador()
	sprite.stop()
	sprite.frame = 0


func _atacar() -> void:
	if estado != Estado.LIBRE or not puede_atacar or not is_instance_valid(jugador):
		return
	estado = Estado.ATACANDO
	puede_atacar = false
	sprite.play(_animacion_hacia_jugador())
	var duracion := maxf(duracion_ataque, 0.1)
	await get_tree().create_timer(duracion * 0.5, false).timeout
	if estado == Estado.MUERTO:
		return
	if is_instance_valid(jugador) and global_position.distance_to(jugador.global_position) <= rango_ataque * 1.3:
		if jugador.has_method("recibir_dano"):
			jugador.recibir_dano(dano, global_position)
	await get_tree().create_timer(duracion * 0.5, false).timeout
	if estado == Estado.MUERTO:
		return
	estado = Estado.LIBRE
	_pose_reposo()
	await get_tree().create_timer(cooldown_ataque, false).timeout
	if estado != Estado.MUERTO:
		puede_atacar = true


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
	murio.emit()
	sprite.modulate = Color(1, 0.3, 0.3)
	var tween := create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 0.4)
	tween.tween_callback(queue_free)
	GameProgress.agregar_monedas(monedas_al_morir)
	GameProgress.complete_level(nivel_index)


func _crear_barra_vida() -> void:
	_barra_vida = ProgressBar.new()
	_barra_vida.max_value = vida_maxima
	_barra_vida.value = vida
	_barra_vida.show_percentage = false
	_barra_vida.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_barra_vida.size = Vector2(60, 5)
	_barra_vida.position = Vector2(-30, -106)
	_barra_vida.z_index = 10
	var fondo := StyleBoxFlat.new()
	fondo.bg_color = Color(0.1, 0.1, 0.1, 0.85)
	var relleno := StyleBoxFlat.new()
	relleno.bg_color = Color(0.85, 0.15, 0.15)
	_barra_vida.add_theme_stylebox_override("background", fondo)
	_barra_vida.add_theme_stylebox_override("fill", relleno)
	add_child(_barra_vida)
