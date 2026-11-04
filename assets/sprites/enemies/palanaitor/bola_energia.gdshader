shader_type canvas_item;
render_mode unshaded;

// El PNG original es opaco y contiene una cuadricula gris dibujada.
// Conservamos el azul y el nucleo luminoso, haciendo transparente ese fondo.
void fragment() {
	vec4 pixel = texture(TEXTURE, UV);
	float azul = smoothstep(0.06, 0.20, pixel.b - pixel.r);
	float brillo = max(pixel.r, max(pixel.g, pixel.b));
	float nucleo = smoothstep(0.24, 0.55, brillo);
	COLOR.a *= max(azul, nucleo);
}
