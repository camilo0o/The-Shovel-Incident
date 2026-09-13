extends PointLight2D

@export var energia_base: float = 1.5
@export var variacion: float = 0.35
@export var velocidad: float = 8.0

var tiempo := 0.0

func _process(delta):
	tiempo += delta * velocidad
	# Combina dos senos con distinta frecuencia para que no se vea repetitivo
	var ruido = sin(tiempo) * 0.6 + sin(tiempo * 2.7) * 0.4
	energy = energia_base + ruido * variacion
