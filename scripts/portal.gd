extends Area2D

@export_file("*.tscn") var escena_destino: String = "res://scenes/boss_room_1.tscn"

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.name == "Player":
		call_deferred("_cambiar_escena")

func _cambiar_escena() -> void:
	Fade.cambiar_escena(escena_destino)
