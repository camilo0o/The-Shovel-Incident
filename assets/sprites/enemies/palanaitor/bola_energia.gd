extends CharacterBody2D
## Proyectil independiente de Palanaitor. La animacion se repite mientras viaja.
## Para disparar: instanciar bola_energia.tscn, llamar iniciar(rumbo, self),
## agregarla al nivel y colocar su global_position en la palma de la mano.

@export var velocidad := 220.0
@export var dano := 1
@export var vida_util := 4.0
@export var direccion := Vector2.RIGHT

var tirador: PhysicsBody2D
var _tiempo_restante := 0.0

@onready var animacion: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	_tiempo_restante = vida_util
	iniciar(direccion, tirador)
	animacion.play(&"energia")


func iniciar(rumbo: Vector2, quien_dispara: PhysicsBody2D = null) -> void:
	# Se puede llamar antes o despues de agregar el proyectil al nivel.
	if is_instance_valid(tirador):
		remove_collision_exception_with(tirador)
	tirador = quien_dispara
	direccion = rumbo.normalized() if not rumbo.is_zero_approx() else Vector2.RIGHT
	if is_instance_valid(tirador):
		add_collision_exception_with(tirador)


func _physics_process(delta: float) -> void:
	_tiempo_restante -= delta
	if _tiempo_restante <= 0.0:
		queue_free()
		return

	velocity = direccion.normalized() * velocidad
	# Barrer todo el recorrido evita atravesar paredes finas a alta velocidad.
	var colision := move_and_collide(velocity * delta)
	if colision == null:
		return

	var cuerpo := colision.get_collider()
	if cuerpo is Node and cuerpo.is_in_group(&"jugador") and cuerpo.has_method("recibir_dano"):
		cuerpo.call("recibir_dano", dano, global_position - direccion * 10.0)
	set_physics_process(false)
	queue_free()
