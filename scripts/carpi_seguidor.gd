extends Node2D
# Carpi sigue al jugador y se ve como un espiritu
@export_group("Seguimiento")
@export var velocidad := 80.0

@export var distancia_seguir := 28.0
@export var distancia_parar := 18.0

@export_group("Espíritu")
@export_range(0.0, 1.0) var opacidad := 0.45
@export var variacion_opacidad := 0.10  
@export var tinte := Color(0.75, 0.9, 1.0)
@export var amplitud_flote := 2.0
 
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
 
var _jugador: Node2D
var _siguiendo := false
var _t := 0.0
 
func _process(delta: float) -> void:
	_t += delta
	_efecto_espiritu()
	
	if _jugador == null or not is_instance_valid(_jugador):
		_jugador = get_tree().get_first_node_in_group("jugador") as Node2D
		if _jugador == null:
			return
	
	var al_jugador := _jugador.global_position - global_position
	var distancia := al_jugador.length()
	
	if distancia > distancia_seguir:
		_siguiendo = true
	elif distancia < distancia_parar:
		_siguiendo = false
		
	if _siguiendo:
		global_position += al_jugador.normalized() * velocidad * delta
		_animar(al_jugador)
	else:
		sprite.stop()
		sprite.frame = 0
		
func _animar(dir: Vector2) -> void:
	var anim: StringName
	if abs(dir.x) > abs(dir.y):
		anim = &"derecha" if dir.x > 0 else &"izquierda"
	else:
		anim = &"abajo" if dir.y > 0 else &"arriba"
	if sprite.animation != anim or not sprite.is_playing():
		sprite.play(anim)
		

func _efecto_espiritu() -> void:
	var alfa := opacidad + sin(_t * 2.0) * variacion_opacidad
	sprite.modulate = Color(tinte.r, tinte.g, tinte.b, alfa)
	sprite.position.y = sin(_t * 3.0) * amplitud_flote
