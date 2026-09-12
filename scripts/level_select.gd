extends Control

@onready var btn1: Button = $Nivel1
@onready var btn2: Button = $Nivel2
@onready var btn3: Button = $Nivel3

func _ready():
	btn1.disabled = not GameProgress.is_unlocked(0)
	btn2.disabled = not GameProgress.is_unlocked(1)
	btn3.disabled = not GameProgress.is_unlocked(2)

	btn1.pressed.connect(func(): GameProgress.go_to_level(0))
	btn2.pressed.connect(func(): GameProgress.go_to_level(1))
	btn3.pressed.connect(func(): GameProgress.go_to_level(2))
