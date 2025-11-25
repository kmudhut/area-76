shader_type canvas_item;

// Parametry
uniform float speed : hint_range(0.1, 10.0) = 2.0;
uniform float intensity : hint_range(0.0, 1.0) = 0.8;
uniform float blur : hint_range(0.0, 0.5) = 0.1;

// Funkcja pomocnicza HSV -> RGB
vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void fragment() {
	// 1. Centrujemy UV (0,0 na środku)
	vec2 centered_uv = UV - vec2(0.5);
	
	// 2. Obliczamy kąt i odległość
	float angle = atan(centered_uv.y, centered_uv.x);
	float dist = length(centered_uv);
	
	// --- TRYB TĘCZY (LLM) ---
	// Kolor zależy od kąta + czasu (obrót)
	float hue = (angle / (2.0 * 3.14159)) + (TIME * speed * 0.1);
	hue = fract(hue);
	vec3 final_color_rgb = hsv2rgb(vec3(hue, 1.0, 1.0));
	
	// 3. Maska Pierścienia (Ring Mask) - miękkie krawędzie
	// Wewnętrzna dziura (żeby nie zasłaniać itemu)
	float inner = smoothstep(0.3, 0.3 + blur, dist);
	// Zewnętrzna krawędź (żeby nie było kwadratu)
	float outer = 1.0 - smoothstep(0.5 - blur, 0.5, dist);
	
	float alpha = inner * outer * intensity;
	
	COLOR = vec4(final_color_rgb, alpha);
}