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
	} else if (v_type < 4.5) {
		color = vec4(0.4, 0.35, 0.3, v_alpha * 0.7);
	} else if (v_type < 5.5) {
		color = vec4(0.75, 0.2, 0.9, 0.95);
	} else if (v_type < 6.5) {
		color = vec4(0.3, 0.9, 0.3, 1.0);
	} else {
		color = vec4(0.8, 0.6, 0.1, 0.9);
	}
	COLOR = color;
}
