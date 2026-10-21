extends Area2D

func _on_body_entered(body):
	print("Hola")
	if body.name == "Player":
		Fade.cambiar_escena("res://scenes/boss_room_1.tscn")
