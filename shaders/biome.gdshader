shader_type canvas_item;

varying flat float v_biome;
varying vec2 v_world_pos;

void vertex() {
    v_biome = INSTANCE_CUSTOM.r;
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

void fragment() {
    // Base color per biome
    vec3 col;
    int biome = int(v_biome + 0.5);
    if (biome == 0)      col = vec3(0.08, 0.18, 0.38); // WATER
    else if (biome == 1) col = vec3(0.32, 0.22, 0.14); // EARTH
    else if (biome == 2) col = vec3(0.22, 0.42, 0.18); // GRASS
    else if (biome == 3) col = vec3(0.10, 0.25, 0.10); // WOOD
    else                 col = vec3(0.38, 0.36, 0.34); // ROCK

    // World-space layered noise (anchored to world, not screen)
    vec2 wp = v_world_pos;
    float n1 = noise(wp / 48.0) * 0.06;
    float n2 = noise(wp / 12.0) * 0.03;
    float n3 = noise(wp / 4.0)  * 0.015;

    col = clamp(col + n1 + n2 + n3 - 0.05, 0.0, 1.0);
    COLOR = vec4(col, 1.0);
}
