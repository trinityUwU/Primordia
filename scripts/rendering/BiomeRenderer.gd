extends Node2D

const BIOME_COLORS: Array[Color] = [
	Color(0.08, 0.18, 0.38, 1.0),   # WATER
	Color(0.32, 0.22, 0.14, 1.0),   # EARTH
	Color(0.22, 0.42, 0.18, 1.0),   # GRASS
	Color(0.10, 0.25, 0.10, 1.0),   # WOOD
	Color(0.38, 0.36, 0.34, 1.0),   # ROCK
]

const CHUNK_PX: float = WorldGrid.CHUNK_WORLD_SIZE


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var camera: Camera2D = get_viewport().get_camera_2d()
	if camera == null:
		return
	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	var half: Vector2 = vp_size * 0.5 / camera.zoom
	var cam_pos: Vector2 = camera.global_position
	var min_chunk: Vector2i = WorldGrid.world_to_chunk(cam_pos - half - Vector2(CHUNK_PX, CHUNK_PX))
	var max_chunk: Vector2i = WorldGrid.world_to_chunk(cam_pos + half + Vector2(CHUNK_PX, CHUNK_PX))
	for cy in range(min_chunk.y, max_chunk.y + 1):
		for cx in range(min_chunk.x, max_chunk.x + 1):
			var coord: Vector2i = Vector2i(cx, cy)
			var biome: int = WorldGrid.get_chunk_biome(coord)
			var color: Color = BIOME_COLORS[mini(biome, BIOME_COLORS.size() - 1)]
			draw_rect(Rect2(Vector2(cx, cy) * CHUNK_PX, Vector2(CHUNK_PX, CHUNK_PX)), color)
