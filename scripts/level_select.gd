extends Control

@onready var btn1: Button = $Botones/Nivel1
@onready var btn2: Button = $Botones/Nivel2
@onready var btn3: Button = $Botones/Nivel3
@onready var btn_volver: Button = $Botones/Volver

var textura_candado = preload("res://assets/elements/candado.png")

func _ready():
	configurar_boton(btn1, 0)
	configurar_boton(btn2, 1)
	configurar_boton(btn3, 2)
	btn_volver.pressed.connect(_volver_al_garage)

func configurar_boton(boton: Button, indice: int) -> void:
	var desbloqueado := GameProgress.is_unlocked(indice)
	boton.disabled = not desbloqueado
	boton.text = "Nivel %d" % (indice + 1)

	if desbloqueado:
		boton.icon = null
	else:
		boton.icon = textura_candado
		boton.add_theme_constant_override("icon_max_width", 24)

	boton.pressed.connect(func(): GameProgress.go_to_level(indice))

func _volver_al_garage() -> void:
	get_tree().change_scene_to_file("res://scenes/garage.tscn")
