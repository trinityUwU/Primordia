extends Node2D

const CHUNK_PX: float = WorldGrid.CHUNK_WORLD_SIZE
const HEATMAP_FIELDS: Array[String] = ["", "nutrients", "toxins", "temperature"]
const HEATMAP_LABELS: Array[String] = ["OFF", "Nutrients", "Toxins", "Temperature"]
const TEMP_MAX: float = 40.0

var mode: int = 0  # 0=off, 1=nutrients, 2=toxins, 3=temperature

var _multimesh: MultiMesh
var _mmi: MultiMeshInstance2D
var _allocated: int = 0


func _ready() -> void:
	add_to_group("heatmap_overlay")
	_multimesh = MultiMesh.new()
	_multimesh.transform_format = MultiMesh.TRANSFORM_2D
	_multimesh.use_custom_data = true
	_multimesh.instance_count = 0

	var quad := QuadMesh.new()
	quad.size = Vector2(CHUNK_PX, CHUNK_PX)
	_multimesh.mesh = quad

	_mmi = MultiMeshInstance2D.new()
	_mmi.multimesh = _multimesh
	var shader := load("res://shaders/heatmap.gdshader") as Shader
	if shader:
		var mat := ShaderMaterial.new()
		mat.shader = shader
		_mmi.material = mat
	add_child(_mmi)
	_mmi.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key := event as InputEventKey
		if key.pressed and key.keycode == KEY_H:
			mode = (mode + 1) % HEATMAP_FIELDS.size()
			_mmi.visible = mode != 0
			get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	if mode == 0:
		return
	_update()


func _update() -> void:
	var camera: Camera2D = get_viewport().get_camera_2d()
	if camera == null:
		return
	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	var half: Vector2 = vp_size * 0.5 / camera.zoom
	var cam_pos: Vector2 = camera.global_position
	var min_chunk: Vector2i = WorldGrid.world_to_chunk(cam_pos - half - Vector2(CHUNK_PX, CHUNK_PX))
	var max_chunk: Vector2i = WorldGrid.world_to_chunk(cam_pos + half + Vector2(CHUNK_PX, CHUNK_PX))

	var needed: int = (max_chunk.x - min_chunk.x + 1) * (max_chunk.y - min_chunk.y + 1)
	if needed > _allocated:
		_allocated = needed + 32
		_multimesh.instance_count = _allocated

	var field: String = HEATMAP_FIELDS[mode]
	var slot: int = 0
	for cy in range(min_chunk.y, max_chunk.y + 1):
		for cx in range(min_chunk.x, max_chunk.x + 1):
			var coord: Vector2i = Vector2i(cx, cy)
			var val: float = _sample_chunk_avg(coord, field)
			if mode == 3:
				val = clamp(val / TEMP_MAX, 0.0, 1.0)
			var center: Vector2 = Vector2(cx, cy) * CHUNK_PX + Vector2(CHUNK_PX * 0.5, CHUNK_PX * 0.5)
			_multimesh.set_instance_transform_2d(slot, Transform2D(0.0, Vector2.ONE, 0.0, center))
			_multimesh.set_instance_custom_data(slot, Color(val, float(mode), 0.0, 0.0))
			slot += 1

	_multimesh.visible_instance_count = slot


func _sample_chunk_avg(coord: Vector2i, field: String) -> float:
	if not WorldGrid._chunks.has(coord):
		return 0.0
	var arr: Array = WorldGrid._chunks[coord]["fields"][field]
	var total: float = 0.0
	var step: int = 64
	var count: int = 0
	for i in range(0, arr.size(), step):
		total += arr[i]
		count += 1
	return total / count if count > 0 else 0.0
