
extends Node2D

@export var cantidad: int = 20
@export var velocidad: float = 45.0
@export var turbulencia: float = 18.0
@export var ancho: float = 3.0
@export var altura: float = 10.0

var rng := RandomNumberGenerator.new()
var particulas: Array[Dictionary] = []


func _ready() -> void:
	rng.randomize()

	for i in range(cantidad):
		particulas.append(crear_particula(true))


func crear_particula(inicial: bool) -> Dictionary:
	return {
		"pos": Vector2(
			rng.randf_range(-ancho / 2.0, ancho / 2.0),
			rng.randf_range(-altura, 0.0) if inicial else 0.0
		),
		"vida": rng.randf_range(0.35, 0.8),
		"edad": rng.randf_range(0.0, 0.8) if inicial else 0.0,
		"fase": rng.randf_range(0.0, TAU),
		"tamano": rng.randf_range(0.3, 0.8),
		"deriva": rng.randf_range(-1.0, 1.0)
	}


func _process(delta: float) -> void:
	for i in range(particulas.size()):
		var p: Dictionary = particulas[i]
		p["edad"] += delta

		if p["edad"] >= p["vida"]:
			particulas[i] = crear_particula(false)
			continue

		var pos: Vector2 = p["pos"]
		var fase: float = p["fase"]

		pos.y -= velocidad * delta
		pos.x += (
			p["deriva"] * 10.0
			+ sin(p["edad"] * 9.0 + fase) * turbulencia
		) * delta

		p["pos"] = pos

	queue_redraw()


func _draw() -> void:
	for p in particulas:
		var progreso: float = p["edad"] / p["vida"]
		var pos: Vector2 = p["pos"]
		var radio: float = p["tamano"]

		var color: Color
		if progreso < 0.3:
			color = Color(1.0, 0.85, 0.25, 1.0)
		elif progreso < 0.7:
			color = Color(1.0, 0.35, 0.05, 0.85)
		else:
			color = Color(0.8, 0.12, 0.02, 0.4)

		color.a *= 1.0 - progreso

		draw_circle(pos, radio, color)
