extends SceneTree

var errores := 0


func _initialize() -> void:
	_run.call_deferred()


func _comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		errores += 1
		push_error(mensaje)


func _run() -> void:
	var pala = load("res://assets/sprites/enemies/pala mala/pala mala.tscn").instantiate()
	_comprobar(pala is CharacterBody2D and pala.has_method("recibir_dano"),
		"La Pala Mala debe perseguir y recibir golpes como un enemigo físico.")
	if errores > 0:
		pala.free()
		quit(1)
		return

	var jugador = load("res://scenes/player.tscn").instantiate()
	root.add_child(jugador)
	jugador.set_physics_process(false)
	var palin = load("res://scenes/palin.tscn").instantiate()
	root.add_child(palin)
	palin.set_physics_process(false)
	root.add_child(pala)
	pala.set_physics_process(false)
	pala.es_jefe = false
	pala.jugador = jugador
	_comprobar(pala.is_in_group("enemigos") and pala.collision_layer == 4,
		"Los puños y las balas deben detectar a la Pala Mala.")

	palin.recibir_dano(2)
	pala.recibir_dano(2)
	_comprobar(palin.vida <= 0 and pala.vida > 0,
		"La Pala Mala debe sobrevivir al golpe que mata a Palín.")
	pala.empuje = Vector2.ZERO
	_comprobar(pala._barra_vida.value == pala.vida,
		"La barra debe reflejar la vida restante tras un golpe.")

	for caso in [
		[Vector2(100, 0), &"pala mala derecha"],
		[Vector2(-100, 0), &"pala mala izquierda"],
		[Vector2(0, -100), &"pala mala arriba"],
		[Vector2(0, 100), &"pala mala abajo"],
	]:
		jugador.global_position = pala.global_position + caso[0]
		pala._physics_process(0.016)
		_comprobar(pala.velocity.dot(caso[0]) > 0 and pala.sprite.animation == caso[1],
			"Debe caminar hacia el jugador con la animación " + str(caso[1]))

	jugador.global_position = pala.global_position + Vector2(500, 0)
	pala._physics_process(0.016)
	_comprobar(pala.velocity == Vector2.ZERO and not pala.sprite.is_playing(),
		"Debe quedarse quieta cuando el jugador sale del rango de detección.")

	pala.duracion_ataque = 0.1
	pala.cooldown_ataque = 0.05
	jugador.global_position = pala.global_position + Vector2(30, 0)
	pala._atacar()
	await create_timer(0.08).timeout
	_comprobar(jugador.vida == 3, "Su golpe debe quitar 2 de vida al jugador.")
	await create_timer(0.75).timeout
	_comprobar(pala.puede_atacar, "Debe poder volver a atacar tras el cooldown.")

	jugador.global_position = pala.global_position + Vector2(30, 0)
	pala._atacar()
	jugador.global_position = pala.global_position + Vector2(500, 0)
	await create_timer(0.2).timeout
	_comprobar(jugador.vida == 3, "Alejarse antes del impacto debe esquivar el golpe.")

	var progreso = root.get_node("GameProgress")
	progreso.level_completed[0] = false
	progreso.level_unlocked[1] = false
	pala.es_jefe = true
	jugador.global_position = pala.global_position + Vector2(30, 0)
	pala._atacar()
	pala.recibir_dano(pala.vida)
	await create_timer(0.2).timeout
	_comprobar(jugador.vida == 3, "Morir durante la preparación debe cancelar el golpe.")
	_comprobar(progreso.level_completed[0] and progreso.level_unlocked[1] and paused,
		"Derrotar al jefe debe completar el nivel, desbloquear el siguiente y mostrar victoria.")
	paused = false
	await create_timer(0.5).timeout
	_comprobar(not is_instance_valid(pala), "El jefe debe desaparecer después de morir.")
	jugador.queue_free()
	await process_frame
	print("Pala Mala: ", "OK" if errores == 0 else str(errores) + " fallos")
	quit(0 if errores == 0 else 1)
