shader_type canvas_item;

uniform sampler2D biome_tex;
uniform float chunk_px;
uniform vec2  cam_pos;
uniform float zoom;
uniform vec2  vp_size;
uniform float tex_size;
uniform vec2  tex_origin;

// Per-chunk deterministic jitter — same result regardless of which neighbor computes it
vec2 chunk_jitter(ivec2 c) {
	vec2 cf = vec2(c);
	float h1 = fract(sin(dot(cf, vec2(127.1, 311.7))) * 43758.5453);
	float h2 = fract(sin(dot(cf, vec2(269.5,  183.3))) * 43758.5453);
	return (vec2(h1, h2) - 0.5) * 0.7; // jitter within ~35% of chunk radius
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

vec3 biome_color(float b_norm) {
	int b = int(round(b_norm * 4.0));
	if (b == 0) return vec3(0.08, 0.18, 0.38);
	if (b == 1) return vec3(0.32, 0.22, 0.14);
	if (b == 2) return vec3(0.22, 0.42, 0.18);
	if (b == 3) return vec3(0.10, 0.25, 0.10);
	return       vec3(0.38, 0.36, 0.34);
}

void fragment() {
	vec2 world_pos = cam_pos + (UV - vec2(0.5)) * vp_size / zoom;
	vec2 chunk_f   = world_pos / chunk_px;
	ivec2 base     = ivec2(floor(chunk_f));
	int   ts       = int(tex_size);

	// Voronoi over 3x3 neighborhood — closest jittered center wins
	float min_dist   = 1e9;
	float win_biome  = 0.0;

	for (int dy = -1; dy <= 1; dy++) {
		for (int dx = -1; dx <= 1; dx++) {
			ivec2 nc     = base + ivec2(dx, dy);
			ivec2 tc     = clamp(nc - ivec2(tex_origin), ivec2(0), ivec2(ts - 1));
			float biome  = texelFetch(biome_tex, tc, 0).r;

			// Center of this chunk in chunk-space, plus jitter
			vec2 center  = vec2(nc) + 0.5 + chunk_jitter(nc);
			float d      = distance(chunk_f, center);
			if (d < min_dist) {
				min_dist   = d;
				win_biome  = biome;
			}
		}
	}

	float n1 = noise(world_pos / 48.0) * 0.06;
	float n2 = noise(world_pos / 12.0) * 0.03;
	float n3 = noise(world_pos / 4.0)  * 0.015;
	float nv = n1 + n2 + n3 - 0.05;

	COLOR = vec4(clamp(biome_color(win_biome) + nv, 0.0, 1.0), 1.0);
}
