extends Area2D
@export var cantidad := 15


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("jugador") and body.has_method("agregar_municion"):
		body.agregar_municion(cantidad)
		queue_free()
