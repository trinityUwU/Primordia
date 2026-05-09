shader_type canvas_item;

uniform vec4 color : source_color = vec4(0.3, 0.7, 1.0, 1.0);
uniform float time : hint_range(0.0, 1000.0) = 0.0;

// Simple value noise — compatible OpenGL 3.3 Compatibility renderer
float hash(vec2 p) {
	p = fract(p * vec2(127.1, 311.7));
	p += dot(p, p + 19.31);
	return fract(p.x * p.y);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

void fragment() {
	vec2 uv = UV;

	// Pulsation lente ~0.8 Hz
	float pulse = 0.5 + 0.5 * sin(time * 5.027); // 5.027 ≈ 2π × 0.8

	// Noise animé pour l'intérieur
	vec2 noise_uv = uv * 3.5 + vec2(time * 0.08, time * 0.05);
	float n = vnoise(noise_uv);
	n = mix(n, vnoise(noise_uv * 2.1 + 0.3), 0.4);

	// Intérieur très subtil — juste un hint de présence
	float inner_alpha = (0.04 + 0.03 * pulse) * (0.5 + 0.5 * n);

	// Bordure lumineuse nette
	float border_dist = min(min(uv.x, 1.0 - uv.x), min(uv.y, 1.0 - uv.y));
	float border_width = 0.025;
	float border_strength = 1.0 - smoothstep(0.0, border_width, border_dist);
	float border_alpha = border_strength * (0.80 + 0.20 * pulse);

	float final_alpha = max(inner_alpha, border_alpha);
	COLOR = vec4(color.rgb, final_alpha * color.a);
}
