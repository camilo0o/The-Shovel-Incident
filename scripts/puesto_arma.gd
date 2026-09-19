extends Area2D
# Puesto de la armería: acercate y apretá E para equipar el arma.
# Solo se puede tener un arma equipada; elegir otra reemplaza la anterior.

@export var arma: ArmaData

@onready var icono: Sprite2D = $Icono
@onready var etiqueta: Label = $Etiqueta

var _jugador_cerca := false


func _ready() -> void:
	etiqueta.visible = false
	if arma == null:
		push_warning("PuestoArma '%s': falta asignar el arma (propiedad Arma)." % name)
		return

	icono.texture = arma.icono
	if arma.icono != null and arma.icono.get_height() > 20:
		icono.rotation_degrees = 90.0    # armas largas: se apoyan acostadas sobre la mesa
		icono.position.y = -20.0
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	GameProgress.arma_cambiada.connect(func(_a): _actualizar())
	_actualizar()
	_flotar()


func _unhandled_input(event: InputEvent) -> void:
	if arma != null and _jugador_cerca and event.is_action_pressed("interactuar"):
		GameProgress.equipar_arma(arma)
		get_viewport().set_input_as_handled()


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("jugador"):
		_jugador_cerca = true
		etiqueta.visible = true

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("jugador"):
		_jugador_cerca = false
		etiqueta.visible = false


func _actualizar() -> void:
	var equipada := GameProgress.arma_equipada == arma
	icono.modulate = Color.WHITE if equipada else Color(0.72, 0.72, 0.72)
	etiqueta.text = "%s\n%s" % [arma.nombre, "¡Equipada!" if equipada else "[E] Equipar"]


# El arma sube y baja apenas, para que se note que se puede agarrar
func _flotar() -> void:
	var y0 := icono.position.y
	var tween := create_tween().set_loops()
	tween.tween_property(icono, "position:y", y0 - 1.5, 0.8).set_trans(Tween.TRANS_SINE)
	tween.tween_property(icono, "position:y", y0, 0.8).set_trans(Tween.TRANS_SINE)
