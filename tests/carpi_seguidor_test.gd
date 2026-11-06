extends SceneTree

var errores := 0


func _initialize() -> void:
	_run.call_deferred()


func comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		errores += 1
		push_error(mensaje)


func _run() -> void:
	var mundo := Node2D.new()
	root.add_child(mundo)
	current_scene = mundo
	var suelo := Node2D.new()
	mundo.add_child(suelo)
	var jugador = load("res://scenes/player.tscn").instantiate()
	mundo.add_child(jugador)
	jugador.set_physics_process(false)
	jugador.position = Vector2(200, 200)
	var carpi = load("res://scenes/carpi2.tscn").instantiate()
	mundo.add_child(carpi)
	carpi.set_process(false)

	# Al ir hacia arriba, el seguidor esta mas cerca de la camara que el jugador.
	# Al volver hacia abajo, debe quedar oculto detras de el.
	for separacion in [Vector2(0, 20), Vector2(0, -20), Vector2(0, 20)]:
		carpi.global_position = jugador.global_position + separacion
		carpi._process(0.0)
		var delante: bool = separacion.y > 0.0
		comprobar((carpi.get_index() > jugador.get_index()) == delante,
			"Carpi debe cambiar de profundidad al cruzar al jugador")
		comprobar(carpi.get_index() > suelo.get_index(), "Carpi debe conservarse sobre el suelo")
		comprobar(carpi._globo.z_index == 20, "Los dialogos deben conservar su profundidad")

	# Al detenerse tras caminar en cualquiera de las cuatro direcciones,
	# debe quedar espacio entre los sprites, incluso con un frame lento.
	for rumbo in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
		carpi.global_position = jugador.global_position - rumbo * 100.0
		for i in range(120):
			carpi._process(1.0 / 60.0)
		var separacion: float = carpi.global_position.distance_to(jugador.global_position)
		comprobar(separacion >= 28.0 and separacion <= 40.0,
			"El seguidor debe detenerse con espacio para no quedar bajo los pies")
		carpi.global_position = jugador.global_position - rumbo * 100.0
		carpi._process(2.0)
		comprobar(carpi.global_position.distance_to(jugador.global_position) >= 28.0,
			"Un frame lento no debe hacer que Carpi alcance o atraviese al jugador")
		comprobar((jugador.global_position - carpi.global_position).dot(rumbo) > 0.0,
			"Carpi no debe pasarse al otro lado del jugador al seguirlo")

	mundo.free()
	print("CARPI_SEGUIDOR: ", "PASS" if errores == 0 else "FAIL", " (", errores, " errores)")
	quit(0 if errores == 0 else 1)
