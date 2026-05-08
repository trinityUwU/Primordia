shader_type canvas_item;

varying flat float v_value;
varying flat float v_mode;

void vertex() {
    v_value = INSTANCE_CUSTOM.r;
    v_mode  = INSTANCE_CUSTOM.g;
}

void fragment() {
    float t = clamp(v_value, 0.0, 1.0);
    vec3 col;
    int mode = int(v_mode + 0.5);
    if (mode == 1) {
        // nutrients: black → green → yellow
        col = mix(mix(vec3(0.0), vec3(0.2, 0.8, 0.2), t * 2.0),
                  mix(vec3(0.2, 0.8, 0.2), vec3(1.0, 1.0, 0.0), (t - 0.5) * 2.0),
                  step(0.5, t));
    } else if (mode == 2) {
        // toxins: transparent → red
        col = vec3(1.0, 0.1, 0.1) * t;
    } else {
        // temperature: blue (cold) → red (hot), normalized 0-40°C
        col = mix(vec3(0.1, 0.2, 0.9), vec3(0.9, 0.2, 0.1), t);
    }
    COLOR = vec4(col, 0.55);
}
