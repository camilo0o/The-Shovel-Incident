class_name ArmaData
extends Resource
# datos de un arma. Cada arma es un archivo .tres en res://resources/armas/
enum Tipo { CUERPO_A_CUERPO, DISTANCIA }

@export var nombre := "Arma"
@export var tipo := Tipo.CUERPO_A_CUERPO
@export var icono: Texture2D              # se usa en el puesto y en la mano del jugador
@export_multiline var descripcion := ""

@export_group("Combate")
@export var dano := 1
@export var cooldown := 0.4               # segundos entre usos

@export_group("Cuerpo a cuerpo")
@export var alcance := 22.0               # distancia del golpe desde el jugador
@export var tamano_golpe := Vector2(26, 26)

@export_group("Distancia")
@export var bala_textura: Texture2D       # sprite del proyectil (vacío = círculo)
@export var velocidad_bala := 260.0
@export var vida_util_bala := 1.2         # segundos antes de desaparecer (define el alcance)
@export var consume_municion := true      # descuenta de player.municion
@export var automatica := false          # true = mantener apretado dispara en ráfaga
@export var distancia_boca := 12.0        # a que distancia del jugador aparece la bala
