shader_type canvas_item;

void fragment() {
    vec2 uv = FRAGCOORD.xy;

    // Value noise
    vec2 p1 = floor(uv / 40.0);
    vec2 f1 = fract(uv / 40.0);
    f1 = f1 * f1 * (3.0 - 2.0 * f1);
    vec2 h1 = fract(p1 * vec2(127.1, 311.7) + vec2(p1.y * 74.3, p1.x * 91.7));
    vec2 h2 = fract((p1 + vec2(1,0)) * vec2(127.1, 311.7) + vec2((p1.y) * 74.3, (p1.x+1.0) * 91.7));
    vec2 h3 = fract((p1 + vec2(0,1)) * vec2(127.1, 311.7) + vec2((p1.y+1.0) * 74.3, p1.x * 91.7));
    vec2 h4 = fract((p1 + vec2(1,1)) * vec2(127.1, 311.7) + vec2((p1.y+1.0) * 74.3, (p1.x+1.0) * 91.7));
    float n1 = mix(mix(fract(h1.x * h1.y * 43758.5), fract(h2.x * h2.y * 43758.5), f1.x),
                   mix(fract(h3.x * h3.y * 43758.5), fract(h4.x * h4.y * 43758.5), f1.x), f1.y);

    // Fine grain
    vec2 p2 = floor(uv / 8.0);
    float n2 = fract(sin(dot(p2, vec2(127.1, 311.7))) * 43758.5);

    float noise = n1 * 0.07 + n2 * 0.025;

    vec4 base = COLOR;
    vec3 col = base.rgb + noise - 0.04;
    COLOR = vec4(clamp(col, 0.0, 1.0), base.a);
}
