extends Sprite2D
const C_ENERGIA := Color("5ad7ff")
const C_EQUIPADA := Color("b17bff")

var _t := 0.0
var _estado := 0
var _particulas: CPUParticles2D


func _ready() -> void:
	_crear_particulas()
	GameProgress.habilidad_cambiada.connect(func(_e): _actualizar_estado())
	GameProgress.nivel_completado.connect(func(_i): _actualizar_estado())
	_actualizar_estado()


func _actualizar_estado() -> void:
	if not GameProgress.invisibilidad_desbloqueada():
		_estado = 0
	elif GameProgress.invisibilidad_equipada:
		_estado = 2
	else:
		_estado = 1
	_particulas.emitting = _estado > 0
	_particulas.amount = 22 if _estado == 2 else 12
	_particulas.color = C_EQUIPADA if _estado == 2 else C_ENERGIA


func _process(delta: float) -> void:
	_t += delta
	var pulso := 0.5 + 0.5 * sin(_t * 2.5)
	match _estado:
		0:
			modulate = Color(0.45, 0.45, 0.5)
		1:
			modulate = Color.WHITE.lerp(C_ENERGIA, 0.15 + 0.25 * pulso)
		_:
			modulate = Color.WHITE.lerp(C_EQUIPADA, 0.2 + 0.3 * pulso)


func _crear_particulas() -> void:
	_particulas = CPUParticles2D.new()
	_particulas.position = Vector2(0, -38)
	_particulas.amount = 12
	_particulas.lifetime = 2.2
	_particulas.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	_particulas.emission_sphere_radius = 10.0
	_particulas.direction = Vector2.UP
	_particulas.spread = 25.0
	_particulas.gravity = Vector2.ZERO
	_particulas.initial_velocity_min = 6.0
	_particulas.initial_velocity_max = 14.0
	_particulas.scale_amount_min = 1.0
	_particulas.scale_amount_max = 2.0
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 0.9))
	g.set_color(1, Color(1, 1, 1, 0.0))
	_particulas.color_ramp = g
	add_child(_particulas)
