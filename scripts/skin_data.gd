class_name SkinData
extends Resource
# Datos de una skin del jugador. Cada skin es un .tres en res://resources/skins/
#
# Las hojas tienen el mismo formato que las del personaje original (player.tscn):
# 4 columnas de 32x32 y se usa la fila 1 (y = 32). Si exportás una skin nueva
# con otro layout, cambiá FILA / FRAME / COLUMNAS acá.

@export var nombre := "Skin"
@export_multiline var descripcion := ""
@export var costo := 0                    # en carpinchos. 0 = gratis

@export_group("Idle")
@export var idle_back: Texture2D
@export var idle_front: Texture2D
@export var idle_left: Texture2D
@export var idle_right: Texture2D

@export_group("Correr")
@export var run_back: Texture2D
@export var run_front: Texture2D
@export var run_left: Texture2D
@export var run_right: Texture2D

const FRAME := Vector2i(32, 32)
const FILA := 1
const COLUMNAS := 4
const VELOCIDAD := 5.0                    # igual que las animaciones de player.tscn


# Arma un SpriteFrames con los mismos nombres de animación que usa player.gd
# ("idle_front", "run_left", etc.), así el jugador solo tiene que cambiarlo.
func construir_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")

	var hojas := {
		&"idle_back": idle_back,
		&"idle_front": idle_front,
		&"idle_left": idle_left,
		&"idle_right": idle_right,
		&"run_back": run_back,
		&"run_front": run_front,
		&"run_left": run_left,
		&"run_right": run_right,
	}
	for anim in hojas:
		var hoja: Texture2D = hojas[anim]
		if hoja == null:
			continue
		frames.add_animation(anim)
		frames.set_animation_speed(anim, VELOCIDAD)
		frames.set_animation_loop(anim, true)
		for i in COLUMNAS:
			var atlas := AtlasTexture.new()
			atlas.atlas = hoja
			atlas.region = Rect2(i * FRAME.x, FILA * FRAME.y, FRAME.x, FRAME.y)
			frames.add_frame(anim, atlas)
	return frames


# Primer cuadro "idle de frente": sirve de ícono en el menú del probador.
func icono() -> Texture2D:
	if idle_front == null:
		return null
	var atlas := AtlasTexture.new()
	atlas.atlas = idle_front
	atlas.region = Rect2(0, FILA * FRAME.y, FRAME.x, FRAME.y)
	return atlas
