extends Node

const RUTA := "user://ajustes.cfg"
const BUSES_EXTRA: Array[String] = ["Musica", "Efectos"]
const VOLUMEN_POR_DEFECTO := 1.0

# Volumen lineal (0.0 a 1.0) por bus.
var volumen := {"Master": VOLUMEN_POR_DEFECTO, "Musica": VOLUMEN_POR_DEFECTO, "Efectos": VOLUMEN_POR_DEFECTO}
var silenciar := false
var pantalla_completa := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_crear_buses()
	cargar()
	aplicar_todo()
	# Cualquier reproductor de audio que entre al árbol se manda al bus que corresponde.
	get_tree().node_added.connect(_asignar_bus)
	_asignar_bus_recursivo(get_tree().root)


func set_volumen(bus: String, valor: float) -> void:
	volumen[bus] = clampf(valor, 0.0, 1.0)
	_aplicar_volumen(bus)


func set_silenciar(valor: bool) -> void:
	silenciar = valor
	AudioServer.set_bus_mute(0, silenciar)


func set_pantalla_completa(valor: bool) -> void:
	pantalla_completa = valor
	var modo := DisplayServer.WINDOW_MODE_FULLSCREEN if valor else DisplayServer.WINDOW_MODE_WINDOWED
	DisplayServer.window_set_mode(modo)


func restablecer() -> void:
	for bus in volumen.keys():
		volumen[bus] = VOLUMEN_POR_DEFECTO
	silenciar = false
	pantalla_completa = false
	aplicar_todo()
	guardar()


func aplicar_todo() -> void:
	for bus in volumen.keys():
		_aplicar_volumen(bus)
	set_silenciar(silenciar)
	set_pantalla_completa(pantalla_completa)


func guardar() -> void:
	var cfg := ConfigFile.new()
	for bus in volumen.keys():
		cfg.set_value("audio", bus, volumen[bus])
	cfg.set_value("audio", "silenciar", silenciar)
	cfg.set_value("pantalla", "completa", pantalla_completa)
	cfg.save(RUTA)


func cargar() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(RUTA) != OK:
		return
	for bus in volumen.keys():
		volumen[bus] = clampf(float(cfg.get_value("audio", bus, VOLUMEN_POR_DEFECTO)), 0.0, 1.0)
	silenciar = bool(cfg.get_value("audio", "silenciar", false))
	pantalla_completa = bool(cfg.get_value("pantalla", "completa", false))

func _crear_buses() -> void:
	for nombre in BUSES_EXTRA:
		if AudioServer.get_bus_index(nombre) != -1:
			continue
		AudioServer.add_bus()
		var idx := AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx, nombre)
		AudioServer.set_bus_send(idx, "Master")


func _aplicar_volumen(bus: String) -> void:
	var idx := AudioServer.get_bus_index(bus)
	if idx == -1:
		return
	# linear_to_db(0) da -inf, así que se pone un piso muy bajo.
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(volumen[bus], 0.0001)))
	AudioServer.set_bus_mute(idx, volumen[bus] <= 0.0)


func _asignar_bus(nodo: Node) -> void:
	if not (nodo is AudioStreamPlayer or nodo is AudioStreamPlayer2D or nodo is AudioStreamPlayer3D):
		return
	if nodo.bus != &"Master":
		return   # ya tiene un bus asignado a mano: se respeta
	var ruta: String = nodo.stream.resource_path if nodo.stream != null else ""
	nodo.bus = &"Musica" if "/music/" in ruta else &"Efectos"


func _asignar_bus_recursivo(nodo: Node) -> void:
	_asignar_bus(nodo)
	for hijo in nodo.get_children():
		_asignar_bus_recursivo(hijo)
