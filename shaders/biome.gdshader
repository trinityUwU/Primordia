shader_type canvas_item;

uniform sampler2D biome_tex;
uniform float chunk_px;
uniform vec2  cam_pos;
uniform float zoom;
uniform vec2  vp_size;
uniform float tex_size;
uniform vec2  tex_origin;
uniform float time;

// ── Hashing / noise ──────────────────────────────────────────────────────────

vec2 chunk_jitter(ivec2 c) {
	vec2 cf = vec2(c);
	float h1 = fract(sin(dot(cf, vec2(127.1, 311.7))) * 43758.5453);
	float h2 = fract(sin(dot(cf, vec2(269.5,  183.3))) * 43758.5453);
	return (vec2(h1, h2) - 0.5) * 0.65;
}

float hash(vec2 p) {
	p = fract(p * vec2(127.1, 311.7));
	p += dot(p, p + 34.23);
	return fract(p.x * p.y);
}

float hash3(vec3 p) {
	p = fract(p * vec3(127.1, 311.7, 74.7));
	p += dot(p, p + 34.23);
	return fract(p.x * p.y * p.z);
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

// Smooth fbm — 3 octaves
float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	vec2  shift = vec2(100.0);
	for (int i = 0; i < 3; i++) {
		v += a * noise(p);
		p = p * 2.1 + shift;
		a *= 0.5;
	}
	return v;
}

// ── Biome palettes ───────────────────────────────────────────────────────────
// Each biome: base color + detail texture + secondary tint

// WATER (0) — deep teal, caustic shimmer
vec3 biome_water(vec2 wp) {
	float depth = fbm(wp / 180.0) * 0.5 + 0.5;
	vec3 shallow = vec3(0.10, 0.30, 0.50);
	vec3 deep    = vec3(0.04, 0.12, 0.28);
	vec3 base    = mix(deep, shallow, depth * 0.7);
	// Animated caustics
	float t = time * 0.3;
	float c1 = noise(wp / 22.0 + vec2(t, t * 0.7)) * 0.5 + 0.5;
	float c2 = noise(wp / 14.0 - vec2(t * 0.5, t)) * 0.5 + 0.5;
	float caustic = pow(c1 * c2, 2.5) * 0.18;
	// Surface shimmer
	float shimmer = noise(wp / 6.0 + vec2(time * 1.2, time * 0.8)) * 0.04;
	return base + vec3(caustic + shimmer) * vec3(0.6, 0.85, 1.0);
}

// EARTH (1) — sandy loam, dry cracks
vec3 biome_earth(vec2 wp) {
	float grain = fbm(wp / 24.0);
	float coarse = noise(wp / 80.0);
	vec3 light  = vec3(0.58, 0.46, 0.30);
	vec3 dark   = vec3(0.34, 0.26, 0.16);
	vec3 base   = mix(dark, light, grain * 0.7 + coarse * 0.3);
	// Subtle crack pattern
	float crack = 1.0 - abs(noise(wp / 40.0) - 0.5) * 2.0;
	crack = pow(max(crack - 0.82, 0.0) / 0.18, 2.0) * 0.12;
	return base - vec3(crack);
}

// GRASS (2) — rich green, blade variation
vec3 biome_grass(vec2 wp) {
	float blade = fbm(wp / 16.0);
	float patch = noise(wp / 90.0);
	vec3 bright = vec3(0.28, 0.52, 0.18);
	vec3 shadow = vec3(0.14, 0.32, 0.10);
	vec3 dry    = vec3(0.40, 0.46, 0.18);
	vec3 base   = mix(shadow, bright, blade);
	base = mix(base, dry, patch * 0.18);
	// Fine detail — individual blade suggestion
	float fine = noise(wp / 5.0) * 0.06 - 0.03;
	return base + vec3(fine * 0.4, fine, fine * 0.2);
}

// WOOD (3) — forest floor, dappled light, leaf litter
vec3 biome_wood(vec2 wp) {
	float canopy  = fbm(wp / 60.0);
	float litter  = fbm(wp / 18.0 + vec2(42.0));
	vec3 floor_c  = vec3(0.18, 0.28, 0.10);  // deep forest
	vec3 dapple   = vec3(0.28, 0.42, 0.16);  // light patch
	vec3 leaf     = vec3(0.30, 0.24, 0.10);  // dead leaves
	vec3 base     = mix(floor_c, dapple, canopy * 0.6);
	base          = mix(base, leaf, litter * 0.22);
	// Animated light dapple through canopy
	float light_t = time * 0.08;
	float dap = noise(wp / 35.0 + vec2(light_t)) * noise(wp / 18.0 - vec2(light_t * 0.7));
	dap = pow(dap, 1.8) * 0.16;
	return base + dap * vec3(0.35, 0.45, 0.15);
}

// ROCK (4) — grey granite, mineral veins
vec3 biome_rock(vec2 wp) {
	float grain  = fbm(wp / 30.0);
	float vein   = fbm(wp / 12.0 + vec2(77.0));
	vec3 granite = vec3(0.48, 0.46, 0.44);
	vec3 dark_m  = vec3(0.28, 0.27, 0.26);
	vec3 quartz  = vec3(0.62, 0.60, 0.58);
	vec3 base    = mix(dark_m, granite, grain);
	// Mineral veins
	float v = pow(abs(vein - 0.5) * 2.0, 3.0);
	base = mix(base, quartz, v * 0.25);
	// Fine surface crack
	float crack = noise(wp / 8.0) * noise(wp / 20.0);
	crack = pow(max(crack - 0.6, 0.0) / 0.4, 2.0) * 0.1;
	return base - vec3(crack);
}

// ── Biome transition blend ───────────────────────────────────────────────────

vec3 get_biome_color(int b, vec2 wp) {
	if (b == 0) return biome_water(wp);
	if (b == 1) return biome_earth(wp);
	if (b == 2) return biome_grass(wp);
	if (b == 3) return biome_wood(wp);
	return biome_rock(wp);
}

// ── Main fragment ────────────────────────────────────────────────────────────

void fragment() {
	vec2 world_pos = cam_pos + (UV - vec2(0.5)) * vp_size / zoom;
	vec2 chunk_f   = world_pos / chunk_px;
	ivec2 base     = ivec2(floor(chunk_f));
	int   ts       = int(tex_size);

	// Voronoi — find 2 closest jittered chunk centers for blend
	float d1 = 1e9, d2 = 1e9;
	int   b1 = 2,   b2 = 2;
	vec2  c1_pos = vec2(0.0);

	for (int dy = -1; dy <= 1; dy++) {
		for (int dx = -1; dx <= 1; dx++) {
			ivec2 nc    = base + ivec2(dx, dy);
			ivec2 tc    = clamp(nc - ivec2(tex_origin), ivec2(0), ivec2(ts - 1));
			float b_raw = texelFetch(biome_tex, tc, 0).r;
			int   btype = int(round(b_raw * 4.0));
			vec2 center = vec2(nc) + 0.5 + chunk_jitter(nc);
			float d     = distance(chunk_f, center);
			if (d < d1) {
				d2 = d1; b2 = b1;
				d1 = d;  b1 = btype; c1_pos = center;
			} else if (d < d2) {
				d2 = d; b2 = btype;
			}
		}
	}

	// Blend zone width — transition over ~15% of chunk radius
	float edge_dist = d2 - d1;
	float blend = smoothstep(0.0, 0.15, edge_dist);

	vec3 col_a = get_biome_color(b1, world_pos);
	vec3 col_b = get_biome_color(b2, world_pos);
	vec3 final_color = mix(col_b, col_a, blend);

	// Global micro-vignette at viewport edges (subtle)
	vec2 uv_centered = (UV - 0.5) * 2.0;
	float vign = 1.0 - dot(uv_centered, uv_centered) * 0.04;
	final_color *= vign;

	COLOR = vec4(clamp(final_color, 0.0, 1.0), 1.0);
}
