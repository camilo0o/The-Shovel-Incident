extends Area2D
# Proyectil del ataque largo. Lo instancia player.gd.

var direccion := Vector2.RIGHT
var velocidad := 260.0
var dano := 1
var vida_util := 1.2        # segundos antes de desaparecer sola
var tirador: Node           # quien la disparó, para no chocar con él


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	get_tree().create_timer(vida_util).timeout.connect(queue_free)


func _physics_process(delta: float) -> void:
	position += direccion * velocidad * delta


func _on_body_entered(body: Node) -> void:
	if body == tirador:
		return
	if body.has_method("recibir_dano"):
		body.recibir_dano(dano, global_position - direccion * 10.0)
	queue_free()   # se destruye al tocar un enemigo o una pared


# Círculo provisional; reemplazar por un Sprite2D (ej. municion.png)
func _draw() -> void:
	draw_circle(Vector2.ZERO, 3.0, Color(1.0, 0.9, 0.3))
