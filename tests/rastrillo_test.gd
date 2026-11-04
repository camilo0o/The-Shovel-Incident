extends SceneTree

var errores := 0
var escena_rastrillo: PackedScene


func _initialize() -> void:
	_run.call_deferred()


func comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		errores += 1
		push_error(mensaje)


func nuevo_rastrillo(mundo: Node, jugador: Node2D, nombre: String, posicion: Vector2):
	var enemigo = escena_rastrillo.instantiate()
	enemigo.name = nombre
	enemigo.position = posicion
	mundo.add_child(enemigo)
	enemigo.set_physics_process(false)
	enemigo.jugador = jugador
	enemigo.sprite.sprite_frames = enemigo.sprite.sprite_frames.duplicate(true)
	for animacion in [&"attack_left", &"attack_right"]:
		enemigo.sprite.sprite_frames.set_animation_speed(animacion, 40.0)
	enemigo.cooldown_ataque = 0.05
	return enemigo


func _run() -> void:
	escena_rastrillo = load("res://scenes/rastrillo.tscn")
	var progreso = root.get_node("GameProgress")
	progreso.armas_robadas.clear()
	progreso.vida_jugador = -1
	var bate: ArmaData = load("res://resources/armas/bate.tres")
	var pistola: ArmaData = load("res://resources/armas/pistola_clavos.tres")
	progreso.armas_desbloqueadas.append(pistola)
	progreso.equipar_arma(bate)
	var mundo := Node2D.new()
	mundo.name = "PruebaRastrillo"
	root.add_child(mundo)
	current_scene = mundo
	var jugador = load("res://scenes/player.tscn").instantiate()
	jugador.vida_maxima = 30
	mundo.add_child(jugador)
	jugador.set_physics_process(false)
	jugador.position = Vector2(400, 400)
	jugador.last_direction = "right"
	var ladron = nuevo_rastrillo(mundo, jugador, "Ladron", Vector2(426, 400))
	var inocente = nuevo_rastrillo(mundo, jugador, "Inocente", Vector2(700, 400))
	await physics_frame
	await process_frame
	comprobar(ladron.is_in_group("enemigos") and ladron.collision_layer == 4,
		"Los ataques del jugador deben detectar al rastrillo.")
	var hacia_jugador: Vector2 = jugador.position - inocente.position
	inocente.rango_deteccion = 400
	inocente._physics_process(0.016)
	comprobar(inocente.velocity.dot(hacia_jugador) > 0,
		"El rastrillo debe perseguir al jugador dentro del rango.")
	inocente.rango_deteccion = 140
	inocente._physics_process(0.016)
	comprobar(inocente.velocity == Vector2.ZERO, "Debe detenerse fuera del rango.")

	# Robar durante la preparación del bate debe cancelar su impacto pendiente.
	jugador.atacar_con_arma()
	ladron._impactar()
	comprobar(jugador.vida == 29 and jugador.arma == null and progreso.arma_equipada == null,
		"Un golpe aceptado debe dañar y desequipar el arma.")
	comprobar(ladron.arma_robada == bate and ladron.indicador_arma.visible,
		"El ladrón debe guardar y mostrar el arma robada.")
	await create_timer(0.12).timeout
	comprobar(ladron.vida == ladron.vida_maxima and not jugador._arma_pivote.visible,
		"El arma robada no debe quedar visible ni completar un golpe fantasma.")
	inocente.recibir_dano(inocente.vida)
	comprobar(jugador.arma == null and ladron.arma_robada == bate,
		"Matar otro rastrillo no debe devolver el arma.")
	jugador.atacar_con_puno()
	comprobar(ladron.vida == ladron.vida_maxima - jugador.dano_puno,
		"El jugador debe poder seguir dañando al ladrón a puñetazos.")
	var monedas_antes: int = progreso.monedas
	ladron.recibir_dano(ladron.vida)
	ladron.recibir_dano(1)
	comprobar(jugador.arma == bate and progreso.armas_robadas.is_empty(),
		"Matar al ladrón debe devolver y reequipar exactamente su arma.")
	await process_frame
	var botines := mundo.find_children("*", "Area2D", false, false).filter(
		func(nodo): return nodo.scene_file_path == "res://scenes/moneda_pickup.tscn")
	comprobar(botines.size() == 2 and progreso.monedas == monedas_antes,
		"Cada rastrillo debe soltar un solo botín y no completar el nivel.")

	# Los ataques ignorados por invulnerabilidad tampoco pueden robar.
	var inmune = nuevo_rastrillo(mundo, jugador, "Inmune", Vector2(426, 400))
	var vida_antes: int = jugador.vida
	inmune._atacar()
	await create_timer(0.15).timeout
	comprobar(jugador.vida == vida_antes and jugador.arma == bate and inmune.arma_robada == null,
		"La invulnerabilidad debe proteger tanto la vida como el arma.")
	await create_timer(0.65).timeout

	# Esquivar antes del impacto debe impedir daño y robo.
	var esquivado = nuevo_rastrillo(mundo, jugador, "Esquivado", Vector2(426, 400))
	esquivado._atacar()
	jugador.position = Vector2(600, 400)
	await create_timer(0.2).timeout
	comprobar(jugador.vida == vida_antes and jugador.arma == bate,
		"Alejarse antes del impacto debe esquivar daño y desarme.")

	# La pausa congela el ataque completo, incluido el robo.
	jugador.position = Vector2(400, 400)
	var pausado = nuevo_rastrillo(mundo, jugador, "Pausado", Vector2(426, 400))
	pausado._atacar()
	paused = true
	await create_timer(0.25).timeout
	comprobar(jugador.vida == vida_antes and jugador.arma == bate,
		"El rastrillo no debe dañar ni robar durante la pausa.")
	paused = false
	await create_timer(0.12).timeout
	comprobar(jugador.vida == vida_antes - 1 and pausado.arma_robada == bate,
		"El golpe debe continuar al reanudar.")
	pausado.recibir_dano(pausado.vida)
	await create_timer(0.75).timeout

	# Morir en preparación cancela tanto el daño como el desarme.
	vida_antes = jugador.vida
	var interrumpido = nuevo_rastrillo(mundo, jugador, "Interrumpido", Vector2(426, 400))
	interrumpido._atacar()
	interrumpido.recibir_dano(interrumpido.vida)
	await create_timer(0.2).timeout
	comprobar(jugador.vida == vida_antes and jugador.arma == bate,
		"Matar al rastrillo antes del impacto debe cancelar su golpe.")

	# Cada ladrón conserva su propia arma; un robo no puede sobrescribir otro.
	var primero = nuevo_rastrillo(mundo, jugador, "Primero", Vector2(426, 400))
	primero._impactar()
	progreso.equipar_arma(pistola)
	await create_timer(0.75).timeout
	primero._impactar()
	comprobar(primero.arma_robada == bate and jugador.arma == pistola,
		"Un rastrillo que ya tiene un arma no debe reemplazarla por otra.")
	await create_timer(0.75).timeout
	var segundo = nuevo_rastrillo(mundo, jugador, "Segundo", Vector2(426, 400))
	segundo._impactar()
	comprobar(segundo.arma_robada == pistola and not jugador._hud_municion.visible,
		"Otro rastrillo puede robar la pistola y debe ocultarse su HUD de munición.")
	var municion_antes: int = jugador.municion
	jugador.atacar_con_arma()
	comprobar(jugador.municion == municion_antes, "Sin arma no se debe gastar munición.")
	primero.recibir_dano(primero.vida)
	comprobar(jugador.arma == bate and segundo.arma_robada == pistola,
		"Cada ladrón debe devolver solo el arma que guarda.")
	segundo.recibir_dano(segundo.vida)
	comprobar(jugador.arma == pistola and jugador._hud_municion.visible,
		"Recuperar la pistola debe restaurar su visual y HUD.")
	await create_timer(0.75).timeout

	# Recargar la escena no debe borrar el arma que hay que recuperar.
	var persistente = nuevo_rastrillo(mundo, jugador, "Persistente", Vector2(426, 400))
	persistente._impactar()
	persistente.free()
	persistente = nuevo_rastrillo(mundo, jugador, "Persistente", Vector2(426, 400))
	comprobar(persistente.arma_robada == pistola and persistente.indicador_arma.visible,
		"Al reaparecer, el mismo rastrillo debe seguir guardando el arma robada.")
	persistente.recibir_dano(persistente.vida)
	comprobar(jugador.arma == pistola and progreso.armas_robadas.is_empty(),
		"El arma debe poder recuperarse también después de recargar.")
	await create_timer(0.75).timeout

	progreso.equipar_arma(null)
	var sin_arma = nuevo_rastrillo(mundo, jugador, "SinArma", Vector2(426, 400))
	vida_antes = jugador.vida
	sin_arma._impactar()
	comprobar(jugador.vida == vida_antes - 1 and sin_arma.arma_robada == null,
		"Si el jugador no lleva arma, el rastrillo igualmente debe dañarlo.")
	sin_arma.recibir_dano(sin_arma.vida)
	comprobar(jugador.arma == null, "Un enemigo sin botín no debe inventar un arma.")

	# Las balas siguen detectando y dañando al nuevo enemigo.
	var blanco = nuevo_rastrillo(mundo, jugador, "Blanco", Vector2(600, 400))
	var bala = load("res://scenes/bala.tscn").instantiate()
	bala.position = Vector2(570, 400)
	bala.direccion = Vector2.RIGHT
	bala.tirador = jugador
	mundo.add_child(bala)
	await create_timer(0.2).timeout
	comprobar(blanco.vida == blanco.vida_maxima - 1, "Las balas deben dañar al rastrillo.")

	# El combate normal sigue funcionando después de perder y recuperar armas.
	jugador.position = Vector2(900, 400)
	var blanco_bate = nuevo_rastrillo(mundo, jugador, "BlancoBate", Vector2(926, 400))
	progreso.equipar_arma(bate)
	await physics_frame
	await process_frame
	jugador.atacar_con_arma()
	await create_timer(0.12).timeout
	comprobar(blanco_bate.vida == blanco_bate.vida_maxima - bate.dano,
		"El bate recuperado debe seguir impactando con su daño normal.")
	blanco_bate.queue_free()
	var blanco_pistola = nuevo_rastrillo(mundo, jugador, "BlancoPistola", Vector2(1020, 400))
	progreso.equipar_arma(pistola)
	jugador.mira_vector = Vector2.RIGHT
	municion_antes = jugador.municion
	jugador.atacar_con_arma()
	await create_timer(0.5).timeout
	comprobar(blanco_pistola.vida == blanco_pistola.vida_maxima - pistola.dano
		and jugador.municion == municion_antes - 1 and jugador.puede_usar_arma,
		"La pistola debe disparar, gastar una bala y completar su cooldown normalmente.")
	mundo.queue_free()
	await process_frame

	# Verifica la integración con las colisiones reales del nivel 3.
	progreso.vida_jugador = -1
	var nivel = load("res://scenes/level3.tscn").instantiate()
	root.add_child(nivel)
	current_scene = nivel
	nivel.get_node("Player").set_physics_process(false)
	var enemigos: Array = nivel.get_node("Enemies").get_children()
	comprobar(enemigos.size() == 5, "El nivel 3 debe tener cinco rastrillos.")
	for enemigo in enemigos:
		enemigo.set_physics_process(false)
	await physics_frame
	await process_frame
	for enemigo in enemigos:
		var consulta := PhysicsShapeQueryParameters2D.new()
		consulta.shape = enemigo.get_node("CollisionShape2D").shape
		consulta.transform = enemigo.global_transform
		consulta.collision_mask = 1
		comprobar(nivel.get_world_2d().direct_space_state.intersect_shape(consulta).is_empty(),
			"El rastrillo %s no debe aparecer dentro de paredes o muebles." % enemigo.name)
	nivel.queue_free()
	await process_frame
	print("Rastrillo: ", "OK" if errores == 0 else str(errores) + " fallos")
	quit(0 if errores == 0 else 1)
