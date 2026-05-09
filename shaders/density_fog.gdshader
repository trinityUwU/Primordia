shader_type canvas_item;

uniform float lod_alpha : hint_range(0.0, 1.0) = 1.0;

varying flat float v_type;
varying flat float v_density;

void vertex() {
	v_type    = INSTANCE_CUSTOM.r;
	v_density = INSTANCE_CUSTOM.g;
}

void fragment() {
	vec2 uv = UV - vec2(0.5);
	float dist = length(uv) * 2.0;

	vec3 col;
	if (v_type < 0.5) {
		col = vec3(0.4, 0.7, 1.0);
	} else if (v_type < 1.5) {
		col = vec3(1.0, 0.45, 0.2);
	} else if (v_type < 2.5) {
		col = vec3(1.0, 0.25, 0.25);
	} else if (v_type < 3.5) {
		col = vec3(0.75, 0.2, 0.9);
	} else if (v_type < 4.5) {
		col = vec3(0.3, 0.9, 0.3);
	} else {
		col = vec3(0.8, 0.6, 0.1);
	}

	float core  = smoothstep(0.55, 0.0, dist);
	float bloom = smoothstep(1.0, 0.0, dist) * 0.35;
	float alpha = (core + bloom) * v_density * 0.75 * lod_alpha;

	COLOR = vec4(col * (1.0 + core * 0.6), alpha);
}
