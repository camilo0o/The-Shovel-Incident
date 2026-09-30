extends "res://scripts/palin.gd"

# Usa el combate de Palín y las cuatro caminatas disponibles de la Pala Mala.
@export var duracion_ataque := 0.8

var _ultima_animacion: StringName = &"pala mala abajo"


func _ready() -> void:
	super._ready()
	_barra_vida.size.x = 36.0
	_barra_vida.position = Vector2(-18.0, -44.0)


func _animacion_hacia_jugador() -> StringName:
	if not is_instance_valid(jugador):
		return _ultima_animacion
	var direccion := jugador.global_position - global_position
	if direccion == Vector2.ZERO:
		return _ultima_animacion
	if absf(direccion.x) > absf(direccion.y):
		_ultima_animacion = &"pala mala derecha" if direccion.x > 0.0 else &"pala mala izquierda"
	else:
		_ultima_animacion = &"pala mala abajo" if direccion.y > 0.0 else &"pala mala arriba"
	return _ultima_animacion


func _caminar() -> void:
	var animacion := _animacion_hacia_jugador()
	if sprite.animation != animacion or not sprite.is_playing():
		sprite.play(animacion)


func _pose_reposo() -> void:
	sprite.animation = _animacion_hacia_jugador()
	sprite.stop()
	sprite.frame = 0


func _atacar() -> void:
	if estado != Estado.LIBRE or not puede_atacar or not is_instance_valid(jugador):
		return
	estado = Estado.ATACANDO
	puede_atacar = false
	# Todavía no hay una animación de ataque propia: usa la caminata orientada
	# al jugador, con un tiempo de preparación que permite esquivar el golpe.
	sprite.play(_animacion_hacia_jugador())
	var duracion := maxf(duracion_ataque, 0.1)

	await get_tree().create_timer(duracion * 0.5).timeout
	if estado == Estado.MUERTO:
		return
	if is_instance_valid(jugador) and global_position.distance_to(jugador.global_position) <= rango_ataque * 1.3:
		if jugador.has_method("recibir_dano"):
			jugador.recibir_dano(dano, global_position)

	await get_tree().create_timer(duracion * 0.5).timeout
	if estado == Estado.MUERTO:
		return
	estado = Estado.LIBRE
	_pose_reposo()

	await get_tree().create_timer(cooldown_ataque).timeout
	if estado != Estado.MUERTO:
		puede_atacar = true
