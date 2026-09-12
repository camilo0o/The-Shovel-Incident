extends Area2D

var prompt_label: Label
@onready var sprite: Sprite2D = $Sprite2D

var textura_cerrada = preload("res://assets/backgrounds/door.png")
var textura_abierta = preload("res://assets/sprites/structures/SpritePuerta-efecto.png")

var player_in_range := false
var abriendo := false

# Cuánto (en píxeles de pantalla) baja el texto respecto al punto de la puerta
const OFFSET_DEBAJO_PUERTA := Vector2(0, 30)

func _ready():
	prompt_label = get_tree().get_first_node_in_group("prompt_label")
	if prompt_label == null:
		push_error("Door: no se encontró ningún nodo en el grupo 'prompt_label'.")
		return
	prompt_label.visible = false
	sprite.texture = textura_cerrada
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(_delta):
	if prompt_label == null:
		return
	# canvas_transform convierte coordenadas del mundo (global_position) a
	# coordenadas de PANTALLA, ya teniendo en cuenta el zoom/posición
	# de la cámara activa. Camera2D no tiene unproject_position (eso es de Camera3D).
	var screen_pos: Vector2 = get_viewport().get_canvas_transform() * global_position
	var ancho: float = prompt_label.size.x
	prompt_label.position = screen_pos + OFFSET_DEBAJO_PUERTA - Vector2(ancho / 2.0, 0)

func _on_body_entered(body):
	if body.name == "Player":
		player_in_range = true
		if not abriendo:
			prompt_label.visible = true

func _on_body_exited(body):
	if body.name == "Player":
		player_in_range = false
		prompt_label.visible = false

func _unhandled_input(event):
	if player_in_range and not abriendo and event.is_action_pressed("interactuar"):
		abrir_puerta()

func abrir_puerta():
	abriendo = true
	prompt_label.visible = false
	sprite.texture = textura_abierta
	await get_tree().create_timer(0.35).timeout
	get_tree().change_scene_to_file("res://scenes/level_select.tscn")
