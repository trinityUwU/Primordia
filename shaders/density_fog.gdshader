shader_type canvas_item;

varying flat float v_type;
varying flat float v_density;  // 0-1 normalized count

void vertex() {
	v_type    = INSTANCE_CUSTOM.r;
	v_density = INSTANCE_CUSTOM.g;
}

void fragment() {
	// Distance from center for radial falloff
	vec2 uv = UV - vec2(0.5);
	float dist = length(uv) * 2.0;
	float radial = 1.0 - smoothstep(0.0, 1.0, dist);

	// Color per dominant type
	vec3 col;
	if (v_type < 0.5) {
		col = vec3(0.4, 0.7, 1.0);   // bacteria gram+
	} else if (v_type < 1.5) {
		col = vec3(1.0, 0.45, 0.2);  // bacteria gram-
	} else if (v_type < 2.5) {
		col = vec3(1.0, 0.25, 0.25); // virus
	} else if (v_type < 3.5) {
		col = vec3(0.75, 0.2, 0.9);  // protozoa
	} else if (v_type < 4.5) {
		col = vec3(0.3, 0.9, 0.3);   // plant
	} else {
		col = vec3(0.8, 0.6, 0.1);   // fungi
	}

	// Bloom: bright core, soft outer glow
	float core   = smoothstep(0.55, 0.0, dist);
	float bloom  = smoothstep(1.0, 0.0, dist) * 0.35;
	float alpha  = (core + bloom) * v_density * 0.75;

	COLOR = vec4(col * (1.0 + core * 0.6), alpha);
}
