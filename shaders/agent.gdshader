shader_type canvas_item;

varying flat float v_type;
varying flat float v_alpha;

void vertex() {
	v_type = INSTANCE_CUSTOM.r;
	v_alpha = INSTANCE_CUSTOM.g;
}

void fragment() {
	vec4 color;
	if (v_type < 0.5) {
		color = vec4(0.4, 0.7, 1.0, 0.9);
	} else if (v_type < 1.5) {
		color = vec4(1.0, 0.45, 0.2, 0.9);
	} else if (v_type < 2.5) {
		color = vec4(0.55, 0.55, 0.55, 0.85);
	} else if (v_type < 3.5) {
		color = vec4(1.0, 0.25, 0.25, 0.65);
	} else {
		color = vec4(0.4, 0.35, 0.3, v_alpha * 0.7);
	}
	COLOR = color;
}
