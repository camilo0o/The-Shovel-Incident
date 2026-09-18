extends Area2D

func _on_body_entered(body):
	print("Hola")
	if body.name == "Player":
		get_tree().change_scene_to_file("res://scenes/boss_room_1.tscn")
