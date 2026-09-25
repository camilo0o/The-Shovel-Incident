extends Node2D

const MAIN_MENU_PATH := "res://scenes/main_menu.tscn"

@onready var video: VideoStreamPlayer = $VideoStreamPlayer

func _ready() -> void:
	video.finished.connect(_go_to_main_menu)
	video.play()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		video.stop()
		_go_to_main_menu()

func _go_to_main_menu() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_PATH)

func _on_skip_button_pressed() -> void:
	video.stop()
	_go_to_main_menu()
