extends Control

@onready var slider:HSlider = $MarginContainer/VBoxContainer/Volume
@onready var mute:CheckBox = $MarginContainer/VBoxContainer/Mute
@onready var btn_volver: Button = $MarginContainer/VBoxContainer/Volver

func _ready() -> void:
	slider.set_value_no_signal(db_to_linear(AudioServer.get_bus_volume_db(0)))
	mute.set_pressed_no_signal(AudioServer.is_bus_mute(0))
	btn_volver.pressed.connect(GameProgress.volver)

func _on_volume_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(value))

func _on_mute_toggled(toggled_on: bool) -> void:
	AudioServer.set_bus_mute(0, toggled_on)
