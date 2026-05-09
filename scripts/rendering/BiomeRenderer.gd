extends Node2D

const CHUNK_PX: float = WorldGrid.CHUNK_WORLD_SIZE

var _multimesh: MultiMesh
var _mmi: MultiMeshInstance2D
var _allocated_chunks: int = 0


func _ready() -> void:
	_multimesh = MultiMesh.new()
	_multimesh.transform_format = MultiMesh.TRANSFORM_2D
	_multimesh.use_custom_data = true
	_multimesh.instance_count = 0

	var quad := QuadMesh.new()
	quad.size = Vector2(CHUNK_PX, CHUNK_PX)
	_multimesh.mesh = quad

	_mmi = MultiMeshInstance2D.new()
	_mmi.multimesh = _multimesh

	var shader: Shader = load("res://shaders/biome.gdshader")
	if shader:
		var mat := ShaderMaterial.new()
		mat.shader = shader
		_mmi.material = mat

	add_child(_mmi)


func _process(_delta: float) -> void:
	_update_chunks()


func _update_chunks() -> void:
	var camera: Camera2D = get_viewport().get_camera_2d()
	if camera == null:
		return
	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	var half: Vector2 = vp_size * 0.5 / camera.zoom
	var cam_pos: Vector2 = camera.global_position
	var min_chunk: Vector2i = WorldGrid.world_to_chunk(cam_pos - half - Vector2(CHUNK_PX, CHUNK_PX))
	var max_chunk: Vector2i = WorldGrid.world_to_chunk(cam_pos + half + Vector2(CHUNK_PX, CHUNK_PX))

	var needed: int = (max_chunk.x - min_chunk.x + 1) * (max_chunk.y - min_chunk.y + 1)
	if needed > _allocated_chunks:
		_allocated_chunks = needed + 32
		_multimesh.instance_count = _allocated_chunks

	var slot: int = 0
	for cy in range(min_chunk.y, max_chunk.y + 1):
		for cx in range(min_chunk.x, max_chunk.x + 1):
			var coord: Vector2i = Vector2i(cx, cy)
			var biome: int = WorldGrid.get_chunk_biome(coord)
			var north: int = WorldGrid.get_chunk_biome(Vector2i(cx, cy - 1))
			var east: int  = WorldGrid.get_chunk_biome(Vector2i(cx + 1, cy))
			var south: int = WorldGrid.get_chunk_biome(Vector2i(cx, cy + 1))
			var west: int  = WorldGrid.get_chunk_biome(Vector2i(cx - 1, cy))
			var center: Vector2 = Vector2(cx, cy) * CHUNK_PX + Vector2(CHUNK_PX * 0.5, CHUNK_PX * 0.5)
			_multimesh.set_instance_transform_2d(slot, Transform2D(0.0, Vector2.ONE, 0.0, center))
			# Normalize to 0-1 (Color channels are clamped). Decode in shader: val = round(ch * 4)
			# alpha encodes south*5+west (max=24), normalize /24
			_multimesh.set_instance_custom_data(slot, Color(
				float(biome) / 4.0,
				float(north) / 4.0,
				float(east) / 4.0,
				(float(south) * 5.0 + float(west)) / 24.0
			))
			slot += 1

	_multimesh.visible_instance_count = slot
