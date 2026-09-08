extends Control

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/player.tscn")

func _on_options_pressed() -> void:
	print("Opciones")
	get_tree().change_scene_to_file("res://scenes/settings.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
