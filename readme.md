# The Shovel Incident
The Shovel Incident es un videojuego de acción y disparos en 2D, creado en el motor de videojuegos de godot para la asignatura de Introducción al Desarrollo de Juegos de sexto semestre del Tecnólogo en Informática

## Cómo se juega
- Movete por el mapa, esquivá o enfrentá a los enemigos ("Palin") que te persiguen apenas te detectan, y avanzá hasta el portal que te lleva a la sala del jefe.
- Siempre podés pelear a piñazos, sin importar el arma que lleves equipada.
- En la armería del garage podés elegir un arma adicional (cuerpo a cuerpo o a distancia) para complementar tus puños. Las armas a distancia gastan munición.
- Cuidado con la vida: si llega a cero, el nivel se reinicia mostrandote un cartel de "Se acabó el juego, tu pierdes...".

## Controles
 
| Acción | Tecla / Mouse |
|---|---|
| Moverse | `WASD` o flechas |
| Piñazo (siempre disponible) | Clic izquierdo / `J` |
| Atacar con el arma equipada | Clic derecho / `K` |
| Interactuar (puertas, puestos de armas) | `E` |
| Pausar | `Esc` |
 
## Armas disponibles
 
- **Puños** — siempre disponibles, alcance corto.
- **Bate de béisbol** — cuerpo a cuerpo, buen alcance y daño.
- **Pistola de clavos** — a distancia, gasta munición.
- **AK-47** — a distancia, ráfagas rápidas, gasta munición.
## Progreso
 
El juego tiene 3 niveles. Completar un nivel desbloquea el siguiente. El progreso y el arma equipada se guardan durante la partida en curso (autoload `GameProgress`).
