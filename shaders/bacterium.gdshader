shader_type canvas_item;

// Pass-through — rendering handled by AgentRenderer._draw()
// Reserved for future GPU-accelerated bacterium effects.

void fragment() {
	COLOR = texture(TEXTURE, UV);
}
