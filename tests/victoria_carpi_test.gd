extends SceneTree

var errores := 0


func _initialize() -> void:
	_run.call_deferred()


func comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		errores += 1
		push_error(mensaje)


func _run() -> void:
	var progreso := root.get_node("GameProgress")
	for nivel in [0, 1, 2]:
		var mundo := Node2D.new()
		root.add_child(mundo)
		current_scene = mundo
		var jugador = load("res://scenes/player.tscn").instantiate()
		mundo.add_child(jugador)
		jugador.set_physics_process(false)
		var interfaz = jugador.get_node("InterfazPartida")
		var resultado = interfaz.get_node("ResultadoPartida")
		progreso.complete_level(nivel)
		comprobar(paused and resultado._panel_victoria.visible,
			"La victoria debe mostrarse y pausar el juego")
		comprobar(not interfaz.menu_pausa.habilitado, "El menu de pausa debe quedar deshabilitado")
		var carpi: TextureRect = resultado.find_child("CarpiFisicoculturista", true, false)
		comprobar((carpi != null) == (nivel == 2),
			"Las poses de Carpi deben aparecer solo al completar el nivel 3")
		if carpi != null:
			var pose: AtlasTexture = carpi.texture
			comprobar(pose != null and pose.region.position.x == 0.0,
				"Carpi debe empezar con el doble biceps de frente")
			var ancho := pose.region.size.x
			await create_timer(1.65).timeout
			comprobar(pose.region.position.x == ancho and paused,
				"Carpi debe pasar a la pose de espalda aun con el juego pausado")
		var caja: VBoxContainer = resultado._panel_victoria.get_meta("caja")
		var boton: Button
		for hijo in caja.get_children():
			if hijo is Button:
				boton = hijo
		comprobar(boton != null and boton.has_focus(),
			"El boton para volver a niveles debe conservar el foco del teclado")
		var cantidad := caja.get_child_count()
		progreso.complete_level(nivel)
		comprobar(caja.get_child_count() == cantidad, "La victoria no debe duplicar imagenes ni frases")
		paused = false
		mundo.free()
	print("VICTORIA_CARPI: ", "PASS" if errores == 0 else "FAIL", " (", errores, " errores)")
	quit(0 if errores == 0 else 1)
