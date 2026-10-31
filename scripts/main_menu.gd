
extends Control


func _ready() -> void:
	var botones = $Botones.get_children()

	for boton in botones:
		if boton is Button:
			boton.focus_mode = Control.FOCUS_ALL

			var color_original = boton.get_theme_color("font_color")
			boton.add_theme_color_override("font_focus_color", color_original)

	$Botones/Start.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interactuar"):
		var boton := get_viewport().gui_get_focus_owner()

		if boton is Button and not boton.disabled:
			get_viewport().set_input_as_handled()
			boton.pressed.emit()


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/garage.tscn")


func _on_options_pressed() -> void:
	print("Opciones")
	get_tree().change_scene_to_file("res://scenes/settings.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_watch_intro_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/introduction.tscn")
