extends CharacterBody2D

signal murio

@export var vida_maxima := 2
@export var velocidad := 40.0            # el jugador va a 100
@export var rango_deteccion := 120.0     # a esta distancia empieza a perseguir
@export var rango_ataque := 26.0         # a esta distancia ataca
@export var dano := 1
@export var cooldown_ataque := 1.2       # pausa entre ataques
@export var fuerza_retroceso := 140.0    # empujón al recibir un golpe

enum Estado { LIBRE, ATACANDO, MUERTO }

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var colision: CollisionShape2D = $CollisionShape2D

var vida := 0
var estado := Estado.LIBRE
var jugador: Node2D
var puede_atacar := true
var empuje := Vector2.ZERO


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING  # vista cenital, sin "suelo"
	add_to_group("enemigos")
	vida = vida_maxima
	_pose_reposo()


func _physics_process(delta: float) -> void:
	# El jugador se busca acá y no en _ready() porque puede no existir todavía.
	if jugador == null:
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
		_caminar()
	else:
		velocity = Vector2.ZERO
		_pose_reposo()
		if puede_atacar:
			_atacar()

	empuje = empuje.move_toward(Vector2.ZERO, 600.0 * delta)
	velocity += empuje
	move_and_slide()


# Ataque de Palin al jugador

func _atacar() -> void:
	estado = Estado.ATACANDO
	puede_atacar = false

	var anim := &"attack_right" if jugador.global_position.x >= global_position.x else &"attack_left"
	sprite.play(anim)
	var duracion := sprite.sprite_frames.get_frame_count(anim) / sprite.sprite_frames.get_animation_speed(anim)

	# El golpe cae a mitad de la animación: si el jugador se aleja antes, lo esquiva.
	await get_tree().create_timer(duracion * 0.5).timeout
	if estado == Estado.MUERTO:
		return
	if jugador != null and global_position.distance_to(jugador.global_position) <= rango_ataque * 1.3:
		if jugador.has_method("recibir_dano"):
			jugador.recibir_dano(dano, global_position)

	await get_tree().create_timer(duracion * 0.5).timeout
	if estado == Estado.MUERTO:
		return
	estado = Estado.LIBRE

	await get_tree().create_timer(cooldown_ataque).timeout
	puede_atacar = true


# Recibir daño (el ataque corto y la bala del jugador)

func recibir_dano(cantidad: int, origen: Vector2 = Vector2.ZERO) -> void:
	if estado == Estado.MUERTO:
		return
	vida -= cantidad

	if origen != Vector2.ZERO:
		empuje = (global_position - origen).normalized() * fuerza_retroceso

	if vida <= 0:
		_morir()
		return

	sprite.modulate = Color(1, 0.3, 0.3)
	await get_tree().create_timer(0.1).timeout
	if estado != Estado.MUERTO:
		sprite.modulate = Color.WHITE


func _morir() -> void:
	estado = Estado.MUERTO
	velocity = Vector2.ZERO
	murio.emit()
	colision.set_deferred("disabled", true)
	set_physics_process(false)
	sprite.modulate = Color(1, 0.3, 0.3)
	var tween := create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 0.4)
	tween.tween_callback(queue_free)


# Animaciones

func _caminar() -> void:
	if sprite.animation != &"movement" or not sprite.is_playing():
		sprite.play(&"movement")


func _pose_reposo() -> void:
	if sprite.animation != &"movement" or sprite.is_playing():
		sprite.animation = &"movement"
		sprite.stop()
		sprite.frame = 0
