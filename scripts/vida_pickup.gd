extends Area2D

@export var cantidad := 1

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("jugador") and body.has_method("curar"):
		body.curar(cantidad)
		queue_free()
