shader_type canvas_item;

uniform sampler2D biome_tex : filter_nearest, repeat_edge;
uniform float chunk_px;
uniform vec2  cam_pos;
uniform float zoom;
uniform vec2  vp_size;
uniform float tex_size;
uniform vec2  tex_origin;

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

vec3 biome_color(float b_norm) {
	int b = int(round(b_norm * 4.0));
	if (b == 0) return vec3(0.08, 0.18, 0.38);
	if (b == 1) return vec3(0.32, 0.22, 0.14);
	if (b == 2) return vec3(0.22, 0.42, 0.18);
	if (b == 3) return vec3(0.10, 0.25, 0.10);
	return       vec3(0.38, 0.36, 0.34);
}

void fragment() {
	// UV = 0..1 over the full ColorRect = full screen
	vec2 world_pos = cam_pos + (UV - vec2(0.5)) * vp_size / zoom;

	// Continuous chunk position
	vec2 chunk_f = world_pos / chunk_px;

	// Pixel in the biome texture
	vec2 tex_uv = (chunk_f - tex_origin) / tex_size;

	// Local position within the chunk [0,1)
	// Use floor to avoid negative-coord artifacts
	vec2 local = chunk_f - floor(chunk_f);

	vec2 step_uv = vec2(1.0 / tex_size);
	float b_self  = texture(biome_tex, tex_uv).r;
	float b_north = texture(biome_tex, tex_uv + vec2(0.0,        -step_uv.y)).r;
	float b_south = texture(biome_tex, tex_uv + vec2(0.0,         step_uv.y)).r;
	float b_west  = texture(biome_tex, tex_uv + vec2(-step_uv.x,  0.0      )).r;
	float b_east  = texture(biome_tex, tex_uv + vec2( step_uv.x,  0.0      )).r;

	float n1 = noise(world_pos / 48.0) * 0.06;
	float n2 = noise(world_pos / 12.0) * 0.03;
	float n3 = noise(world_pos / 4.0)  * 0.015;
	float nv = n1 + n2 + n3 - 0.05;

	float disp = noise(world_pos / 22.0) * 0.09 - 0.045;
	const float BW = 0.15;

	vec3 col = clamp(biome_color(b_self) + nv, 0.0, 1.0);

	float t_n = clamp((BW - local.y  + disp) / BW, 0.0, 1.0);
	float t_s = clamp((local.y  - (1.0 - BW) + disp) / BW, 0.0, 1.0);
	float t_w = clamp((BW - local.x  + disp) / BW, 0.0, 1.0);
	float t_e = clamp((local.x  - (1.0 - BW) + disp) / BW, 0.0, 1.0);

	if (abs(b_north - b_self) > 0.01 && t_n > 0.0)
		col = mix(col, clamp(biome_color(b_north) + nv, 0.0, 1.0), t_n);
	if (abs(b_south - b_self) > 0.01 && t_s > 0.0)
		col = mix(col, clamp(biome_color(b_south) + nv, 0.0, 1.0), t_s);
	if (abs(b_west  - b_self) > 0.01 && t_w > 0.0)
		col = mix(col, clamp(biome_color(b_west)  + nv, 0.0, 1.0), t_w);
	if (abs(b_east  - b_self) > 0.01 && t_e > 0.0)
		col = mix(col, clamp(biome_color(b_east)  + nv, 0.0, 1.0), t_e);

	COLOR = vec4(col, 1.0);
}
