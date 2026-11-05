extends CharacterBody2D

signal murio

enum Estado { LIBRE, ATACANDO, MUERTO }

const BOLA_SCENE := preload("res://scenes/bola_energia.tscn")

@export_group("Estadísticas")
@export var vida_maxima := 40
@export var velocidad := 45.0
@export var rango_deteccion := 400.0
@export var fuerza_retroceso := 60.0   # bajo: es un jefe, casi no se empuja

@export_group("Patada (cuerpo a cuerpo)")
@export var rango_ataque := 48.0
@export var dano := 2
@export var duracion_ataque := 0.8
@export var cooldown_ataque := 1.0

@export_group("Energía (a distancia)")
@export var rango_energia_min := 90.0
@export var rango_energia_max := 280.0
@export var dano_energia := 2
@export var velocidad_bola := 120.0
@export var duracion_disparo := 0.8
@export var cooldown_energia := 2.5

@export_group("Gritos")
@export var gritos: Array[AudioStream] = []        # risas, burlas, rugidos... (arrastrá varios)
@export var gritos_furia: Array[AudioStream] = []  # opcional: solo suenan en furia
@export var grito_muerte: AudioStream              # opcional
@export var intervalo_grito_min := 6.0
@export var intervalo_grito_max := 14.0
@export var volumen_gritos_db := 0.0
@export var distancia_maxima_gritos := 500.0

@export_group("Jefe de nivel")
@export var nivel_index := 2            # nivel 3 = índice 2
@export var monedas_al_morir := 5

@onready var sprite: AnimatedSprite2D = $AnimatedSprite
@onready var colision: CollisionShape2D = $CollisionShape2D

var vida := 0
var estado := Estado.LIBRE
var jugador: Node2D
var puede_patear := true
var puede_disparar := true
var furia := false
var empuje := Vector2.ZERO
var _ultima_direccion := &"frente"
var _barra_vida: ProgressBar
var _audio: AudioStreamPlayer2D
var _ultimo_grito := -1


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	add_to_group("enemigos")
	vida = vida_maxima
	_crear_barra_vida()
	_pose_reposo()
	_crear_audio()
	_bucle_gritos()


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
	elif distancia <= rango_ataque:
		velocity = Vector2.ZERO
		_pose_reposo()
		if puede_patear:
			_patear()
	elif puede_disparar and distancia >= rango_energia_min and distancia <= rango_energia_max:
		velocity = Vector2.ZERO
		_disparar_energia()
	else:
		var vel := velocidad * (1.4 if furia else 1.0)
		velocity = hacia_jugador.normalized() * vel
		var anim := "caminar_" + String(_direccion_a_sufijo_caminar())
		if sprite.animation != StringName(anim) or not sprite.is_playing():
			sprite.play(anim)

	empuje = empuje.move_toward(Vector2.ZERO, 600.0 * delta)
	velocity += empuje
	move_and_slide()



func _crear_audio() -> void:
	_audio = AudioStreamPlayer2D.new()
	_audio.volume_db = volumen_gritos_db
	_audio.max_distance = distancia_maxima_gritos
	add_child(_audio)


func _bucle_gritos() -> void:
	if gritos.is_empty() and gritos_furia.is_empty():
		return
	await get_tree().create_timer(randf_range(2.0, intervalo_grito_min), false).timeout
	while estado != Estado.MUERTO:
		var lista := _lista_de_gritos()
		if not lista.is_empty():
			_audio.stream = _elegir_sin_repetir(lista)
			_audio.play()
			await _audio.finished
			if estado == Estado.MUERTO:
				return
		await get_tree().create_timer(
				randf_range(intervalo_grito_min, intervalo_grito_max) * (0.6 if furia else 1.0),
				false).timeout


func _lista_de_gritos() -> Array[AudioStream]:
	var lista: Array[AudioStream] = []
	lista.append_array(gritos)
	if furia:
		lista.append_array(gritos_furia)
	return lista


func _elegir_sin_repetir(lista: Array[AudioStream]) -> AudioStream:
	if lista.size() == 1:
		return lista[0]
	var i := randi() % lista.size()
	if i == _ultimo_grito:
		i = (i + 1) % lista.size()
	_ultimo_grito = i
	return lista[i]

func _actualizar_direccion() -> void:
	if not is_instance_valid(jugador):
		return
	var d := jugador.global_position - global_position
	if d == Vector2.ZERO:
		return
	if absf(d.x) > absf(d.y):
		_ultima_direccion = &"derecha" if d.x > 0.0 else &"izquierda"
	else:
		_ultima_direccion = &"frente" if d.y > 0.0 else &"espalda"


func _direccion_a_sufijo_caminar() -> StringName:
	_actualizar_direccion()
	match _ultima_direccion:
		&"frente": return &"abajo"
		&"espalda": return &"arriba"
		_: return _ultima_direccion


func _pose_reposo() -> void:
	sprite.animation = StringName("caminar_" + String(_direccion_a_sufijo_caminar()))
	sprite.stop()
	sprite.frame = 0


func _reproducir_ataque(prefijo: String, duracion: float) -> void:
	_actualizar_direccion()
	var anim := StringName(prefijo + String(_ultima_direccion))
	if sprite.sprite_frames.has_animation(anim):
		var frames := sprite.sprite_frames.get_frame_count(anim)
		var fps := sprite.sprite_frames.get_animation_speed(anim)
		sprite.speed_scale = frames / (fps * duracion)
		sprite.play(anim)


func _patear() -> void:
	if estado != Estado.LIBRE or not puede_patear or not is_instance_valid(jugador):
		return
	estado = Estado.ATACANDO
	puede_patear = false
	var duracion := maxf(duracion_ataque, 0.1)
	_reproducir_ataque("palanaitor_patada_", duracion)

	await get_tree().create_timer(duracion * 0.5, false).timeout
	if estado == Estado.MUERTO:
		return
	if is_instance_valid(jugador) and global_position.distance_to(jugador.global_position) <= rango_ataque * 1.3:
		if jugador.has_method("recibir_dano"):
			jugador.recibir_dano(dano, global_position)

	await get_tree().create_timer(duracion * 0.5, false).timeout
	if estado == Estado.MUERTO:
		return
	sprite.speed_scale = 1.0
	estado = Estado.LIBRE
	_pose_reposo()

	await get_tree().create_timer(cooldown_ataque * (0.7 if furia else 1.0), false).timeout
	if estado != Estado.MUERTO:
		puede_patear = true


func _disparar_energia() -> void:
	if estado != Estado.LIBRE or not puede_disparar or not is_instance_valid(jugador):
		return
	estado = Estado.ATACANDO
	puede_disparar = false
	var duracion := maxf(duracion_disparo, 0.1)
	_reproducir_ataque("palanaitor_ataque_energia_", duracion)

	# La bola sale a mitad de la animación.
	await get_tree().create_timer(duracion * 0.5, false).timeout
	if estado == Estado.MUERTO:
		return
	if is_instance_valid(jugador):
		var base := (jugador.global_position - global_position).normalized()
		if furia:
			for angulo in [-0.35, 0.0, 0.35]:
				_lanzar_bola(base.rotated(angulo))
		else:
			_lanzar_bola(base)

	await get_tree().create_timer(duracion * 0.5, false).timeout
	if estado == Estado.MUERTO:
		return
	sprite.speed_scale = 1.0
	estado = Estado.LIBRE
	_pose_reposo()

	await get_tree().create_timer(cooldown_energia * (0.7 if furia else 1.0), false).timeout
	if estado != Estado.MUERTO:
		puede_disparar = true


func _lanzar_bola(direccion: Vector2) -> void:
	var bola := BOLA_SCENE.instantiate()
	bola.direccion = direccion
	bola.velocidad = velocidad_bola
	bola.dano = dano_energia
	bola.tirador = self
	get_tree().current_scene.add_child(bola)
	bola.global_position = global_position + Vector2(0, -20)


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
	if not furia and vida <= vida_maxima / 2:
		furia = true
		sprite.modulate = Color(1, 0.5, 0.2)
	sprite.modulate = Color(1, 0.3, 0.3)
	await get_tree().create_timer(0.1, false).timeout
	if estado != Estado.MUERTO:
		sprite.modulate = Color(1, 0.6, 0.4) if furia else Color.WHITE


func _morir() -> void:
	estado = Estado.MUERTO
	velocity = Vector2.ZERO
	puede_patear = false
	puede_disparar = false
	set_physics_process(false)
	colision.set_deferred("disabled", true)
	_barra_vida.hide()
	_audio.stop()
	if grito_muerte != null:
		# Reproductor aparte: este nodo se libera al terminar el fade.
		var p := AudioStreamPlayer2D.new()
		p.stream = grito_muerte
		p.volume_db = volumen_gritos_db
		p.max_distance = distancia_maxima_gritos
		get_tree().current_scene.add_child(p)
		p.global_position = global_position
		p.finished.connect(p.queue_free)
		p.play()
	murio.emit()
	sprite.modulate = Color(1, 0.3, 0.3)
	var tween := create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 0.6)
	tween.tween_callback(queue_free)
	GameProgress.agregar_monedas(monedas_al_morir)
	GameProgress.complete_level(nivel_index)   # dispara el cartel de victoria


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
