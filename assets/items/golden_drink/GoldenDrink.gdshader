shader_type canvas_item;

// Kolor aury (Domyślnie złoty)
uniform vec4 aura_color : source_color = vec4(1.0, 0.85, 0.3, 1.0);
// Prędkość pulsowania
uniform float speed : hint_range(0.1, 10.0) = 3.0;
// Ilość pierścieni (fal)
uniform float frequency : hint_range(1.0, 20.0) = 8.0;
// Moc efektu (przezroczystość)
uniform float intensity : hint_range(0.0, 1.0) = 0.8;

void fragment() {
	// 1. Ustawiamy punkt (0,0) na środku prostokąta (UV domyślnie jest 0..1)
	vec2 centered_uv = UV - vec2(0.5);

	// 2. Obliczamy odległość od środka
	float dist = length(centered_uv);

	// 3. Tworzymy falę idącą od środka na zewnątrz
	// Wzór: sin(czas - odległość) daje ruch "do przodu" (na zewnątrz)
	float wave = sin(TIME * speed - dist * frequency);

	// Normalizujemy falę z (-1 do 1) na (0 do 1)
	wave = 0.5 + 0.5 * wave;

	// 4. Maska kołowa (Circular Mask)
	// Dzięki temu aura jest kołem, a nie kwadratem, i zanika na brzegach
	// smoothstep(promień_zewnętrzny, promień_wewnętrzny, odległość)
	float mask = smoothstep(0.5, 0.0, dist);

	// 5. Obliczamy ostateczny kolor
	vec4 final_color = aura_color;

	// Alpha to kombinacja: maski (kształt), fali (ruch) i intensywności
	final_color.a = mask * wave * intensity;

	// Przypisujemy kolor
	COLOR = final_color;
}