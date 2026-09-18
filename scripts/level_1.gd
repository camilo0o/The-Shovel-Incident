extends Node2D

func _on_portal_body_entered(body):
	if body.name == "Player":
		call_deferred("_cambiar_escena")

func _cambiar_escena():
	get_tree().change_scene_to_file("res://scenes/boss_room_1.tscn")
