extends CharacterBody2D
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite

signal vida_cambiada(vida_actual: int, vida_maxima: int)
signal murio

const MASK_ENEMIGOS := 1 << 2   # capa de colisión 3 = enemigos

@export var vida_maxima := 5

@export_group("Ataque corto (cuerpo a cuerpo)")
@export var dano_corto := 1
@export var alcance_corto := 22.0        # distancia del golpe desde el jugador
@export var tamano_golpe := Vector2(26, 26)
@export var cooldown_corto := 0.35

@export_group("Ataque largo (proyectil)")
@export var bala_scene: PackedScene = preload("res://scenes/bala.tscn")
@export var dano_largo := 1
@export var cooldown_largo := 0.5
@export var municion := 10

var speed = 100.0
var last_direction = "front"

var vida := 0
var invulnerable := false
var puede_atacar_corto := true
var puede_atacar_largo := true

var _golpe_visible := false
var _golpe_rect := Rect2()


func _ready() -> void:
	add_to_group("jugador")
	vida = vida_maxima


func _physics_process(delta: float) -> void:
	get_input()
	move_and_slide()

	if Input.is_action_just_pressed("ataque_corto"):
		ataque_corto()
	elif Input.is_action_just_pressed("ataque_largo"):
		ataque_largo()

func get_input():
	var input_direction = Input.get_vector("left", "right", "up", "down")
	if input_direction == Vector2.ZERO:
		velocity = Vector2.ZERO
		update_animation("idle")
		return
	#Detectar en que eje nos movemos
	if abs(input_direction.x) > abs(input_direction.y):
		#Movimiento horizontal
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

func update_animation(state):
	animated_sprite.play(state + "_" + last_direction)


# Dirección a la que mira el jugador

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


# Ataque corto: golpea todo enemigo dentro de una caja delante del jugador

func ataque_corto() -> void:
	if not puede_atacar_corto:
		return
	puede_atacar_corto = false

	var dir := _direccion_vector()
	var centro_local := dir * alcance_corto

	var forma := RectangleShape2D.new()
	forma.size = tamano_golpe
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
			cuerpo.recibir_dano(dano_corto, global_position)

	_mostrar_golpe(Rect2(centro_local - tamano_golpe / 2.0, tamano_golpe))

	await get_tree().create_timer(cooldown_corto).timeout
	puede_atacar_corto = true


# Feedback visual provisional del golpe (reemplazar por una animación de ataque).
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


# Ataque largo: dispara una bala en la dirección a la que mira

func ataque_largo() -> void:
	if not puede_atacar_largo or municion <= 0:
		return
	puede_atacar_largo = false
	municion -= 1

	var dir := _direccion_vector()
	var bala := bala_scene.instantiate()
	bala.direccion = dir
	bala.dano = dano_largo
	bala.tirador = self
	get_tree().current_scene.add_child(bala)
	bala.global_position = global_position + dir * 12.0

	await get_tree().create_timer(cooldown_largo).timeout
	puede_atacar_largo = true

func agregar_municion(cantidad: int) -> void:
	municion += cantidad


# Recibir daño

func recibir_dano(cantidad: int, _origen: Vector2 = Vector2.ZERO) -> void:
	if invulnerable or vida <= 0:
		return
	vida -= cantidad
	print("Vida jugador: ", vida)   # debug, se puede borrar
	vida_cambiada.emit(vida, vida_maxima)

	if vida <= 0:
		murio.emit()
		# Provisional: reinicia el nivel. Cambiar por pantalla de derrota cuando exista.
		get_tree().call_deferred("reload_current_scene")
		return

	invulnerable = true
	animated_sprite.modulate = Color(1, 0.4, 0.4)
	await get_tree().create_timer(0.7).timeout
	animated_sprite.modulate = Color.WHITE
	invulnerable = false
