extends Node2D

func _on_portal_body_entered(body):
	if body.name == "Player":
		call_deferred("_cambiar_escena")

func _cambiar_escena():
	Fade.cambiar_escena("res://scenes/boss_room_1.tscn")
