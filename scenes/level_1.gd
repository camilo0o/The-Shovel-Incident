extends Node2D


func _on_portal_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		get_tree().change_scene_to_file("res://scenes/boss_room_1.tscn")
