extends CharacterBody2D
# Proyectil de Palanaitor. Lo configura el jefe justo después de instanciarlo.

var direccion := Vector2.DOWN
var velocidad := 120.0
var dano := 2
var vida_util := 3.0        # segundos antes de desaparecer sola
var tirador: Node           # quien la disparó, para no chocar con él


func _ready() -> void:
	get_tree().create_timer(vida_util, false).timeout.connect(queue_free)


func _physics_process(delta: float) -> void:
	var colision := move_and_collide(direccion * velocidad * delta)
	if colision == null:
		return
	var cuerpo := colision.get_collider()
	if cuerpo != null and cuerpo != tirador and cuerpo.has_method("recibir_dano"):
		cuerpo.recibir_dano(dano, global_position)
	queue_free()   # choca con jugador o pared: desaparece
