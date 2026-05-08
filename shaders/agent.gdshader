shader_type canvas_item;

void fragment() {
	vec4 custom = INSTANCE_CUSTOM;
	float type = custom.r;
	vec4 color;
	if (type < 0.5) {
		color = vec4(0.4, 0.7, 1.0, 0.9);
	} else if (type < 1.5) {
		color = vec4(1.0, 0.45, 0.2, 0.9);
	} else if (type < 2.5) {
		color = vec4(0.55, 0.55, 0.55, 0.85);
	} else if (type < 3.5) {
		color = vec4(1.0, 0.25, 0.25, 0.65);
	} else {
		color = vec4(0.4, 0.35, 0.3, custom.g);
	}
	COLOR = color * COLOR;
}
