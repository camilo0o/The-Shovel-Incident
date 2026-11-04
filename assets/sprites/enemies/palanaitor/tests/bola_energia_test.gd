extends SceneTree

const ESCENA := "res://scenes/bola_energia.tscn"

var errores := 0
var escena: PackedScene


class Objetivo:
	extends CharacterBody2D

	var vida := 5
	var impactos := 0

	func recibir_dano(cantidad: int, _origen: Vector2 = Vector2.ZERO) -> void:
		vida -= cantidad
		impactos += 1


func _initialize() -> void:
	_run.call_deferred()


func comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		errores += 1
		push_error(mensaje)


func crear_mundo() -> Node2D:
	var mundo := Node2D.new()
	root.add_child(mundo)
	return mundo


func agregar_forma(cuerpo: CollisionObject2D) -> void:
	var forma := CollisionShape2D.new()
	var circulo := CircleShape2D.new()
	circulo.radius = 8.0
	forma.shape = circulo
	cuerpo.add_child(forma)


func crear_bola(mundo: Node2D, rumbo := Vector2.RIGHT, tirador: PhysicsBody2D = null):
	var bola = escena.instantiate()
	bola.velocidad = 100.0
	bola.vida_util = 3.0
	bola.iniciar(rumbo, tirador)
	mundo.add_child(bola)
	# Avanzamos la simulacion con pasos conocidos para comprobar impactos rapidos.
	bola.set_physics_process(false)
	return bola


func _run() -> void:
	if not ResourceLoader.exists(ESCENA):
		print("FAIL: todavia no existe la escena de la bola de energia")
		quit(1)
		return
	escena = load(ESCENA)
	if escena == null:
		quit(1)
		return

	# El material debe ocultar la cuadricula y conservar solo los seis cuadros azules.
	var mundo := crear_mundo()
	var bola = crear_bola(mundo, Vector2(3, 4))
	var sprite: AnimatedSprite2D = bola.get_node("AnimatedSprite2D")
	comprobar(sprite.sprite_frames.get_frame_count(&"energia") == 6, "Faltan cuadros azules")
	comprobar(sprite.is_playing(), "La animacion no comienza al crear la bola")
	comprobar(sprite.sprite_frames.get_animation_loop(&"energia"), "La animacion debe repetirse")
	comprobar(sprite.material is ShaderMaterial, "El PNG opaco necesita el material de transparencia")
	for i in range(sprite.sprite_frames.get_frame_count(&"energia")):
		var textura: AtlasTexture = sprite.sprite_frames.get_frame_texture(&"energia", i)
		comprobar(textura.region.position.y >= 640, "Se incluyo una llama de la fila superior")
	bola._physics_process(0.5)
	comprobar(bola.position.is_equal_approx(Vector2(30, 40)), "La direccion diagonal cambia la velocidad")
	var frame_inicial := sprite.frame
	for i in range(10):
		await process_frame
	comprobar(sprite.frame != frame_inicial or sprite.frame_progress > 0.0, "La animacion no avanza")
	mundo.free()

	# Un proyectil rapido debe golpear al jugador una vez y desaparecer.
	mundo = crear_mundo()
	var jugador := Objetivo.new()
	jugador.position = Vector2(80, 0)
	agregar_forma(jugador)
	jugador.add_to_group("jugador")
	mundo.add_child(jugador)
	bola = crear_bola(mundo)
	bola.dano = 2
	await physics_frame
	await physics_frame
	bola._physics_process(1.0)
	comprobar(jugador.vida == 3 and jugador.impactos == 1, "El jugador no recibio el dano correcto una sola vez")
	comprobar(bola.is_queued_for_deletion(), "La bola no desaparece al golpear al jugador")
	mundo.free()

	# Una pared fina detiene el disparo antes de que alcance al jugador.
	for capa in [1, 2]:
		mundo = crear_mundo()
		var pared := StaticBody2D.new()
		pared.collision_layer = capa
		pared.position = Vector2(40, 0)
		agregar_forma(pared)
		mundo.add_child(pared)
		jugador = Objetivo.new()
		jugador.position = Vector2(80, 0)
		agregar_forma(jugador)
		jugador.add_to_group("jugador")
		mundo.add_child(jugador)
		bola = crear_bola(mundo)
		await physics_frame
		await physics_frame
		bola._physics_process(1.0)
		comprobar(bola.is_queued_for_deletion(), "La bola atraviesa la pared de capa %d" % capa)
		comprobar(jugador.vida == 5, "El disparo hizo dano a traves de la pared")
		mundo.free()

	# La mano puede estar dentro del cuerpo del tirador: el disparo debe salir igual.
	mundo = crear_mundo()
	var tirador := Objetivo.new()
	agregar_forma(tirador)
	mundo.add_child(tirador)
	bola = crear_bola(mundo, Vector2.RIGHT, tirador)
	await physics_frame
	await physics_frame
	bola._physics_process(1.0)
	comprobar(not bola.is_queued_for_deletion(), "La bola golpea al personaje que la disparo")
	comprobar(bola.position.x > 90.0 and tirador.vida == 5, "La bola no pudo salir del tirador")
	mundo.free()

	# El tiempo de vida evita dejar proyectiles viajando indefinidamente.
	mundo = crear_mundo()
	bola = crear_bola(mundo)
	bola._physics_process(3.1)
	comprobar(bola.is_queued_for_deletion(), "La bola no desaparece al terminar su vida util")
	mundo.free()

	print("BOLA_ENERGIA: ", "PASS" if errores == 0 else "FAIL", " (", errores, " errores)")
	quit(0 if errores == 0 else 1)
