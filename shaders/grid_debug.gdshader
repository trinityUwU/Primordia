shader_type canvas_item;

uniform float cell_size : hint_range(1.0, 64.0) = 8.0;
uniform vec4 grid_color : source_color = vec4(1.0, 1.0, 1.0, 0.1);

void fragment() {
	vec2 world_uv = UV * vec2(
		float(textureSize(TEXTURE, 0).x),
		float(textureSize(TEXTURE, 0).y)
	);

	// Use screen pixel coordinates relative to the shader rect
	vec2 pixel = FRAGCOORD.xy;
	vec2 cell_coord = mod(pixel, cell_size);

	float line_width = 1.0;
	bool on_line = cell_coord.x < line_width || cell_coord.y < line_width;

	if (on_line) {
		COLOR = grid_color;
	} else {
		COLOR = vec4(0.0, 0.0, 0.0, 0.0);
	}
}
