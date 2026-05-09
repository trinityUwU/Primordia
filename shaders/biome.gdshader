shader_type canvas_item;

varying flat float v_biome;
varying flat float v_north;
varying flat float v_east;
varying vec2 v_world_pos;

void vertex() {
	v_biome     = INSTANCE_CUSTOM.r;
	v_north     = INSTANCE_CUSTOM.g;
	v_east      = INSTANCE_CUSTOM.b;
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
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

vec3 biome_color(int b) {
	if (b == 0) return vec3(0.08, 0.18, 0.38); // WATER
	if (b == 1) return vec3(0.32, 0.22, 0.14); // EARTH
	if (b == 2) return vec3(0.22, 0.42, 0.18); // GRASS
	if (b == 3) return vec3(0.10, 0.25, 0.10); // WOOD
	return       vec3(0.38, 0.36, 0.34);        // ROCK
}

void fragment() {
	int biome = int(round(v_biome * 4.0));
	int north  = int(round(v_north * 4.0));
	int east   = int(round(v_east  * 4.0));

	vec2 wp = v_world_pos;
	float n1 = noise(wp / 48.0) * 0.06;
	float n2 = noise(wp / 12.0) * 0.03;
	float n3 = noise(wp / 4.0)  * 0.015;
	float nv = n1 + n2 + n3 - 0.05;

	vec3 col = clamp(biome_color(biome) + nv, 0.0, 1.0);

	// Organic displacement along edges
	float disp = noise(wp / 22.0) * 0.09 - 0.045;
	const float BW = 0.15; // blend width in UV space

	// North edge blend (top of this chunk → matches south edge of northern neighbour)
	float t_n = clamp((BW - UV.y + disp) / BW, 0.0, 1.0);
	if (north != biome && t_n > 0.0)
		col = mix(col, clamp(biome_color(north) + nv, 0.0, 1.0), t_n);

	// East edge blend (right side → matches west edge of eastern neighbour)
	float t_e = clamp((UV.x - (1.0 - BW) + disp) / BW, 0.0, 1.0);
	if (east != biome && t_e > 0.0)
		col = mix(col, clamp(biome_color(east) + nv, 0.0, 1.0), t_e);

	COLOR = vec4(col, 1.0);
}
