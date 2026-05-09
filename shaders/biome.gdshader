shader_type canvas_item;

varying flat float v_biome;
varying flat float v_north;
varying flat float v_east;
varying flat float v_south_west;
varying vec2 v_world_pos;

void vertex() {
	v_biome      = INSTANCE_CUSTOM.r;
	v_north      = INSTANCE_CUSTOM.g;
	v_east       = INSTANCE_CUSTOM.b;
	v_south_west = INSTANCE_CUSTOM.a;
	v_world_pos  = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

float hash(vec2 p) {
	p = fract(p * vec2(127.1, 311.7));
	p += dot(p, p + 34.23);
	return fract(p.x * p.y);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x),
		f.y
	);
}

vec3 biome_base(int b) {
	if (b == 0) return vec3(0.08, 0.18, 0.38);
	if (b == 1) return vec3(0.32, 0.22, 0.14);
	if (b == 2) return vec3(0.22, 0.42, 0.18);
	if (b == 3) return vec3(0.10, 0.25, 0.10);
	return vec3(0.38, 0.36, 0.34);
}

void fragment() {
	// Decode normalized values (encoded as val/4 and south*5+west/24)
	int biome = int(round(v_biome * 4.0));
	int north  = int(round(v_north * 4.0));
	int east   = int(round(v_east  * 4.0));
	float sw   = v_south_west * 24.0;
	int south  = int(sw / 5.0);
	int west   = int(mod(sw, 5.0));

	vec2 wp = v_world_pos;

	// Noise for variation
	float n1 = noise(wp / 48.0) * 0.06;
	float n2 = noise(wp / 12.0) * 0.03;
	float n3 = noise(wp / 4.0)  * 0.015;
	float noise_offset = n1 + n2 + n3 - 0.05;

	vec3 col = clamp(biome_base(biome) + noise_offset, 0.0, 1.0);

	// Organic noise displacement on edge
	float edge_n = noise(wp / 28.0) * 0.08 - 0.04;
	const float BLEND = 0.14;

	float t_north = clamp((BLEND - UV.y + edge_n) / BLEND, 0.0, 1.0);
	float t_south = clamp((UV.y - (1.0 - BLEND) + edge_n) / BLEND, 0.0, 1.0);
	float t_west  = clamp((BLEND - UV.x + edge_n) / BLEND, 0.0, 1.0);
	float t_east  = clamp((UV.x - (1.0 - BLEND) + edge_n) / BLEND, 0.0, 1.0);

	if (north != biome && t_north > 0.0)
		col = mix(col, clamp(biome_base(north) + noise_offset, 0.0, 1.0), t_north);
	if (south != biome && t_south > 0.0)
		col = mix(col, clamp(biome_base(south) + noise_offset, 0.0, 1.0), t_south);
	if (west != biome && t_west > 0.0)
		col = mix(col, clamp(biome_base(west) + noise_offset, 0.0, 1.0), t_west);
	if (east != biome && t_east > 0.0)
		col = mix(col, clamp(biome_base(east) + noise_offset, 0.0, 1.0), t_east);

	COLOR = vec4(col, 1.0);
}
