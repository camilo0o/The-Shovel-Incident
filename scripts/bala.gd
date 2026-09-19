extends Area2D
# Proyectil del ataque a distancia. Lo instancia player.gd.

var direccion := Vector2.RIGHT
var velocidad := 260.0
var dano := 1
var vida_util := 1.2        # segundos antes de desaparecer sola
var tirador: Node           # quien la disparó, para no chocar con él
var textura: Texture2D      # sprite del proyectil (apunta hacia arriba); vacío = círculo


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	get_tree().create_timer(vida_util).timeout.connect(queue_free)

	if textura != null:
		var sprite := Sprite2D.new()
		sprite.texture = textura
		sprite.rotation = direccion.angle() + PI / 2.0   # el sprite mira hacia arriba
		add_child(sprite)


func _physics_process(delta: float) -> void:
	position += direccion * velocidad * delta


func _on_body_entered(body: Node) -> void:
	if body == tirador:
		return
	if body.has_method("recibir_dano"):
		body.recibir_dano(dano, global_position - direccion * 10.0)
	queue_free()   # se destruye al tocar un enemigo o una pared


# Círculo de respaldo cuando el arma no define sprite de proyectil
func _draw() -> void:
	if textura == null:
		draw_circle(Vector2.ZERO, 3.0, Color(1.0, 0.9, 0.3))
