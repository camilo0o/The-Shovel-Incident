extends SceneTree

var errores := 0


func _initialize() -> void:
	_run.call_deferred()


func comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		errores += 1
		push_error(mensaje)


func _run() -> void:
	var escena: PackedScene = load("res://scenes/palanaitor.tscn")
	# Palmas medidas en los cuadros de 200 x 200 con el brazo extendido.
	var casos := [
		[Vector2.RIGHT, Vector2(64, -35), "derecha"],
		[Vector2.LEFT, Vector2(-64, -35), "izquierda"],
		[Vector2.DOWN, Vector2(-56, -30), "frente"],
		[Vector2.UP, Vector2(74, -40), "espalda"],
	]
	for furia in [false, true]:
		for caso in casos:
			var mundo := Node2D.new()
			mundo.position = Vector2(80, 120)
			mundo.scale = Vector2(1.2, 1.2)
			root.add_child(mundo)
			current_scene = mundo
			var jefe = escena.instantiate()
			mundo.add_child(jefe)
			jefe.set_physics_process(false)
			jefe.position = Vector2(250, 250)
			jefe.furia = furia
			jefe.velocidad_bola = 0.0
			var jugador := Node2D.new()
			mundo.add_child(jugador)
			jugador.global_position = jefe.global_position + caso[0] * 180.0
			jefe.jugador = jugador
			jefe._disparar_energia()
			await create_timer(jefe.duracion_disparo * 0.6).timeout
			var bolas: Array[Node] = []
			for nodo in mundo.get_children():
				if nodo.scene_file_path == "res://scenes/bola_energia.tscn":
					bolas.append(nodo)
			comprobar(bolas.size() == (3 if furia else 1),
				"Cantidad de disparos incorrecta hacia " + caso[2])
			var palma: Vector2 = jefe.sprite.to_global(caso[1])
			for bola in bolas:
				comprobar(bola.global_position.distance_to(palma) < 5.0,
					"La bola debe salir de la palma hacia " + caso[2])
			if not bolas.is_empty():
				var central = bolas[1] if furia else bolas[0]
				var rumbo: Vector2 = (jugador.global_position - central.global_position).normalized()
				comprobar(central.direccion.is_equal_approx(rumbo),
					"El disparo central debe apuntar desde la mano al jugador")
			# Dejar terminar la recuperacion antes de liberar al jefe.
			await create_timer(jefe.duracion_disparo * 0.5).timeout
			mundo.free()
	print("PALANAITOR_ENERGIA: ", "PASS" if errores == 0 else "FAIL",
		" (", errores, " errores)")
	quit(0 if errores == 0 else 1)
