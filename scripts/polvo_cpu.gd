
extends Node2D

@export var cantidad: int = 30
@export var area: Vector2 = Vector2(700, 500)
@export var vida: float = 13.66
@export var velocidad: float = 8.0
@export var turbulencia: float = 12.0
@export var frecuencia: float = 1.2
@export var textura: Texture2D

var rng := RandomNumberGenerator.new()
var particulas: Array[Dictionary] = []
var tiempo := 0.0


func _ready() -> void:
	rng.randomize()

	for i in range(cantidad):
		particulas.append(crear_particula(true))


func crear_particula(inicial: bool) -> Dictionary:
	var posicion := Vector2(
		rng.randf_range(-area.x / 2.0, area.x / 2.0),
		rng.randf_range(-area.y / 2.0, area.y / 2.0)
	)

	return {
		"pos": posicion,
		"edad": rng.randf_range(0.0, vida) if inicial else 0.0,
		"fase": rng.randf_range(0.0, TAU),
		"tamano": rng.randf_range(0.3, 0.7),
		"opacidad": rng.randf_range(0.35, 0.9),
		"deriva": rng.randf_range(-0.4, 0.4)
	}


func _process(delta: float) -> void:
	tiempo += delta

	for i in range(particulas.size()):
		var p: Dictionary = particulas[i]
		p["edad"] += delta

		if p["edad"] >= vida:
			particulas[i] = crear_particula(false)
			continue

		var fase: float = p["fase"]
		var pos: Vector2 = p["pos"]

		pos.x += (
			p["deriva"] * velocidad
			+ sin(tiempo * frecuencia + fase) * turbulencia
		) * delta

		pos.y += (
			velocidad * 0.25
			+ cos(tiempo * frecuencia * 0.7 + fase) * turbulencia * 0.4
		) * delta

		if pos.x > area.x / 2.0:
			pos.x = -area.x / 2.0
		elif pos.x < -area.x / 2.0:
			pos.x = area.x / 2.0

		if pos.y > area.y / 2.0:
			pos.y = -area.y / 2.0

		p["pos"] = pos

	queue_redraw()


func _draw() -> void:
	for p in particulas:
		var pos: Vector2 = p["pos"]
		var tamano: float = p["tamano"]
		var alpha: float = p["opacidad"]

		var progreso: float = p["edad"] / vida
		alpha *= minf(1.0, progreso * 5.0)
		alpha *= minf(1.0, (1.0 - progreso) * 5.0)

		var color := Color(0.067, 0.067, 0.067, alpha)

		if textura != null:
			var dimensiones := textura.get_size() * tamano
			draw_texture_rect(
				textura,
				Rect2(pos - dimensiones / 2.0, dimensiones),
				false,
				color
			)
		else:
			draw_circle(pos, tamano * 2.0, color)
