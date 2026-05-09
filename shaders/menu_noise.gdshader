shader_type canvas_item;

uniform float intensity : hint_range(0.0, 1.0) = 0.025;
uniform float scale : hint_range(1.0, 64.0) = 32.0;

float hash(vec2 p) {
	p = fract(p * vec2(127.1, 311.7));
	p += dot(p, p + 19.19);
	return fract(p.x * p.y);
}

void fragment() {
	vec2 uv = UV * scale;
	float n = hash(floor(uv));
	COLOR = vec4(vec3(n * intensity), 0.0);
}
