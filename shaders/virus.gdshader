shader_type canvas_item;

// Pass-through — rendering handled by AgentRenderer._draw()
// Reserved for future GPU-accelerated virus glow/pulse effects.

void fragment() {
	COLOR = texture(TEXTURE, UV);
}
