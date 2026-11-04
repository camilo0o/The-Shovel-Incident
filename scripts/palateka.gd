extends CharacterBody2D
signal murio

enum Estado { LIBRE, ATACANDO, MUERTO }

@export_group("Estadísticas")
@export var vida_maxima := 20
@export var velocidad := 55.0
@export var rango_deteccion := 300.0
@export var rango_ataque := 40.0
@export var dano := 2
@export var duracion_ataque := 0.9
@export_range(0.1, 0.9) var momento_golpe := 0.55
@export var cooldown_ataque := 1.0
@export var fuerza_retroceso := 90.0

@export_group("Jefe de nivel")
@export var es_jefe := true
@export var nivel_index := 1            # nivel 2 = índice 1
@export var monedas_al_morir := 3

@export_group("Sonido")
@export var gritos_ataque: Array[AudioStream] = []   # kiai al atacar (arrastrá varios)
@export var grito_muerte: AudioStream                 # opcional
@export_range(0.4, 1.5) var pitch_voz := 0.8          # < 1.0 = voz más grave/oscura
@export_range(0.0, 0.3) var variacion_pitch := 0.06
@export var volumen_voz_db := 0.0
@export var distancia_maxima_voz := 400.0

@export_group("Ajuste de sprites")
@export var offset_ataque_izquierda := Vector2.ZERO  # las hojas de ataque lateral son más anchas (256 vs 160)
@export var offset_ataque_derecha := Vector2.ZERO

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var colision: CollisionShape2D = $CollisionShape2D

const MONEDA_SCENE := preload("res://scenes/moneda_pickup.tscn")

var vida := 0
var estado := Estado.LIBRE
var jugador: Node2D
var puede_atacar := true
var empuje := Vector2.ZERO
var _dir := &"abajo"          # abajo | arriba | izquierda | derecha
var _barra_vida: ProgressBar
var _audio: AudioStreamPlayer2D
var _ultimo_grito := -1


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	add_to_group("enemigos")
	vida = vida_maxima
	# Las animaciones de ataque se controlan por tiempo: que no hagan loop.
	for anim in sprite.sprite_frames.get_animation_names():
		if String(anim).begins_with("palateka_ataque") or String(anim).begins_with("palateka_atacar"):
			sprite.sprite_frames.set_animation_loop(anim, false)
	_crear_barra_vida()
	_crear_audio()
	_pose_reposo()


func _physics_process(delta: float) -> void:
	if estado == Estado.MUERTO:
		return
	if not is_instance_valid(jugador):
		jugador = get_tree().get_first_node_in_group("jugador") as Node2D
		if not is_instance_valid(jugador):
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
		_caminar(hacia_jugador)
	else:
		velocity = Vector2.ZERO
		_actualizar_direccion(hacia_jugador)
		_pose_reposo()
		if puede_atacar:
			_atacar()

	empuje = empuje.move_toward(Vector2.ZERO, 600.0 * delta)
	velocity += empuje
	move_and_slide()


func _actualizar_direccion(v: Vector2) -> void:
	if v == Vector2.ZERO:
		return
	if absf(v.x) > absf(v.y):
		_dir = &"derecha" if v.x > 0.0 else &"izquierda"
	else:
		_dir = &"abajo" if v.y > 0.0 else &"arriba"


func _anim_caminar() -> StringName:
	match _dir:
		&"arriba": return &"palateka_camina_arriba"
		&"izquierda": return &"palateka_camina_izquierda"
		&"derecha": return &"palateka_caminar_derecha"
	return &"palateka_camina_abajo"


func _anim_ataque() -> StringName:
	match _dir:
		&"arriba": return &"palateka_ataque_espalda"
		&"izquierda": return &"palateka_ataque_izquierda"
		&"derecha": return &"palateka_ataque_derecha"
	return &"palateka_ataque_frente"


func _caminar(v: Vector2) -> void:
	_actualizar_direccion(v)
	var anim := _anim_caminar()
	sprite.offset = Vector2.ZERO
	sprite.speed_scale = 1.0
	if sprite.animation != anim or not sprite.is_playing():
		sprite.play(anim)


func _pose_reposo() -> void:
	sprite.offset = Vector2.ZERO
	sprite.speed_scale = 1.0
	sprite.animation = _anim_caminar()
	sprite.stop()
	sprite.frame = 0


func _atacar() -> void:
	if estado != Estado.LIBRE or not puede_atacar or not is_instance_valid(jugador):
		return
	estado = Estado.ATACANDO
	puede_atacar = false
	var duracion := maxf(duracion_ataque, 0.1)

	var anim := _anim_ataque()
	var frames := sprite.sprite_frames.get_frame_count(anim)
	var fps := sprite.sprite_frames.get_animation_speed(anim)
	sprite.speed_scale = frames / (fps * duracion)
	match _dir:
		&"izquierda": sprite.offset = offset_ataque_izquierda
		&"derecha": sprite.offset = offset_ataque_derecha
		_: sprite.offset = Vector2.ZERO
	sprite.play(anim)
	_gritar()

	await get_tree().create_timer(duracion * momento_golpe, false).timeout
	if estado == Estado.MUERTO:
		return
	if is_instance_valid(jugador) \
			and global_position.distance_to(jugador.global_position) <= rango_ataque * 1.3 \
			and jugador.has_method("recibir_dano"):
		jugador.recibir_dano(dano, global_position)

	await get_tree().create_timer(duracion * (1.0 - momento_golpe), false).timeout
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
	murio.emit()
	colision.set_deferred("disabled", true)
	set_physics_process(false)
	_barra_vida.hide()
	_reproducir_voz(grito_muerte, true)
	sprite.modulate = Color(1, 0.3, 0.3)

	if es_jefe:
		GameProgress.agregar_monedas(monedas_al_morir)
		GameProgress.complete_level(nivel_index)
	else:
		GameProgress.carpi_evento.emit(&"kill")
		_soltar_moneda.call_deferred(global_position)

	var tween := create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 0.4)
	tween.tween_callback(_liberar)


# Deja terminar el grito de muerte antes de liberar el nodo.
func _liberar() -> void:
	if _audio != null and _audio.playing:
		await _audio.finished
	queue_free()


func _soltar_moneda(pos: Vector2) -> void:
	var escena := get_tree().current_scene
	if escena == null:
		return
	var moneda := MONEDA_SCENE.instantiate()
	moneda.cantidad = monedas_al_morir
	escena.add_child(moneda)
	moneda.global_position = pos


func _crear_audio() -> void:
	_audio = AudioStreamPlayer2D.new()
	_audio.volume_db = volumen_voz_db
	_audio.max_distance = distancia_maxima_voz
	add_child(_audio)


func _gritar() -> void:
	if gritos_ataque.is_empty():
		return
	var i := randi() % gritos_ataque.size()
	if gritos_ataque.size() > 1 and i == _ultimo_grito:
		i = (i + 1) % gritos_ataque.size()
	_ultimo_grito = i
	_reproducir_voz(gritos_ataque[i])


func _reproducir_voz(stream: AudioStream, forzar := false) -> void:
	if stream == null or _audio == null:
		return
	if _audio.playing and not forzar:
		return
	_audio.stream = stream
	_audio.pitch_scale = pitch_voz * randf_range(1.0 - variacion_pitch, 1.0 + variacion_pitch)
	_audio.play()


func _crear_barra_vida() -> void:
	_barra_vida = ProgressBar.new()
	_barra_vida.max_value = vida_maxima
	_barra_vida.value = vida
	_barra_vida.show_percentage = false
	_barra_vida.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_barra_vida.size = Vector2(36, 4)
	_barra_vida.position = Vector2(-18, -78)
	_barra_vida.z_index = 10
	var fondo := StyleBoxFlat.new()
	fondo.bg_color = Color(0.1, 0.1, 0.1, 0.85)
	var relleno := StyleBoxFlat.new()
	relleno.bg_color = Color(0.85, 0.15, 0.15)
	_barra_vida.add_theme_stylebox_override("background", fondo)
	_barra_vida.add_theme_stylebox_override("fill", relleno)
	add_child(_barra_vida)
