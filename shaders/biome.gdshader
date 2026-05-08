shader_type canvas_item;

uniform vec4 biome_color : source_color = vec4(0.4, 0.3, 0.2, 1.0);
uniform float noise_scale : hint_range(0.0, 200.0) = 80.0;
uniform float noise_strength : hint_range(0.0, 0.3) = 0.06;

float hash(vec2 p) {
    p = fract(p * vec2(234.34, 435.345));
    p += dot(p, p + 34.23);
    return fract(p.x * p.y);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(
        mix(hash(i), hash(i + vec2(1, 0)), f.x),
        mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x),
        f.y
    );
}

void fragment() {
    vec2 uv = FRAGCOORD.xy / noise_scale;
    float n = noise(uv) * noise_strength;
    vec3 col = biome_color.rgb + vec3(n) - noise_strength * 0.5;
    COLOR = vec4(col, biome_color.a);
}
