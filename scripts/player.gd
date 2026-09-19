extends CharacterBody2D
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite

signal vida_cambiada(vida_actual: int, vida_maxima: int)
signal murio

const MASK_ENEMIGOS := 1 << 2   # capa de colisión 3 = enemigos

# Controles: clic izq / J = piñazo (siempre disponible)
#            clic der / K = arma elegida en la armería
# Para invertirlos alcanza con intercambiar estas dos constantes.
const ACCION_PUNO := "ataque_corto"
const ACCION_ARMA := "ataque_largo"

const TEXTURA_PUNO := preload("res://assets/sprites/armas/puno.png")

@export var vida_maxima := 5
@export var municion := 60

@export_group("Piñazo")
@export var dano_puno := 1
@export var alcance_puno := 16.0
@export var tamano_puno := Vector2(16, 16)
@export var cooldown_puno := 0.3

@export_group("Proyectil")
@export var bala_scene: PackedScene = preload("res://scenes/bala.tscn")

@export_group("Debug")
@export var debug_hitbox := false   # dibuja la caja del golpe

var speed = 100.0
var last_direction = "front"

var vida := 0
var invulnerable := false

var arma: ArmaData = null            # se sincroniza con GameProgress.arma_equipada
var puede_pegar_puno := true
var puede_usar_arma := true

var _arma_pivote: Node2D             # queda en la mano; el arma gira alrededor de este punto
var _arma_sprite: Sprite2D
var _puno_sprite: Sprite2D
var _animando_arma := false
var _direccion_dibujada := ""

var _golpe_visible := false
var _golpe_rect := Rect2()


func _ready() -> void:
	add_to_group("jugador")
	vida = vida_maxima
	_crear_visuales_de_ataque()
	GameProgress.arma_cambiada.connect(_on_arma_cambiada)
	_on_arma_cambiada(GameProgress.arma_equipada)


func _physics_process(_delta: float) -> void:
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


# Golpe genérico: daña a todo enemigo dentro de una caja delante del jugador.
# Lo usan el piñazo y las armas cuerpo a cuerpo. Devuelve cuántos golpeó.

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


# Ñapi: siempre disponible, con o sin arma

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


# Arma equipada: solo se puede usar la que se eligió en la armería

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
	var base := _direccion_vector().angle() + PI / 2.0     # el arma mira hacia arriba con rotación 0
	var signo := -1.0 if last_direction == "left" else 1.0
	var inicio := base - signo * deg_to_rad(70.0)
	inicio = _arma_pivote.rotation + angle_difference(_arma_pivote.rotation, inicio)   # evita dar vueltas de más

	var tween := create_tween()
	tween.tween_property(_arma_pivote, "rotation", inicio, 0.05)          # preparación
	tween.tween_callback(_impactar_arma)                                  # el golpe cae acá
	tween.tween_property(_arma_pivote, "rotation", inicio + signo * deg_to_rad(140.0), 0.09)   # tajo
	await tween.finished
	_animando_arma = false

func _impactar_arma() -> void:
	_golpear(arma.dano, arma.alcance, arma.tamano_golpe)

func _disparar() -> void:
	if arma.consume_municion:
		municion -= 1

	var dir := _direccion_vector()
	var bala := bala_scene.instantiate()
	bala.direccion = dir
	bala.dano = arma.dano
	bala.velocidad = arma.velocidad_bala
	bala.vida_util = arma.vida_util_bala
	bala.textura = arma.bala_textura
	bala.tirador = self
	get_tree().current_scene.add_child(bala)
	bala.global_position = global_position + dir * arma.distancia_boca

	# retroceso visual del arma
	_animando_arma = true
	var pos0 := _arma_pivote.position
	var tween := create_tween()
	tween.tween_property(_arma_pivote, "position", pos0 - dir * 3.0, 0.04)
	tween.tween_property(_arma_pivote, "position", pos0, 0.08)
	await tween.finished
	_animando_arma = false

func agregar_municion(cantidad: int) -> void:
	municion += cantidad


# Arma en la mano

func _crear_visuales_de_ataque() -> void:
	_arma_pivote = Node2D.new()
	_arma_pivote.visible = false
	add_child(_arma_pivote)

	_arma_sprite = Sprite2D.new()
	_arma_sprite.offset = Vector2(0, -8)   # el pivote queda en el mango, el arma "crece" hacia arriba
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
			# el pivote queda en la base del arma sin importar su alto
			_arma_sprite.offset = Vector2(0, -arma.icono.get_height() / 2.0)
	_actualizar_arma_visual()

func _actualizar_arma_visual() -> void:
	if arma == null or _animando_arma:
		return
	_arma_pivote.position = _posicion_mano()
	_arma_pivote.rotation = _rotacion_reposo()

	if _direccion_dibujada != last_direction:
		_direccion_dibujada = last_direction
		# de espaldas el arma queda detrás del cuerpo; en el resto, delante
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
		return _direccion_vector().angle() + PI / 2.0   # apunta hacia donde mira
	var inclinacion := deg_to_rad(20.0)
	return -inclinacion if (last_direction == "left" or last_direction == "back") else inclinacion


# Feedback visual opcional de la caja del golpe (Debug > debug_hitbox)
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
