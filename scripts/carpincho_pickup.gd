extends Area2D
# Moneda carpincho naranja: la moneda con la que se compran skins en el probador.
@export var cantidad := 1

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("jugador"):
		GameProgress.agregar_carpinchos(cantidad)
		queue_free()
