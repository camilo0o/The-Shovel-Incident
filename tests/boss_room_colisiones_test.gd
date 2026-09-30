extends SceneTree

var errores := 0


func _initialize() -> void:
	_run.call_deferred()


func _comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		errores += 1
		push_error(mensaje)


func _run() -> void:
	var sala = load("res://scenes/boss_room_1.tscn").instantiate()
	root.add_child(sala)
	var pala: CharacterBody2D = sala.get_node("PalaMala")
	var jugador: CharacterBody2D = sala.get_node("Player")
	pala.set_physics_process(false)
	jugador.set_physics_process(false)
	var decoracion: TileMapLayer = sala.get_node("Decoracion2")
	var base: TileMapLayer = sala.get_node("Base2")
	var casos := [
		[decoracion.tile_set, Vector2i(5, 9), false, "libro"],
		[decoracion.tile_set, Vector2i(17, 6), false, "respaldo de silla"],
		[decoracion.tile_set, Vector2i(16, 7), false, "silla izquierda"],
		[decoracion.tile_set, Vector2i(17, 7), false, "silla central"],
		[decoracion.tile_set, Vector2i(18, 7), false, "silla derecha"],
		[decoracion.tile_set, Vector2i(16, 8), false, "patas de silla izquierda"],
		[decoracion.tile_set, Vector2i(17, 8), false, "patas de silla central"],
		[decoracion.tile_set, Vector2i(18, 8), false, "patas de silla derecha"],
		[decoracion.tile_set, Vector2i(14, 4), true, "mueble grande"],
		[base.tile_set, Vector2i(0, 0), true, "pared"],
	]
	for caso in casos:
		# Aísla un tile real de la sala para comprobar el recorrido completo
		# sin que otro objeto del mapa oculte su comportamiento.
		var mapa := TileMapLayer.new()
		mapa.tile_set = caso[0]
		mapa.position = Vector2(1000, 1000)
		mapa.set_cell(Vector2i.ZERO, 0, caso[1])
		sala.add_child(mapa)
		mapa.update_internals()
		await physics_frame
		await process_frame
		var inicio := Transform2D(0.0, mapa.to_global(mapa.map_to_local(Vector2i.ZERO)) - Vector2(48, 0))
		var recorrido := Vector2(96, 0)
		_comprobar(pala.test_move(inicio, recorrido) == caso[2],
			"Colisión incorrecta de la Pala Mala con " + str(caso[3]))
		# El cuerpo del jugador está a la altura de sus pies, debajo del origen.
		var inicio_jugador := inicio
		inicio_jugador.origin.y -= 8.0
		_comprobar(jugador.test_move(inicio_jugador, recorrido),
			"La colisión del jugador debe conservarse con " + str(caso[3]))
		mapa.queue_free()
		await process_frame
	sala.queue_free()
	await process_frame
	print("BossRoom1 colisiones: ", "OK" if errores == 0 else str(errores) + " fallos")
	quit(0 if errores == 0 else 1)
